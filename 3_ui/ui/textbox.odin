package ui

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import "core:math/linalg"
import "core:math"
import rl "vendor:raylib"

TEXT_FIELD_DELIMITERS :: " #@%/\\.?!§*-_:;\",&(){}[]"

TextBox :: struct {
	pixels_rounded: i32,
	color: Color,
	background: Color,
	outlineColor: Color,
	labelColor: Color,

	str: [dynamic]rune,
	labelStr: string,
	editable: bool,
	cursorIndex: int,
	cursorPosX: f32,
}

new_textbox :: proc {
	new_textbox_simple,
	new_textbox_extra,
}

new_textbox_simple :: proc(parent: ^Node) -> ^Node {
	return new_textbox_extra(parent, "")
}

new_textbox_extra :: proc(parent: ^Node, labelStr: string) -> ^Node {
	node := new(Node)
	textbox := TextBox{
		color = UNSET_DEFAULT_COLOR,
		background = {0,0,0,0},
		outlineColor = UNSET_DEFAULT_COLOR,
		labelColor = UNSET_DEFAULT_COLOR,

		pixels_rounded = 2,
		str = make([dynamic]rune),
		labelStr = labelStr,
		editable = true,
		cursorIndex = 0,
		cursorPosX = 0,
	}

	node.element = textbox
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

nextWordLeft :: proc(text: ^[dynamic]rune, index: int) -> int {
	nextPosition := 0
	inWord := false
	
	for i := 0; i < index; i += 1 {
		if strings.contains_rune(TEXT_FIELD_DELIMITERS, text[i]) {
			inWord = false
			continue
		}

		if !inWord {
			nextPosition = i
			inWord = true
		}
	}

	return nextPosition
}

nextWordRight :: proc(text: ^[dynamic]rune, index: int) -> int {
	nextPosition := len(text)
	inWord := false

	for i := len(text) - 1; i >= index; i -= 1 {
		if strings.contains_rune(TEXT_FIELD_DELIMITERS, text[i]) {
			inWord = false
			continue
		}

		if !inWord {
			nextPosition = i + 1
			inWord = true
		}
	}

	return nextPosition
}

// Returns the new cursor position
delete_substring :: proc(str: ^[dynamic]rune, startIndex, endIndex: int) -> int {
	leftMostIndex := min(startIndex, endIndex)
	count := abs(startIndex - endIndex)

	left := str[:leftMostIndex]
	right := str[leftMostIndex+count:]
	clear(str)
	append(str, ..left)
	append(str, ..right)

	return leftMostIndex
}

// FIXME: Take in a buffer of inputs, and loop over them
textbox_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, platformProc: PlatformProcs, inputs: Inputs) {
	t := &node.element.(TextBox)
	if !t.editable {
		return
	}

	if inputs.runePressed != 0 {
		inject_at(&t.str, t.cursorIndex, inputs.runePressed)
		t.cursorIndex += 1
	}

	isCtrlDown := inputs.leftCtrlDown || inputs.rightCtrlDown

	if inputs.backspacePressed {
		if t.cursorIndex == 0 {
			return
		}

		if isCtrlDown {
			if len(t.str) != 0 {
				t.cursorIndex = delete_substring(&t.str, nextWordLeft(&t.str, t.cursorIndex), t.cursorIndex)
			}
		} else {
			t.cursorIndex -= 1
			ordered_remove(&t.str, t.cursorIndex)
		}
	} else if inputs.deletePressed {
		if len(t.str) == 0 {
			return
		}

		if t.cursorIndex == len(t.str) {
			return
		}

		if isCtrlDown {
			if len(t.str) != 0 {
				t.cursorIndex = delete_substring(&t.str, t.cursorIndex, nextWordRight(&t.str, t.cursorIndex))
			}
		} else {
			ordered_remove(&t.str, max(0, t.cursorIndex))
		}
	} else if isCtrlDown && inputs.wPressed {
		if len(t.str) != 0 {
			t.cursorIndex = delete_substring(&t.str, nextWordLeft(&t.str, t.cursorIndex), t.cursorIndex)
		}
	} else if inputs.leftPressed {
		if isCtrlDown {
			t.cursorIndex = nextWordLeft(&t.str, t.cursorIndex)
		} else {
			t.cursorIndex -= 1
			if t.cursorIndex < 0 {
				t.cursorIndex = 0
			}
		}
	} else if inputs.rightPressed {
		if isCtrlDown {
			t.cursorIndex = nextWordRight(&t.str, t.cursorIndex)
		} else {
			t.cursorIndex += 1
			if t.cursorIndex >= len(t.str) {
				t.cursorIndex = max(0, len(t.str))
			}
		}
	} else if inputs.homePressed {
		t.cursorIndex = 0
	} else if inputs.endPressed {
		t.cursorIndex = max(0, len(t.str))
	} else if isCtrlDown && inputs.vPressed {
		s := platformProc.getClipboardText()
		s, _ = strings.remove_all(s, "\n")
		inject_at(&t.str, t.cursorIndex, ..utf8.string_to_runes(s, context.temp_allocator))
		t.cursorIndex += len(s)
	} else {
		return // Skip resetting cursor blink
	}

	reset_text_cursor_blink(state)
}

