package ui

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

TEXT_FIELD_DELIMITERS :: " #@%/\\.?!§*-_:;\",&(){}[]"

TextBox :: struct {
	str: [dynamic]rune,
	cursorIndex: int,
}

new_textbox :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	textbox := TextBox{
		str = make([dynamic]rune),
		cursorIndex = 0,
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

textbox_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	t := node.element.(TextBox)
	rl.DrawTextCodepoints(uiData.fontVariable, raw_data(t.str[:]), i32(len(t.str)), {f32(node.x), f32(node.y)}, f32(uiData.fontSize), 0, color_to_rl_color(uiData.colors.textColor))
}

textbox_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, platformProc: PlatformProcs, inputs: Inputs) {
	t := &node.element.(TextBox)
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
				t.cursorIndex = delete_substring(&t.str, t.cursorIndex, nextWordLeft(&t.str, t.cursorIndex))
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
	}
}
