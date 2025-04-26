package ui

import rl "vendor:raylib"
import "core:fmt"

Button :: struct {
	pixels_rounded: i32,
	color: rl.Color,
	backgroundColor: rl.Color,

	text: string,
	textColor: rl.Color,

	onClickData: rawptr,
	onClickProc: proc(data: rawptr),
}

// Remember to free() the return value!
new_button :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	button := Button{
		color = PASSIVE_OUTLINE_COLOR,
		pixels_rounded = 4,
		backgroundColor = BACKGROUND_COLOR,
		textColor = TEXT_COLOR,
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

	scissorBox := box_clip_within(node.parent.box, node.box)
	rl.BeginScissorMode(scissorBox.x, scissorBox.y, scissorBox.w, scissorBox.h)

	button := node.element.(Button)

	rl.DrawRectangle(node.x, node.y, node.w, node.h, button.backgroundColor)

	innerBox := inner_box_from_box(node.box)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderBoxLoc, &innerBox, .IVEC4)
	screenHeightThing := screenHeight
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderScreenHeightLoc, &screenHeightThing, .INT)

	dropshadowColor: Color = {0, 0, 0, 0.2}
	dropshadowSmoothness: f32 = 6
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowSmoothnessLoc, &dropshadowSmoothness, .FLOAT)

	color := Color{
		r = f32(button.color.r) / 255,
		g = f32(button.color.g) / 255,
		b = f32(button.color.b) / 255,
		a = f32(button.color.a) / 255,
	}

	hovered := is_coord_in_box(inner_box_from_box(node.box), inputs.mouseX, inputs.mouseY)
	hovered &= state.hoveredNode == node

	if hovered {
		dropshadowColor = Color{
			r = f32(uiData.colors.hoveredOutlineColor.r) / 255,
			g = f32(uiData.colors.hoveredOutlineColor.g) / 255,
			b = f32(uiData.colors.hoveredOutlineColor.b) / 255,
			a = f32(uiData.colors.hoveredOutlineColor.a) / 255,
		}
	}

	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderColorLoc, &color, .VEC4)
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderDropshadowColorLoc, &dropshadowColor, .VEC4)
	pixelsRounded := button.pixels_rounded
	rl.SetShaderValue(uiData.buttonShader, uiData.buttonShaderPixelsRoundedLoc, &pixelsRounded, .INT)

	rl.BeginShaderMode(uiData.buttonShader)
	//rl.DrawRectangle(innerBox.x, innerBox.y, innerBox.w, innerBox.h, {0,0,0,0})
	rl.DrawRectangle(node.x, node.y, node.w, node.h, {0,0,0,0}) // Size of the outer box
	//rl.DrawRectangle(0, 0, 2000, screenHeight, {0,0,0,0})
	rl.EndShaderMode()

	rl.EndScissorMode()

	if button.text != "" {
		scissorBox = box_clip_within(node.parent.box, innerBox)
		rl.BeginScissorMode(scissorBox.x, scissorBox.y, scissorBox.w, scissorBox.h)

		text := fmt.ctprintf("{}", button.text)
		spacing: f32 = 0
		bounds := rl.MeasureTextEx(uiData.fontVariable, text, f32(uiData.fontSize), spacing)
		x := f32(innerBox.x + innerBox.w / 2) - bounds.x/2
		y := f32(innerBox.y + innerBox.h / 2) - bounds.y/2
		x = max(f32(innerBox.x), x)
		y = max(f32(innerBox.y), y)

		x = f32(i32(x))
		y = f32(i32(y))

		rl.DrawTextEx(uiData.fontVariable, text, {x, y}, f32(uiData.fontSize), spacing, button.textColor)

		rl.EndScissorMode()
	}

	// Out of bounds drawing test
	//rl.DrawRectangle(innerBox.x-50, innerBox.y, innerBox.w+90, innerBox.h, {0,255,0,80})
}

button_handle_input :: proc(node: ^Node, state: ^UserInterfaceState, inputs: Inputs) {
	if state.lastMouse1Pressed {
		return
	}

	hovered := is_coord_in_box(inner_box_from_box(node.box), inputs.mouseX, inputs.mouseY)
	hovered &= state.hoveredNode == node

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
