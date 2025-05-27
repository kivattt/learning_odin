package ui

import rl "vendor:raylib"

// Uses the childrens minimumSize as their widths.
// A child with preferResize = true means its width will grow dynamically
// We assume only ONE child can have preferResize = true. We panic if this doesn't hold!
VerticalSplitUnresizeable :: struct {
	children: [dynamic]^Node,
}

new_vertical_split_unresizeable :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	verticalSplitUnresizeable: VerticalSplitUnresizeable
	node.element = verticalSplitUnresizeable
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

new_vertical_split_unresizeable_from_nodes :: proc(parent: ^Node, nodes: []^Node) -> ^Node {
	verticalSplitUnresizeable: VerticalSplitUnresizeable

	node := new(Node)

	for &inNode in nodes {
		inNode.parent = node
		append(&verticalSplitUnresizeable.children, inNode)
	}

	node.element = verticalSplitUnresizeable
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

vertical_split_unresizeable_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	visible := visible_area_for_drawing(node)
	rl.DrawRectangle(visible.x, visible.y, visible.w, visible.h, color_to_rl_color(BACKGROUND_COLOR))

	verticalSplitUnresizeable := node.element.(VerticalSplitUnresizeable)

	// Panic when more than 1 child has preferResize = true
	alreadyFoundChildWithPreferResize := false
	for child in verticalSplitUnresizeable.children {
		if child.preferResize {
			if alreadyFoundChildWithPreferResize {
				panic("Multiple children had preferResize = true in a VerticalSplitUnresizeable element.")
			}
			alreadyFoundChildWithPreferResize = true
		}
	}

	theX: i32 = node.x

	for i := 0; i < len(verticalSplitUnresizeable.children); i += 1 {
		child := verticalSplitUnresizeable.children[i]
		child.w = child.minimumSize

		if child.preferResize {
			widthSumOfNextChildren: i32 = 0
			for j := i + 1; j < len(verticalSplitUnresizeable.children); j += 1 {
				widthSumOfNextChildren += verticalSplitUnresizeable.children[j].minimumSize
			}

			child.w = max(child.minimumSize, node.w - (theX - node.x) - widthSumOfNextChildren)
		}

		child.x = theX
		child.y = node.y

		child.h = node.h

		theX += child.w

		draw(child, state, uiData, screenHeight, inputs)
		//rl.DrawRectangleLines(child.x+1, child.y+1, child.w-1, child.h-1, {255,0,0,100})
	}
}
