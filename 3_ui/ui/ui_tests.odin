package ui

import "core:testing"
import "core:log"

// TODO: Add a test for resize bar hover being like -8, +8

// Remember to delete() the return value!
get_me_some_padding_rects :: proc(numBoxes: int) -> (boxes: []^Node) {
	boxes = make([]^Node, numBoxes)

	for i := 0; i < numBoxes; i += 1 {
		debugSquare := new_padding_rect(nil) // FIXME?
		c: u8 = u8(i) * 20
		boxes[i] = debugSquare
	}

	return
}

@(test)
scale_up_children_test :: proc(t: ^testing.T) {
	debugSquares := get_me_some_padding_rects(2)
	defer delete(debugSquares)

	rootNode := new_vertical_split_from_nodes(nil, debugSquares)
	defer delete_node_and_its_children(rootNode)

	rootNode.w = 1000
	rootNode.h = 1000
	scale_up_children(rootNode)
	testing.expect_value(t, debugSquares[0].x, 0)
	testing.expect_value(t, debugSquares[0].y, 0)
	testing.expect_value(t, debugSquares[0].w, 500)
	testing.expect_value(t, debugSquares[0].h, 1000)

	testing.expect_value(t, debugSquares[1].x, 500)
	testing.expect_value(t, debugSquares[1].y, 0)
	testing.expect_value(t, debugSquares[1].w, 500)
	testing.expect_value(t, debugSquares[1].h, 1000)
}

@(test)
children_have_correct_parents_test :: proc(t: ^testing.T) {
	debugSquares := get_me_some_padding_rects(8)
	defer delete(debugSquares)

	horizSplit1 := new_horizontal_split_from_nodes(nil, debugSquares[0:3])
	horizSplit2 := new_horizontal_split_from_nodes(nil, debugSquares[3:6])
	rootNode := new_vertical_split_from_nodes(nil, {horizSplit1, horizSplit2, debugSquares[6], debugSquares[7]})
	defer delete_node_and_its_children(rootNode)

	testing.expect_value(t, rootNode.parent, nil)
	for &node in rootNode.element.(VerticalSplit).children {
		testing.expect_value(t, node.parent, rootNode)
	}

	for &node in horizSplit1.element.(HorizontalSplit).children {
		testing.expect_value(t, node.parent, horizSplit1)
	}

	for &node in horizSplit2.element.(HorizontalSplit).children {
		testing.expect_value(t, node.parent, horizSplit2)
	}
}

@(test)
vertical_resize_bar_hover_position_test :: proc(t: ^testing.T) {
	debugSquares := get_me_some_padding_rects(4)
	defer delete(debugSquares)

	rootNode := new_vertical_split_from_nodes(nil, debugSquares)
	defer delete_node_and_its_children(rootNode)

	state := ui_state_default_values()
	rootNode.w = 1000
	rootNode.h = 1000
	scale_up_children(rootNode)

	testing.expect_value(t, debugSquares[1].x + debugSquares[1].w, 500)

	// Hovering over the 2nd resize bar
	for i: i32 = -8; i <= 8; i += 1 {
		inputs := Inputs{
			mouseX = 500 + i,
			mouseY = 500,
		}

		handle_input(rootNode, &state, get_dummy_platform_procs(), inputs)
		if !testing.expect_value(t, state.hoveredResizeBar, debugSquares[1]) {
			break
		}
	}

	// NOT hovering over the 2nd resize bar
	for i: i32 = -16; i <= 16; i += 1 {
		if i >= -8 && i <= 8 {
			continue
		}

		inputs := Inputs{
			mouseX = 500 + i,
			mouseY = 500,
		}

		handle_input(rootNode, &state, get_dummy_platform_procs(), inputs)
		if !testing.expect_value(t, state.hoveredResizeBar, nil) {
			break
		}
	}
}

@(test)
horizontal_resize_bar_hover_position_test :: proc(t: ^testing.T) {
	debugSquares := get_me_some_padding_rects(4)
	defer delete(debugSquares)

	rootNode := new_horizontal_split_from_nodes(nil, debugSquares)
	defer delete_node_and_its_children(rootNode)

	state := ui_state_default_values()
	rootNode.w = 1000
	rootNode.h = 1000
	scale_up_children(rootNode)

	testing.expect_value(t, debugSquares[1].y + debugSquares[1].h, 500)

	// Hovering over the 2nd resize bar
	for i: i32 = -8; i <= 8; i += 1 {
		inputs := Inputs{
			mouseX = 500,
			mouseY = 500 + i,
		}

		handle_input(rootNode, &state, get_dummy_platform_procs(), inputs)
		if !testing.expect_value(t, state.hoveredResizeBar, debugSquares[1]) {
			break
		}
	}

	// NOT hovering over the 2nd resize bar
	for i: i32 = -16; i <= 16; i += 1 {
		if i >= -8 && i <= 8 {
			continue
		}

		inputs := Inputs{
			mouseX = 500,
			mouseY = 500 + i,
		}

		handle_input(rootNode, &state, get_dummy_platform_procs(), inputs)
		if !testing.expect_value(t, state.hoveredResizeBar, nil) {
			break
		}
	}
}
