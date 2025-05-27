package ui

// A button should always be inside a Container

import rl "vendor:raylib"
import "core:fmt"

Button :: struct {
	pixels_rounded: i32,
	color: Color,
	background: Color,

	text: string,
	textColor: Color,

	onClickData: rawptr,
	onClickProc: proc(data: rawptr),
}

// Remember to free() the return value!
new_button :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	button := Button{
		color = UNSET_DEFAULT_COLOR,
		pixels_rounded = 3,
		background = {0,0,0,0},
		textColor = UNSET_DEFAULT_COLOR,
	}
	node.element = button
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

button_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	assert(node.parent != nil)

	firstParentContainer := first_parent_container(node)

	visible := visible_area_for_drawing(firstParentContainer)
	rl.BeginScissorMode(visible.x, visible.y, visible.w, visible.h)

	button := node.element.(Button)

	if button.background.a != 0 {
		rl.DrawRectangle(node.x, node.y, node.w, node.h, color_to_rl_color(button.background))
	}

	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDPIScaleLoc, &uiData.dpiScale, .VEC2)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderRectLoc, &node.box, .IVEC4)
	screenHeightThing := screenHeight
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderScreenHeightLoc, &screenHeightThing, .INT)

	dropshadowColor: ColorVec4 = {0, 0, 0, 0.2}
	outlineColor: ColorVec4 = {1, 1, 1, 0.1}
	dropshadowSmoothness: f32 = 5
	dropshadowOffset := [2]i32{0,1}
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowOffsetLoc, &dropshadowOffset, .IVEC2)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowSmoothnessLoc, &dropshadowSmoothness, .FLOAT)

	color := color_to_colorvec4(color_or(button.color, uiData.colors.passiveOutlineColor))

	hovered := is_hovered(node, firstParentContainer, state, inputs)

	if hovered {
		//outlineColor = color_to_colorvec4(uiData.colors.hoveredOutlineColor)
		amount: f32 = 0.07
		color.r += amount
		color.g += amount
		color.b += amount
	}

	drawUpperHighlight: i32 = hovered ? 0 : 1
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDrawUpperHighlightLoc, &drawUpperHighlight, .INT)

	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderColorLoc, &color, .VEC4)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowColorLoc, &dropshadowColor, .VEC4)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderOutlineColorLoc, &outlineColor, .VEC4)
	pixelsRounded := button.pixels_rounded
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderPixelsRoundedLoc, &pixelsRounded, .INT)

	rl.BeginShaderMode(uiData.buttonShader)
	rl.DrawRectangle(firstParentContainer.x, firstParentContainer.y, firstParentContainer.w, firstParentContainer.h, {0,0,0,0}) // outer box
	rl.EndShaderMode()

	rl.EndScissorMode()

	if button.text != "" {
		visible = box_clip_within(node.parent.box, node.box)
		rl.BeginScissorMode(visible.x, visible.y, visible.w, visible.h)

		text := fmt.ctprintf("{}", button.text)
		spacing: f32 = 0
		bounds := rl.MeasureTextEx(uiData.fontVariable, text, f32(uiData.fontSize), spacing)
		x := f32(node.x + node.w / 2) - bounds.x/2
		y := f32(node.y + node.h / 2) - bounds.y/2
		x = max(f32(node.x), x)
		y = max(f32(node.y), y)

		x = f32(i32(x))
		y = f32(i32(y))

		rl.DrawTextEx(uiData.fontVariable, text, {x, y}, f32(uiData.fontSize), spacing, color_to_rl_color(color_or(button.textColor, uiData.colors.textColor)))

		rl.EndScissorMode()
	}

	if node == state.controllerHoveredNode {
		draw_controller_outline(node.box, firstParentContainer.box, screenHeightThing, pixelsRounded, uiData)
	}
}

button_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, inputs: Inputs) {
	if state.lastMouse1Pressed {
		return
	}

	firstParentContainer := first_parent_container(node)
	hovered := is_hovered(node, firstParentContainer, state, inputs)

	if hovered && inputs.mouseLeftDown {
		button := node.element.(Button)
		if button.onClickProc != nil {
			button.onClickProc(button.onClickData)
		}
	}
}

button_set_on_click :: proc(node: ^Node, data: rawptr, onClickProc: proc(data: rawptr)) {
	button := &node.element.(Button)
	button.onClickData = data
	button.onClickProc = onClickProc
}
