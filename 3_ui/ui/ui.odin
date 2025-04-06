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
	lastFrameCursor: rl.MouseCursor,
	hoveredNode: ^Node,
	selectedResizeBar: ^Node,
	selectedResizeBarIndexInParent: int,
	resizeBarStartX: i32,
	resizeBarStartY: i32,
}

ui_state_default_values :: proc() -> UserInterfaceState {
	return UserInterfaceState{
		selectedResizeBarIndexInParent = -1
	}
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
// TODO: Could make a separate function for (window) resizing up, since it would prob only return first that wants resize or 0
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
resize_child_until_minimum_size_for_window_resize :: proc(node: ^Node, itsIndex: int, diff: i32) -> i32 {
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

// direction: -1 for previous, 1 for next
// Returns -1 if none found.
find_first_resizeable_child_index :: proc(parentSplitNode: ^Node, index: int, direction: int) -> int {
	directionCopy := direction

	#partial switch &e in parentSplitNode.element {
		case VerticalSplit:
			if directionCopy == -1 { // Above/previous
				for i := index; i >= 0; i -= 1 {
					if e.children[i].w > e.children[i].minimumSize {
						return i
					}
				}
			} else if directionCopy == 1 { // Below/next
				for i := index + 1; i < len(e.children); i += 1 {
					if e.children[i].w > e.children[i].minimumSize {
						return i
					}
				}
			}
		case HorizontalSplit:
			if directionCopy == -1 { // Above/previous
				for i := index; i >= 0; i -= 1 {
					if e.children[i].h > e.children[i].minimumSize {
						return i
					}
				}
			} else if directionCopy == 1 { // Below/next
				for i := index + 1; i < len(e.children); i += 1 {
					if e.children[i].h > e.children[i].minimumSize {
						return i
					}
				}
			}
	}

	return -1
}

// Returns the amount not yet resized (remainder).
// Returns 0 if done resizing.
resize_child_until_minimum_size_for_individual_resize :: proc(node: ^Node, resizeableIndex: int, selectedIndex: int, diff: i32) -> i32 {
	diffCopy := diff
	remainder: i32 = 0

	#partial switch &e in node.element {
		case VerticalSplit:
			resizeableChild := e.children[resizeableIndex]
			selectedChild := e.children[selectedIndex]

			newSize := resizeableChild.w - abs(diffCopy)
			if newSize < resizeableChild.minimumSize {
				remainder = newSize - resizeableChild.minimumSize

				if diffCopy > 0 {
					remainder = -remainder
				}
				diffCopy -= remainder
			}

			if diffCopy < 0 {
				assert(resizeableIndex <= selectedIndex)

				e.children[selectedIndex + 1].x += diffCopy
				e.children[selectedIndex + 1].w -= diffCopy
				assert(e.children[selectedIndex + 1].w >= e.children[selectedIndex + 1].minimumSize)

				// Change size of the resizeable child
				resizeableChild.w += diffCopy
				assert(resizeableChild.w >= resizeableChild.minimumSize)

				// Move all the ones inbetween
				for i := resizeableIndex + 1; i < selectedIndex + 1; i += 1 {
					e.children[i].x += diffCopy
				}
			} else if diffCopy > 0 {
				assert(resizeableIndex > selectedIndex)

				selectedChild.w += diffCopy
				assert(selectedChild.w >= selectedChild.minimumSize)

				// Change size of the resizeable child
				resizeableChild.x += diffCopy
				resizeableChild.w -= diffCopy
				assert(resizeableChild.w >= resizeableChild.minimumSize)

				// Move all the ones inbetween
				for i := selectedIndex + 1; i < resizeableIndex; i += 1 {
					e.children[i].x += diffCopy
				}
			}
		case HorizontalSplit:
			// TODO: Do the horizontal split aswell
	}

	return remainder
}

