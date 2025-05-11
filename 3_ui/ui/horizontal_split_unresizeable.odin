package ui

import rl "vendor:raylib"

// Uses the childrens minimumSize as their widths.
// A child with preferResize = true means its width will grow dynamically
// We assume only ONE child can have preferResize = true. We panic if this doesn't hold!
HorizontalSplitUnresizeable :: struct {
	children: [dynamic]^Node,
}

new_horizontal_split_unresizeable :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	horizontalSplitUnresizeable: HorizontalSplitUnresizeable
	node.element = horizontalSplitUnresizeable
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

new_horizontal_split_unresizeable_from_nodes :: proc(parent: ^Node, nodes: []^Node) -> ^Node {
	horizontalSplitUnresizeable: HorizontalSplitUnresizeable

	node := new(Node)

	for &inNode in nodes {
		inNode.parent = node
		append(&horizontalSplitUnresizeable.children, inNode)
	}

	node.element = horizontalSplitUnresizeable
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

horizontal_split_unresizeable_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	visible := visible_area_for_drawing(node)
	rl.DrawRectangle(visible.x, visible.y, visible.w, visible.h, BACKGROUND_COLOR)

	horizontalSplitUnresizeable := node.element.(HorizontalSplitUnresizeable)

	// Panic when more than 1 child has preferResize = true
	alreadyFoundChildWithPreferResize := false
	for child in horizontalSplitUnresizeable.children {
		if child.preferResize {
			if alreadyFoundChildWithPreferResize {
				panic("Multiple children had preferResize = true in a HorizontalSplitUnresizeable element.")
			}
			alreadyFoundChildWithPreferResize = true
		}
	}

	theY: i32 = node.y

	for i := 0; i < len(horizontalSplitUnresizeable.children); i += 1 {
		child := horizontalSplitUnresizeable.children[i]
		//child.w = child.minimumSize
		child.h = child.minimumSize

		if child.preferResize {
			heightSumOfNextChildren: i32 = 0
			for j := i + 1; j < len(horizontalSplitUnresizeable.children); j += 1 {
				heightSumOfNextChildren += horizontalSplitUnresizeable.children[j].minimumSize
			}

			//child.w = max(child.minimumSize, node.w - (theX - node.x) - widthSumOfNextChildren)
			child.h = max(child.minimumSize, node.h - (theY - node.y) - heightSumOfNextChildren)
		}

		//child.x = theX
		//child.y = node.y

		child.x = node.x
		child.y = theY

		//child.h = node.h
		child.w = node.w

		theY += child.h

		draw(child, state, uiData, screenHeight, inputs)
	}
}
