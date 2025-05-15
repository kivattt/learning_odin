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
		pixels_rounded = 3,
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

	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderBoxLoc, &node.box, .IVEC4)
	screenHeightThing := screenHeight
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderScreenHeightLoc, &screenHeightThing, .INT)

	dropshadowColor: Color = {0, 0, 0, 0.2}
	outlineColor: Color = {1, 1, 1, 0.07}
	dropshadowSmoothness: f32 = 6
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowSmoothnessLoc, &dropshadowSmoothness, .FLOAT)

	color := Color{
		r = f32(checkbox.color.r) / 255,
		g = f32(checkbox.color.g) / 255,
		b = f32(checkbox.color.b) / 255,
		a = f32(checkbox.color.a) / 255,
	}

	if notSquare {
		color = Color{0,1,0,1}
	}

	hovered := is_coord_in_box(node.box, inputs.mouseX, inputs.mouseY)
	hovered &= state.hoveredNode == node

	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderColorLoc, &color, .VEC4)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowColorLoc, &dropshadowColor, .VEC4)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderOutlineColorLoc, &outlineColor, .VEC4)
	pixelsRounded := checkbox.pixels_rounded
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderPixelsRoundedLoc, &pixelsRounded, .INT)

	rl.BeginShaderMode(uiData.buttonShader)
	rl.DrawRectangle(firstParentContainer.x, firstParentContainer.y, firstParentContainer.w, firstParentContainer.h, {0,0,0,0}) // outer box
	rl.EndShaderMode()

	if checkbox.checked {
		b := inner_box_from_box(node)
		rl.DrawRectangle(b.x, b.y, b.w, b.h, {255,255,255,215})
	}
}

checkbox_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, inputs: Inputs) {
	if state.lastMouse1Pressed {
		return
	}

	hovered := is_coord_in_box(node.box, inputs.mouseX, inputs.mouseY)
	hovered &= state.hoveredNode == node

	if hovered && inputs.mouseLeftDown {
		checkbox := &node.element.(Checkbox)
		checkbox.checked = !checkbox.checked
	}
}