resize_individual_child :: proc(parentSplitNode: ^Node, index: int, diff: i32) {
	if diff == 0 {
		return
	}


	diffCopy := diff

	iterations := 0
	for {
		iterations += 1
		assert(iterations < 10000) // Infinite loop check

		direction := diffCopy < 0 ? -1 : 1

		// The index which we're going to lower its size
		resizeableIndex := find_first_resizeable_child_index(parentSplitNode, index, direction)
		if resizeableIndex == -1 {
			break
		}

		diffCopy = resize_child_until_minimum_size_for_individual_resize(parentSplitNode, resizeableIndex, index, diffCopy)
		if diffCopy == 0 {
			break
		}
	}
}

try_resize_children_to_fit :: proc(rootNode: ^Node, rootNodeChildren: []^Node, diff: i32) {
	if diff == 0 {
		return
	}

	diffCopy := diff

	iterations := 0
	for {
		iterations += 1
		assert(iterations < 10000) // Infinite loop check

		respectMinimumSize := diffCopy < 0 ? true : false

		resizeableIndex := find_resizeable_child_index(rootNode, respectMinimumSize)
		if resizeableIndex == -1 {
			break
		}

		diffCopy = resize_child_until_minimum_size_for_window_resize(rootNodeChildren[resizeableIndex], resizeableIndex, diffCopy)
		if diffCopy == 0 {
			break
		}
	}
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
			try_resize_children_to_fit(node, e.children[:], diff)

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

			yDiff := node.y - e.children[0].y
			if yDiff != 0 {
				for child in e.children {
					child.y += yDiff
				}
			}

			diff := node.h - heightSum
			try_resize_children_to_fit(node, e.children[:], diff)

			for &child in e.children {
				recompute_children_boxes(child)
			}
	}
}