textbox_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs, delta: f32) {
	t := &node.element.(TextBox)
	firstParentContainer := first_parent_container(node)

	visible := visible_area_for_drawing(node)
	rl.BeginScissorMode(visible.x, visible.y, visible.w, visible.h)
	defer rl.EndScissorMode()

	screenHeightThing := screenHeight
	dropshadowColor: ColorVec4 = {0, 0, 0, 0.0}
	dropshadowSmoothness: f32 = 5
	dropshadowOffset := [2]i32{0,1}
	outlineColor := color_to_colorvec4(color_or(t.outlineColor, uiData.colors.textboxOutlineColor))
	if !t.editable {
		outlineColor.a /= 2
	}
	color := color_to_colorvec4(color_or(t.color, uiData.colors.textboxBackgroundColor))
	pixelsRounded := t.pixels_rounded
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderDPIScaleLoc, &uiData.dpiScale, .VEC2)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderRectLoc, &node.box, .IVEC4)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderScreenHeightLoc, &screenHeightThing, .INT)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderDropshadowColorLoc, &dropshadowColor, .VEC4)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderDropshadowOffsetLoc, &dropshadowOffset, .IVEC2)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderDropshadowSmoothnessLoc, &dropshadowSmoothness, .FLOAT)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderColorLoc, &color, .VEC4)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderOutlineColorLoc, &outlineColor, .VEC4)
	rl.SetShaderValue(uiData.textboxShader, uiData.textboxShaderPixelsRoundedLoc, &pixelsRounded, .INT)

	rl.BeginShaderMode(uiData.textboxShader)
	rl.DrawRectangle(firstParentContainer.x, firstParentContainer.y, firstParentContainer.w, firstParentContainer.h, {0,0,0,0}) // outer box
	rl.EndShaderMode()

	xOffset: i32 = 3
	yOffset: f32 = math.ceil(max(2, (f32(node.h) - f32(uiData.fontSize)) / 2))
	if len(t.str) == 0 {
		labelColor := color_or(t.labelColor, uiData.colors.textboxLabelColor)
		if !t.editable {
			labelColor.a /= 2
		}
		rl.DrawTextCodepoints(uiData.fontVariable, raw_data(utf8.string_to_runes(t.labelStr)), i32(len(t.labelStr)), {f32(i32(node.x + xOffset)), f32(i32(f32(node.y) + yOffset))}, f32(uiData.fontSize), 0, color_to_rl_color(labelColor))
	} else {
		rl.DrawTextCodepoints(uiData.fontVariable, raw_data(t.str[:]), i32(len(t.str)), {f32(i32(node.x + xOffset)), f32(i32(f32(node.y) + yOffset))}, f32(uiData.fontSize), 0, color_to_rl_color(uiData.colors.textboxTextColor))
	}

	target := rl.MeasureTextEx(uiData.fontVariable, strings.unsafe_string_to_cstring(utf8.runes_to_string(t.str[:t.cursorIndex])), f32(uiData.fontSize), 0)[0]
	if abs(t.cursorPosX - target) > 1 {
		t.cursorPosX = linalg.lerp(t.cursorPosX, target, delta * 30)
	}

	if node == state.selectedInteractableLockNode && t.editable {
		heightDiff: f32 = f32(uiData.fontSize) * 0.1
		color := Color{210,210,210,255}
		if state.textCursorBlink {
			rl.DrawRectangle(node.x + xOffset + i32(t.cursorPosX), i32(f32(node.y) + yOffset + heightDiff / 2), 1, i32(f32(uiData.fontSize) - heightDiff), color_to_rl_color(color))
		}
	}
}
