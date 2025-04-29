package ui

import rl "vendor:raylib"
import "core:fmt"

// This is meant to be used in VerticalSplitUnresizeable or HorizontalSplitUnresizeable
// Because you wouldn't want to resize a visual break

Direction :: enum {
	Vertical,
	Horizontal,
}

VisualBreak :: struct {
	direction: Direction,
}

// Remember to free() the return value!
new_visual_break :: proc(parent: ^Node, direction: Direction, size: i32) -> ^Node {
	node := new(Node)

	visualBreak := VisualBreak{
		direction = direction,
	}

	node.element = visualBreak
	node.parent = parent

	switch direction {
	case .Vertical:
		node.w = size
		node.h = parent.h
	case .Horizontal:
		node.h = size
		node.w = parent.w
	}
	node.minimumSize = size

	return node
}

visual_break_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	assert(node.parent != nil)

	visualBreak := node.element.(VisualBreak)

	scissorBox := box_clip_within(node.parent.box, node.box)
	rl.BeginScissorMode(scissorBox.x, scissorBox.y, scissorBox.w, scissorBox.h)
	defer rl.EndScissorMode()

	switch visualBreak.direction {
	case .Vertical:
		x := node.x + i32(0.75 * f32(node.w))
		node.y += 5
		node.h -= 10
		rl.DrawRectangle(x, node.y, node.w, 1, VISUAL_BREAK_COLOR)
	case .Horizontal:
		y := node.y + i32(0.75 * f32(node.h))
		node.x += 5
		node.w -= 10
		rl.DrawRectangle(node.x, y, node.w, 1, VISUAL_BREAK_COLOR)
	}
}