// Remember to delete() the return values?
get_resizeable_children :: proc(node: ^Node) -> (vertBars: [dynamic]^Node, horizBars: [dynamic]^Node) {
	#partial switch &e in node.element {
		case VerticalSplit:
			for &child in e.children[:max(0, len(e.children) - 1)] {
				append(&vertBars, child)
			}

			for &child in e.children {
				vertBarsToAdd, horizBarsToAdd := get_resizeable_children(child)
				append(&vertBars, ..vertBarsToAdd[:])
				append(&horizBars, ..horizBarsToAdd[:])

				delete(horizBarsToAdd)
				delete(vertBarsToAdd)
			}
		case HorizontalSplit:
			for &child in e.children[:max(0, len(e.children) - 1)] {
				append(&horizBars, child)
			}

			for &child in e.children {
				vertBarsToAdd, horizBarsToAdd := get_resizeable_children(child)
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

find_hovered_resize_bar :: proc(node: ^Node, x, y: i32) -> ^Node {
	//horizBarPositions, vertBarPositions := get_resizeable_children(node)
	vertBarPositions, horizBarPositions := get_resizeable_children(node)
	defer {
		delete(vertBarPositions)
		delete(horizBarPositions)
	}

	// Detect hover on vertical bars first. This feels the most intuitive.
	// Intellij IDEA, Krita and REAPER all seem to do this.
	for e in vertBarPositions {
		if y < e.y || y > (e.y + e.h) {
			continue
		}

		theX := e.x + e.w - 1
		if x < (theX - 8) || x > (theX + 8) {
			continue
		}

		return e
	}

	for e in horizBarPositions {
		if x < e.x || x > (e.x + e.w) {
			continue
		}

		theY := e.y + e.h - 1
		if y < (theY - 8) || y > (theY + 8) {
			continue
		}

		return e
	}

	return nil
}

// Call this on your root node
// FIXME: I think left-clicking has a 1-frame delay. Could add a test for that
handle_input :: proc(node: ^Node, state: ^UserInterfaceState) {
	x := rl.GetMouseX()
	y := rl.GetMouseY()

	if state.selectedResizeBar != nil {
		if state.selectedResizeBarIndexInParent == -1 {
			state.resizeBarStartX = x
			state.resizeBarStartY = y
			state.selectedResizeBarIndexInParent = index_of_node_in_parent_split(state.selectedResizeBar)
		}

		if rl.IsMouseButtonDown(.LEFT) {
			#partial switch &e in state.selectedResizeBar.parent.element {
				case VerticalSplit:
					xDiff := x - state.resizeBarStartX
					state.resizeBarStartX += xDiff
					resize_individual_child(state.selectedResizeBar.parent, state.selectedResizeBarIndexInParent, xDiff)
				case HorizontalSplit:
					yDiff := y - state.resizeBarStartY
					state.resizeBarStartY += yDiff
					resize_individual_child(state.selectedResizeBar.parent, state.selectedResizeBarIndexInParent, yDiff)
			}

			return
		} else {
			state.selectedResizeBar = nil
			state.selectedResizeBarIndexInParent = -1
		}
	}

	state.hoveredNode = find_hovered_resize_bar(node, x, y)

	cursorWanted := rl.MouseCursor.DEFAULT
	if state.hoveredNode != nil {
		#partial switch &e in state.hoveredNode.parent.element {
			case VerticalSplit:
				cursorWanted = rl.MouseCursor.RESIZE_EW
			case HorizontalSplit:
				cursorWanted = rl.MouseCursor.RESIZE_NS
		}
	}

	if cursorWanted != state.lastFrameCursor {
		rl.SetMouseCursor(cursorWanted)
	}
	state.lastFrameCursor = cursorWanted

	if rl.IsMouseButtonDown(.LEFT) {
		state.selectedResizeBar = state.hoveredNode
	}
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
				if child == state.hoveredNode || child == state.selectedResizeBar {
					c = 255
				}
				rl.DrawRectangle(x, y, 1, child.h, {c,c,c,255})
			}

			for child in n.children {
				if true || n_parents(child) == 3 {
					//cString := fmt.ctprintf("{}", child.w)
					cString := fmt.ctprintf("{}", child.minimumSize)
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
				if child == state.hoveredNode || child == state.selectedResizeBar {
					c = 255
				}
				rl.DrawRectangle(x, y, child.w, 1, {c,c,c,255})
			}

			for child in n.children {
				if true || n_parents(child) == 3 {
					//cString := fmt.ctprintf("{}", child.h)
					cString := fmt.ctprintf("{}", child.minimumSize)
					rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2, 30, rl.WHITE)
				}
			}
		case DebugSquare:
			rl.DrawRectangle(node.x, node.y, node.w, node.h, n.color)
			rl.DrawRectangle(node.x+1, node.y+1, 12, 12, {0,0,255,255})
	}
}

vertical_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := VerticalSplit{}

	for &inNode in nodes {
		inNode.parent = node
		inNode.minimumSize = 100
		append(&n.children, inNode)
	}

	node.element = n
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

horizontal_split_from_nodes :: proc(nodes: []^Node) -> ^Node {
	node := new(Node)
	n := HorizontalSplit{}

	for &inNode in nodes {
		inNode.parent = node
		inNode.minimumSize = 100
		append(&n.children, inNode)
	}

	node.element = n
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

delete_node_and_its_children :: proc(node: ^Node) {
	switch &e in node.element {
		case VerticalSplit:
			for &child in e.children {
				delete_node_and_its_children(child)
			}

			delete(e.children)
			free(node)
		case HorizontalSplit:
			for &child in e.children {
				delete_node_and_its_children(child)
			}

			delete(e.children)
			free(node)
		case DebugSquare:
			free(node)
	}
}

// Remember to delete() the return value!
get_me_some_debug_squares :: proc(numBoxes: int) -> (boxes: []^Node) {
	boxes = make([]^Node, numBoxes)

	for i := 0; i < numBoxes; i += 1 {
		ds: DebugSquare
		c: u8 = u8(i) * 20
		ds.color = {c, c, c, 255}

		node := new(Node)
		node.element = ds
		node.w = 1
		node.h = 1
		boxes[i] = node
	}

	return
}
