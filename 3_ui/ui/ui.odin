package ui

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:math"
//import "core:math/fixed"

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

n_parents :: proc(node: ^Node) -> int {
	sum := 0
	p := node.parent
	for p != nil {
		sum += 1
		p = p.parent
	}
	//fmt.println(sum)
	return sum
}

draw :: proc(node: ^Node) {
	switch n in node.element {
		case VerticalSplit:
			for child in n.children {
				draw(child)
			}

			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x + child.w - 1
				y := child.y

				//c := u8(255 / n_parents(child))
				nParents := n_parents(child)
				c := u8(nParents == 1 ? 255 : (nParents == 2 ? 127 : 40))
				rl.DrawRectangle(x, y, 2, child.h, {c,c,c,255})
			}

			/*for child in n.children {
				cString := fmt.ctprintf("{}", n_parents(child))
				rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2 + i32(30 * n_parents(child)), i32(80 / f32(0 + n_parents(child))), rl.WHITE)
			}*/
		case HorizontalSplit:
			for child in n.children {
				draw(child)
			}

			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x
				y := child.y + child.h - 1

				//c := u8(255 / n_parents(child))
				nParents := n_parents(child)
				c := u8(nParents == 1 ? 255 : (nParents == 2 ? 127 : 40))
				rl.DrawRectangle(x, y, child.w, 2, {c,c,c,255})
			}

			/*for child in n.children {
				cString := fmt.ctprintf("{}", n_parents(child))
				rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2 + i32(30 * n_parents(child)), i32(80 / f32(0 + n_parents(child))), rl.WHITE)
			}*/
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

			xPositions := make([]i32, len(e.children))
			xPos := f64(node.x)
			for &child, i in e.children {
				width := f64(node.w) * (child.relativeSize / divisor)
				xPositions[i] = i32(xPos)
				xPos += width
			}

			for &child, i in e.children {
				child.x = xPositions[i]
				child.y = node.y
				child.h = node.h

				if i == len(e.children) - 1 {
					child.w = node.x + node.w - xPositions[i]
				} else {
					child.w = xPositions[i+1] - xPositions[i]
				}
			}

			for &child in e.children {
				recompute_children_boxes(child)
			}
		case HorizontalSplit:
			divisor: f64 = 0
			for child in e.children {
				divisor += child.relativeSize
			}

			yPositions := make([]i32, len(e.children))
			yPos := f64(node.y)
			for &child, i in e.children {
				height := f64(node.h) * (child.relativeSize / divisor)
				yPositions[i] = i32(yPos)
				yPos += height
			}

			for &child, i in e.children {
				child.x = node.x
				child.y = yPositions[i]
				child.w = node.w

				if i == len(e.children) - 1 {
					child.h = node.y + node.h - yPositions[i]
				} else {
					child.h = yPositions[i+1] - yPositions[i]
				}
			}

			for &child in e.children {
				recompute_children_boxes(child)
			}
	}
}

vertical_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := new(VerticalSplit)
	for &inNode in nodes {
		inNode.parent = node
		append(&n.children, inNode)
	}
	node.element = n^
	node.relativeSize = 1
	return node
}

horizontal_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := new(HorizontalSplit)
	for &inNode in nodes {
		inNode.parent = node
		append(&n.children, inNode)
	}
	node.element = n^
	node.relativeSize = 1
	return node
}
