package ui

// A button should always be inside a Container

import rl "vendor:raylib"
import "core:fmt"

Checkbox :: struct {
	checked: bool,

	pixels_rounded: i32,
	color: rl.Color,
	background: rl.Color,
}

// Remember to free() the return value!
new_checkbox :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	checkbox := Checkbox{
		color = PASSIVE_OUTLINE_COLOR,
		pixels_rounded = 2,
		background = BACKGROUND_COLOR,
	}
	node.element = checkbox
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

checkbox_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
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
		rl.DrawRectangle(node.x, node.y, node.w, node.h, checkbox.background)
	}

	dpiScale := rl.GetWindowScaleDPI()
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderDPIScaleLoc, &dpiScale, .VEC2)
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderRectLoc, &node.box, .IVEC4)
	screenHeightThing := screenHeight
	rl.SetShaderValue(uiData.checkboxShader, uiData.checkboxShaderScreenHeightLoc, &screenHeightThing, .INT)

	c := f32(14) / f32(255)
	dropshadowColor: Color = {c, c, c, 1}
	dropshadowOffset := [2]i32{0, 2}

	color := Color{
		r = f32(checkbox.color.r) / 255,
		g = f32(checkbox.color.g) / 255,
		b = f32(checkbox.color.b) / 255,
		a = f32(checkbox.color.a) / 255,
	}

	if checkbox.checked {
		color.r = f32(HIGHLIGHT_COLOR.r) / 255
		color.g = f32(HIGHLIGHT_COLOR.g) / 255
		color.b = f32(HIGHLIGHT_COLOR.b) / 255
		color.a = f32(HIGHLIGHT_COLOR.a) / 255
	}

	if notSquare {
		color = Color{0,1,0,1}
	}

	hovered := is_coord_in_box(node.box, inputs.mouseX, inputs.mouseY)
	hovered &= state.hoveredNode == node

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
}

checkbox_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, inputs: Inputs) {
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
