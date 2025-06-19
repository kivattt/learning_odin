package ui

import rl "vendor:raylib"
import "core:fmt"

VerticalTextAlignment :: enum {
	Top,
	Middle,
	Bottom,
}

HorizontalTextAlignment :: enum {
	Left,
	Middle,
	Right,
}

Label :: struct {
	text: string,
	fontSize: i32,
	foreground: Color,
	background: Color,
	verticalAlignment: VerticalTextAlignment,
	horizontalAlignment: HorizontalTextAlignment,
}

new_label :: proc {
	new_label_simple,
	new_label_extra,
}

// Remember to free() the return value!
new_label_extra :: proc(parent: ^Node, text: string, verticalAlignment: VerticalTextAlignment, horizontalAlignment: HorizontalTextAlignment, foreground, background: Color) -> ^Node {
	node := new(Node)
	label := Label{
		text = text,
		fontSize = DEFAULT_FONT_SIZE,
		foreground = foreground,
		background = background,
		verticalAlignment = verticalAlignment,
		horizontalAlignment = horizontalAlignment,
	}

	node.element = label
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

// Remember to free() the return value!
new_label_simple :: proc(parent: ^Node, text: string, verticalAlignment: VerticalTextAlignment, horizontalAlignment: HorizontalTextAlignment) -> ^Node {
	//return new_label_extra(parent, text, verticalAlignment, horizontalAlignment, TEXT_COLOR, BACKGROUND_COLOR)
	return new_label_extra(parent, text, verticalAlignment, horizontalAlignment, TEXT_COLOR, {0,0,0,0})
}

label_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs, delta: f32) {
	assert(node.parent != nil)

	label := node.element.(Label)

	visible := visible_area_for_drawing(node)
	rl.BeginScissorMode(visible.x, visible.y, visible.w, visible.h)
	defer rl.EndScissorMode()

	if label.background.a != 0 {
		rl.DrawRectangle(node.x, node.y, node.w, node.h, color_to_rl_color(label.background))
	}

	text := fmt.ctprintf("{}", label.text)
	spacing: f32 = 0

	bounds := rl.MeasureTextEx(uiData.fontVariable, text, f32(label.fontSize), spacing)

	x, y: f32
	switch label.verticalAlignment {
	case .Middle:
		y = f32(node.y + node.h / 2) - bounds.y/2
	case .Top:
		y = f32(node.y)
	case .Bottom:
		y = f32(node.y + node.h) - bounds.y
	}

	switch label.horizontalAlignment {
	case .Middle:
		x = f32(node.x + node.w / 2) - bounds.x/2
	case .Left:
		x = f32(node.x)
	case .Right:
		x = f32(node.x + node.w) - bounds.x
	}

	x = max(f32(node.x), x)
	y = max(f32(node.y), y)

	x = f32(i32(x))
	y = f32(i32(y))

	rl.DrawTextEx(uiData.fontVariable, text, {x, y}, f32(label.fontSize), spacing, color_to_rl_color(label.foreground))
}
