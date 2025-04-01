/*
We assume a Node is only ever present once in the UI.
If you use a Node twice in a VerticalSplit, for example, it will break resizing...
*/

package ui

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:math"

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
	preferNotResize: bool, // Used when in a VerticalSplit/HorizontalSplit
	minimumSize: i32, // Used when in a VerticalSplit/HorizontalSplit
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

// FIXME: Doesn't respect minimumSize
scale_up_children :: proc(node: ^Node) {
	#partial switch &e in node.element {
		case VerticalSplit:
			widthSum: i32 = 0
			for child in e.children {
				widthSum += child.w
				child.y = node.y
				child.h = node.h
			}

			if widthSum != node.w {
				//fmt.println("changed width:", widthSum, node.w)

				ratio := f64(node.w) / f64(widthSum)
				currX := node.x
				for child, i in e.children {
					child.x = currX

					if i == len(e.children) - 1 {
						child.w = node.w - (currX - node.x)
					} else {
						child.w = i32(math.ceil(f64(child.w) * ratio))
					}

					currX += child.w
				}

				assert(currX - node.x == node.w)
			}

			for &child in e.children {
				scale_up_children(child)
			}
		case HorizontalSplit:
			heightSum: i32 = 0
			for child in e.children {
				heightSum += child.h
				child.x = node.x
				child.w = node.w
			}

			if heightSum != node.h {
				//fmt.println("changed height:", heightSum, node.h)
				ratio := f64(node.h) / f64(heightSum)
				currY := node.y
				for child, i in e.children {
					child.y = currY

					if i == len(e.children) - 1 {
						child.h = node.h - (currY - node.y)
					} else {
						child.h = i32(math.ceil(f64(child.h) * ratio))
					}

					currY += child.h
				}

				assert(currY - node.y == node.h)
			}

			for &child in e.children {
				scale_up_children(child)
			}
	}
}

resize_vert :: proc(vert: ^VerticalSplit, index: int, diff: i32) {
	vert.children[index].w += diff
	for i := index + 1; i < len(vert.children); i += 1 {
		vert.children[i].x += diff
	}
}

// Returns -1 when none found
// TODO: Could make a separate function for resizing up, since it would prob only return first that wants resize or 0
find_resizeable_child_index :: proc(node: ^Node, respectMinimumSize: bool) -> int {
	secondChoice := -1

	switch &e in node.element {
		case VerticalSplit:
			for child, index in e.children {
				if respectMinimumSize && child.w <= child.minimumSize {
					continue
				}

				if !child.preferNotResize {
					return index
				}

				if child.preferNotResize && secondChoice == -1 {
					secondChoice = index
				}
			}
		case HorizontalSplit:
			for child, index in e.children {
				if respectMinimumSize && child.h <= child.minimumSize {
					continue
				}

				if !child.preferNotResize {
					return index
				}

				if child.preferNotResize && secondChoice == -1 {
					secondChoice = index
				}
			}
		case DebugSquare:
	}

	return secondChoice
}

// Returns the amount not yet resized.
// Returns 0 if done resizing.
try_resize_child :: proc(node: ^Node, itsIndex: int, diff: i32) -> i32 {
	diffCopy := diff

	#partial switch &e in node.parent.element {
		case VerticalSplit:
			remainder := (node.w + diffCopy) - node.minimumSize
			if remainder < 0 {
				diffCopy -= remainder
			}

			node.w += diffCopy
			assert(node.w >= node.minimumSize)
			for i := itsIndex + 1; i < len(e.children); i += 1 {
				e.children[i].x += diffCopy
			}

			return remainder < 0 ? remainder : 0
		case HorizontalSplit:
			remainder := (node.h + diffCopy) - node.minimumSize
			if remainder < 0 {
				diffCopy -= remainder
			}

			node.h += diffCopy
			assert(node.h >= node.minimumSize)
			for i := itsIndex + 1; i < len(e.children); i += 1 {
				e.children[i].y += diffCopy
			}

			return remainder < 0 ? remainder : 0
	}

	assert(false)
	return 0
}

recompute_children_boxes :: proc(node: ^Node) {
	#partial switch &e in node.element {
		case VerticalSplit:
			widthSum: i32 = 0
			for child in e.children {
				widthSum += child.w
				child.y = node.y
				child.h = node.h
			}

			xDiff := node.x - e.children[0].x
			if xDiff != 0 {
				for child in e.children {
					child.x += xDiff
				}
			}

			diff := node.w - widthSum
			if diff != 0 {
				for {
					//respectMinimumSize := diff < 0
					respectMinimumSize := diff < 0 ? true : false

					resizeableIndex := find_resizeable_child_index(node, respectMinimumSize)
					if resizeableIndex == -1 {
						break
					}

					diff = try_resize_child(e.children[resizeableIndex], resizeableIndex, diff)
					if diff == 0 {
						break
					}
				}
			}

			for &child in e.children {
				recompute_children_boxes(child)
			}
		case HorizontalSplit:
			heightSum: i32 = 0
			for child in e.children {
				heightSum += child.h
				child.x = node.x
				child.w = node.w
			}

			if node.y != e.children[0].y {
				diff := node.y - e.children[0].y
				for child in e.children {
					child.y += diff
				}
			}

			if true || heightSum != node.h {
				//fmt.println("changed height:", heightSum, node.h)

				for child, i in e.children {
					if child.preferNotResize {
						continue // FIXME
					}

					diff := node.h - heightSum
					fmt.println("diff:", diff)
					child.h += diff
					//e.children[i+1].y += diff
					for j := i+1; j < len(e.children); j += 1 {
						e.children[j].y += diff
					}
					break
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

	// Detect hover on vertical bars first, like Intellij IDEA and Krita does
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
				if false || n_parents(child) == 3 {
					cString := fmt.ctprintf("{}", child.w)
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
				if false || n_parents(child) == 3 {
					cString := fmt.ctprintf("{}", child.h)
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
		inNode.minimumSize = 100
		append(&n.children, inNode)
	}
	node.element = n^
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

horizontal_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := new(HorizontalSplit)
	for &inNode in nodes {
		inNode.parent = node
		inNode.minimumSize = 100
		append(&n.children, inNode)
	}
	node.element = n^
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}
