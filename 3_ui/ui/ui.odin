package ui

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"

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

			xPos := node.x
			yPos := node.y
			for &child in e.children {
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

			xPos := node.x
			yPos := node.y
			for &child in e.children {
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
