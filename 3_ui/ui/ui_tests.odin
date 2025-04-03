package ui

import "core:testing"
import "core:log"

@(test)
scale_up_children_test :: proc(t: ^testing.T) {
	debugSquares := get_me_some_debug_squares(2)
	defer delete(debugSquares)

	rootNode := vertical_split_from_nodes(debugSquares)
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
	debugSquares := get_me_some_debug_squares(8)
	defer delete(debugSquares)

	horizSplit1 := horizontal_split_from_nodes(debugSquares[0:3])
	horizSplit2 := horizontal_split_from_nodes(debugSquares[3:6])
	rootNode := vertical_split_from_nodes({horizSplit1, horizSplit2, debugSquares[6], debugSquares[7]})
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
