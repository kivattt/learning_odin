package ui

import rl "vendor:raylib"
import "core:fmt"

// A container is a rectangle with a background color and contains a child element.
// The child element can then have a border of size borderPixels

Container :: struct {
	child: ^Node,
	background: rl.Color,
	borderPixels: i32,
}

new_container :: proc{
	new_container_simple,
	new_container_extra,
}

// Remember to free() the return value!
new_container_simple :: proc(parent, child: ^Node, background: rl.Color) -> ^Node {
	return new_container_extra(parent, child, background, 5)
}

// Remember to free() the return value!
new_container_extra :: proc(parent, child: ^Node, background: rl.Color, borderPixels: i32) -> ^Node {
	node := new(Node)

	container := Container{
		child = child,
		background = background,
		borderPixels = borderPixels,
	}
	node.element = container
	node.parent = parent
	child.parent = node
	//node.w = 1
	//node.h = 1
	//node.minimumSize = 100
	node.minimumSize = child.minimumSize

	return node
}

container_inner_box :: proc(node: ^Node) -> Box {
	return inner_box_from_box_n(node.box, node.element.(Container).borderPixels)
}

container_draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	container := node.element.(Container)

	visible := visible_area_for_drawing(node)
	if container.background.a != 0 {
		rl.DrawRectangle(visible.x, visible.y, visible.w, visible.h, container.background)
	}

	container.child.box = inner_box_from_box(node.box, container.borderPixels)
	draw(container.child, state, uiData, screenHeight, inputs)
}

num_interactable :: proc(node: ^Node) -> (num: int, onlyChild: ^Node) {
	if is_interactable(node) {
		num = 1
		onlyChild = node
	} else {
		#partial switch &e in node.element {
			case VerticalSplit:
				for &child in e.children {
					n, c := num_interactable(child)
					num += n
					if c != nil {
						onlyChild = c
					}
				}
			case HorizontalSplit:
				for &child in e.children {
					n, c := num_interactable(child)
					num += n
					if c != nil {
						onlyChild = c
					}
				}
			case VerticalSplitUnresizeable:
				for &child in e.children {
					n, c := num_interactable(child)
					num += n
					if c != nil {
						onlyChild = c
					}
				}
			case HorizontalSplitUnresizeable:
				for &child in e.children {
					n, c := num_interactable(child)
					num += n
					if c != nil {
						onlyChild = c
					}
				}
		}
	}

	return
}

is_interactable :: proc(node: ^Node) -> bool {
	#partial switch &e in node.element {
		case Container, Button, Checkbox:
			return true
	}

	return false
}
