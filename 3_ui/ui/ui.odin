/*
We assume a Node is only ever present once in the UI.
If you use a Node twice in a VerticalSplit, for example, it will break resizing...
*/

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
	size: i32, // Used when it's in a VerticalSplit/HorizontalSplit
}

UserInterfaceState :: struct {
	hoveredNode: ^Node,
	selectedNode: ^Node,
}

n_parents :: proc(node: ^Node) -> int {
	sum := 0
	p := node.parent
	for p != nil {
		sum += 1
		p = p.parent
	}
	return sum
}

recompute_children_boxes :: proc(node: ^Node) {
	#partial switch &e in node.element {
		case VerticalSplit:
			widthSum: i32 = 0
			for child in e.children {
				widthSum += child.size
			}

			if widthSum != node.w {
				fmt.println("didnt match:", widthSum, node.w)
				ratio := f64(node.w) / f64(widthSum)
				for child in e.children {
					child.size = i32(f64(child.size) * ratio)
				}
			}

			for &child in e.children {
				recompute_children_boxes(child)
			}
		case HorizontalSplit:
			widthSum: i32 = 0
			for child in e.children {
				widthSum += child.size
			}

			if widthSum != node.w {
				ratio := f64(widthSum) / f64(node.w)
				for child in e.children {
					child.size = i32(f64(child.size) * ratio)
				}
			}

			for &child in e.children {
				recompute_children_boxes(child)
			}
	}
}

// Remember to delete() the return values?
get_resizeable_children :: proc(node: ^Node) -> (horizBars: [dynamic]^Node, vertBars: [dynamic]^Node) {
	#partial switch &e in node.element {
		case VerticalSplit:
			//for &child in e.children {
			for &child in e.children[:max(0, len(e.children) - 1)] {
				append(&vertBars, child)
			}

			for &child in e.children {
				horizBarsToAdd, vertBarsToAdd := get_resizeable_children(child)
				append(&vertBars, ..vertBarsToAdd[:])
				append(&horizBars, ..horizBarsToAdd[:])

				delete(horizBarsToAdd)
				delete(vertBarsToAdd)
			}
		case HorizontalSplit:
			//for &child in e.children {
			for &child in e.children[:max(0, len(e.children) - 1)] {
				append(&horizBars, child)
			}

			for &child in e.children {
				horizBarsToAdd, vertBarsToAdd := get_resizeable_children(child)
				append(&vertBars, ..vertBarsToAdd[:])
				append(&horizBars, ..horizBarsToAdd[:])

				delete(horizBarsToAdd)
				delete(vertBarsToAdd)
			}
	}

	return
}

// Returns -1 on error
index_of_node_in_parent_split :: proc(node: ^Node) -> int {
	assert(node != nil && node.parent != nil)

	#partial switch &e in node.parent.element {
		case VerticalSplit:
			for child, i in e.children {
				if node == child {
					return i
				}
			}
		case HorizontalSplit:
			for child, i in e.children {
				if node == child {
					return i
				}
			}
	}

	assert(false)
	return -1
}

handle_input :: proc(node: ^Node, state: ^UserInterfaceState) {
	x := rl.GetMouseX()
	y := rl.GetMouseY()
	state.hoveredNode = nil

	if state.selectedNode != nil {
		if rl.IsMouseButtonDown(.LEFT) {
			#partial switch &e in state.selectedNode.parent.element {
				case VerticalSplit:
				case HorizontalSplit:
			}
			return
		} else {
			state.selectedNode = nil
		}
	}

	// find hovered node.
	horizBarPositions, vertBarPositions := get_resizeable_children(node)

	// Detect hover on vertical bars first, like Intellij IDEA does
	for e in vertBarPositions {
		if y < e.y || y > (e.y + e.h) {
			continue
		}

		theX := e.x + e.w - 1
		if x < (theX - 8) || x > (theX + 8) {
			continue
		}

		state.hoveredNode = e
		break
	}

	if state.hoveredNode == nil {
		for e in horizBarPositions {
			if x < e.x || x > (e.x + e.w) {
				continue
			}

			theY := e.y + e.h - 1
			if y < (theY - 8) || y > (theY + 8) {
				continue
			}

			state.hoveredNode = e
			break
		}
	}

	if rl.IsMouseButtonDown(.LEFT) {
		state.selectedNode = state.hoveredNode

		// Probably unnecessary
		//state.hoveredNode = nil
	}

	delete(horizBarPositions)
	delete(vertBarPositions)
}

draw :: proc(node: ^Node, state: ^UserInterfaceState) {
	switch n in node.element {
		case VerticalSplit:
			for child in n.children {
				draw(child, state)
			}

			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x + child.w - 1
				y := child.y

				//nParents := n_parents(child)
				//c := u8(nParents == 1 ? 255 : (nParents == 2 ? 127 : 40))

				c := u8(70)
				if child == state.hoveredNode || child == state.selectedNode {
					c = 255
				}
				rl.DrawRectangle(x, y, 1, child.h, {c,c,c,255})
			}

			for child in n.children {
				if n_parents(child) == 3 {
					cString := fmt.ctprintf("%.3f", child.size)
					rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2, 30, rl.WHITE)
				}
			}
		case HorizontalSplit:
			for child in n.children {
				draw(child, state)
			}

			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x
				y := child.y + child.h - 1

				//nParents := n_parents(child)
				//c := u8(nParents == 1 ? 255 : (nParents == 2 ? 127 : 40))
				c := u8(70)
				if child == state.hoveredNode || child == state.selectedNode {
					c = 255
				}
				rl.DrawRectangle(x, y, child.w, 1, {c,c,c,255})
			}

			for child in n.children {
				if n_parents(child) == 3 {
					cString := fmt.ctprintf("%.3f", child.size)
					rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2, 30, rl.WHITE)
				}
			}
		case DebugSquare:
			rl.DrawRectangle(node.x, node.y, node.w, node.h, n.color)
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
	//node.size = 1
	node.size = 100
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
	//node.size = 1
	node.size = 100
	return node
}
