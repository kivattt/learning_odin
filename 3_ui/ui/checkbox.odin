package ui

// A button should always be inside a Container

import rl "vendor:raylib"
import "core:fmt"

Checkbox :: struct {
	checked: bool,

	pixels_rounded: i32,
	color: Color,
	background: Color,
}

// Remember to free() the return value!
new_checkbox :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	checkbox := Checkbox{
		color = UNSET_DEFAULT_COLOR,
		pixels_rounded = 2,
		background = {0,0,0,0},
	}
	node.element = checkbox
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

checkbox_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs, delta: f32) {
	assert(node.parent != nil)
	notSquare := node.w != node.h
	if notSquare {
		fmt.println("WARNING: Non-square checkbox, shown in green")
	}

	firstParentContainer := first_parent_container(node)

	visible := visible_area_for_drawing(firstParentContainer)
	rl.BeginScissorMode(visible.x, visible.y, visible.w, visible.h)
	defer rl.EndScissorMode()

	checkbox := node.element.(Checkbox)

	if checkbox.background.a != 0 {
		rl.DrawRectangle(node.x, node.y, node.w, node.h, color_to_rl_color(checkbox.background))
	}

	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderDPIScaleLoc, &uiData.dpiScale, .VEC2)
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderRectLoc, &node.box, .IVEC4)
	screenHeightThing := screenHeight
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderScreenHeightLoc, &screenHeightThing, .INT)

	c := f32(14) / f32(255)
	dropshadowColor: ColorVec4 = {c, c, c, 1}
	dropshadowOffset := [2]i32{0, 2}

	color := color_to_colorvec4(color_or(checkbox.color, uiData.colors.interactableColor))

	if checkbox.checked {
		color = color_to_colorvec4(HIGHLIGHT_COLOR)
	}

	if notSquare {
		color = ColorVec4{0,1,0,1}
	}

	hovered := is_hovered(node, firstParentContainer, state, inputs)
	if hovered {
		amount: f32 = 0.07
		color.r += amount
		color.g += amount
		color.b += amount
	}

	checked: i32 = checkbox.checked ? 1 : 0
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderDrawCheckmark, &checked, .INT)
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderColorLoc, &color, .VEC4)
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderDropshadowColorLoc, &dropshadowColor, .VEC4)
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderDropshadowOffsetLoc, &dropshadowOffset, .IVEC2)
	pixelsRounded := checkbox.pixels_rounded
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderPixelsRoundedLoc, &pixelsRounded, .INT)

	rl.BeginShaderMode(uiData.checkboxShader)
	rl.DrawRectangle(firstParentContainer.x, firstParentContainer.y, firstParentContainer.w, firstParentContainer.h, {0,0,0,0}) // outer box
	rl.EndShaderMode()

	if node == state.controllerHoveredNode {
		draw_controller_outline(node.box, firstParentContainer.box, screenHeightThing, pixelsRounded, uiData)
	}
}

checkbox_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, platformProcs: PlatformProcs, inputs: Inputs) {
	if state.lastMouse1Pressed {
		return
	}

	firstParentContainer := first_parent_container(node)
	hovered := is_hovered(node, firstParentContainer, state, inputs)

	if hovered && inputs.mouseLeftDown {
		checkbox := &node.element.(Checkbox)
		checkbox.checked = !checkbox.checked
	}
}
