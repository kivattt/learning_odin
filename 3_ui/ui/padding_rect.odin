package ui

import rl "vendor:raylib"

PaddingRect :: struct {
	color: Color,
}

new_padding_rect :: proc {
	new_padding_rect_simple,
	new_padding_rect_extra,
}

// Remember to free() the return value!
new_padding_rect_extra :: proc(parent: ^Node, color: Color) -> ^Node {
	node := new(Node)
	paddingRect := PaddingRect{
		color = color,
	}
	node.element = paddingRect
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

new_padding_rect_simple :: proc(parent: ^Node) -> ^Node {
	return new_padding_rect_extra(parent, {0,0,0,0})
}


padding_rect_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	paddingRect := node.element.(PaddingRect)
	if paddingRect.color.a != 0 {
		rl.DrawRectangle(node.x, node.y, node.w, node.h, color_to_rl_color(paddingRect.color))
	}
}
