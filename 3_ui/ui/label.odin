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
	foreground: rl.Color,
	background: rl.Color,
	verticalAlignment: VerticalTextAlignment,
	horizontalAlignment: HorizontalTextAlignment,
}

new_label :: proc{
	new_label_simple,
	new_label_extra,
}

// Remember to free() the return value!
new_label_extra :: proc(parent: ^Node, text: string, verticalAlignment: VerticalTextAlignment, horizontalAlignment: HorizontalTextAlignment, foreground, background: rl.Color) -> ^Node {
	node := new(Node)
	label := Label{
		text = text,
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
	return new_label_extra(parent, text, verticalAlignment, horizontalAlignment, TEXT_COLOR, BACKGROUND_COLOR)
}

label_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	assert(node.parent != nil)

	label := node.element.(Label)

	scissorBox := box_clip_within(node.parent.box, node.box)
	rl.BeginScissorMode(scissorBox.x, scissorBox.y, scissorBox.w, scissorBox.h)

	if label.background.a != 0 {
		rl.DrawRectangle(node.x, node.y, node.w, node.h, label.background)
	}

	text := fmt.ctprintf("{}", label.text)
	spacing: f32 = 0

	bounds := rl.MeasureTextEx(uiData.fontVariable, text, f32(uiData.fontSize), spacing)

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

	rl.DrawTextEx(uiData.fontVariable, text, {x, y}, f32(uiData.fontSize), spacing, label.foreground)

	rl.EndScissorMode()
}
