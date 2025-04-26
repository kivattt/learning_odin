package ui

import rl "vendor:raylib"

// Uses the childrens minimumSize as their widths.
// A child with preferResize = true means its width will grow dynamically
// We assume only ONE child can have preferResize = true. We panic if this doesn't hold!
VerticalSplitUnresizeable :: struct {
	children: [dynamic]^Node,
}

vertical_split_unresizeable_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
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

	// TODO: Rolling X position type thing
	for i := 0; i < len(verticalSplitUnresizeable.children); i += 1 {
		child := verticalSplitUnresizeable.children[i]
		if child.preferResize {
			widthSumOfNextChildren: i32 = 0
			for j := i + 1; j < len(verticalSplitUnresizeable.children); j += 1 {
				widthSumOfNextChildren += verticalSplitUnresizeable.children[j].minimumSize
			}

			child.w = max(child.minimumSize, node.w - 
		}

		child.w = child.minimumSize
		child.h = node.h
	}

	for child in verticalSplitUnresizeable.children {
		child.w = child.minimumSize
		child.h = node.h
	}
}
