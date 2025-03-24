package ui

import rl "vendor:raylib"
import "core:fmt"

Box :: struct {
	x: i32,
	y: i32,
	w: i32,
	h: i32,
}

VerticalSplit :: struct {
	children: [dynamic]^Node,
}

HorizontalSplit :: struct {
	children: [dynamic]^Node,
}

DebugSquare :: struct {
	color: rl.Color,
}

Element :: union {
	DebugSquare,
	VerticalSplit,
	HorizontalSplit,
}

Node :: struct {
	parent: ^Node,
	element: Element,
	using box: Box,
	relativeSize: f64, // Used when it's in a VerticalSplit/HorizontalSplit
}

handle_input :: proc(node: ^Node) {
	x := rl.GetMouseX()
	y := rl.GetMouseY()

	#partial switch &e in node.element {
		case VerticalSplit:
			
			for &child in e.children {
				
			}
	}
}

draw :: proc(node: ^Node) {
	switch n in node.element {
		case VerticalSplit:
			for child in n.children {
				draw(child)
			}
			for child in n.children {
				x := child.x + child.w - 1
				y := child.y
				rl.DrawRectangle(x, y, 2, child.h, {130,130,130,255})
			}
		case HorizontalSplit:
			for child in n.children {
				draw(child)
			}
			for child in n.children {
				x := child.x
				y := child.y + child.h - 1
				rl.DrawRectangle(x, y, child.w, 2, {130,130,130,255})
			}
		case DebugSquare:
			rl.DrawRectangle(node.x, node.y, node.w, node.h, n.color)
	}
}

recompute_children_boxes :: proc(node: ^Node) {
	#partial switch &e in node.element {
		case VerticalSplit:
			divisor: f64 = 0
			for child in e.children {
				divisor += child.relativeSize
			}
			//divisor /= f64(len(e.children))

			xPos := node.x
			yPos := node.y
			for &child in e.children {
				//thisWidth := f64(node.w) / (child.relativeSize / divisor)
				thisWidth := f64(node.w) * (child.relativeSize / divisor)
				child.x = xPos
				child.y = yPos
				child.w = i32(thisWidth)
				child.h = node.h

				xPos += i32(thisWidth)

			}
			for &child in e.children {
				recompute_children_boxes(child)
			}
		case HorizontalSplit:
			divisor: f64 = 0
			for child in e.children {
				divisor += child.relativeSize
			}
			//divisor /= f64(len(e.children))

			xPos := node.x
			yPos := node.y
			for &child in e.children {
				//thisWidth := f64(node.w) / (child.relativeSize / divisor)
				thisHeight := f64(node.h) * (child.relativeSize / divisor)
				child.x = xPos
				child.y = yPos
				child.w = node.w
				child.h = i32(thisHeight)

				yPos += i32(thisHeight)
			}
			for &child in e.children {
				recompute_children_boxes(child)
			}
	}
}

vertical_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := new(VerticalSplit)
	for &node in nodes {
		append(&n.children, node)
	}
	node.element = n^
	node.relativeSize = 1
	return node
}

horizontal_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := new(HorizontalSplit)
	for &node in nodes {
		append(&n.children, node)
	}
	node.element = n^
	node.relativeSize = 1
	return node
}
