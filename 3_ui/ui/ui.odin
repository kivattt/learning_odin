/*
We assume a Node is only ever present once in the UI.
If you use a Node twice in a VerticalSplit, for example, it will break resizing...
*/

package ui

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:math"
import "core:c"

PASSIVE_OUTLINE_COLOR :: rl.Color{70, 70, 70, 255}
HOVERED_OUTLINE_COLOR :: rl.Color{150, 150, 150, 255}
BACKGROUND_COLOR :: rl.Color{25, 25, 25, 255}

Box :: struct {
	x: i32,
	y: i32,
	w: i32,
	h: i32,
}

Color :: struct {
	r: f32,
	g: f32,
	b: f32,
	a: f32,
}

VerticalSplit :: struct {
	children: [dynamic]^Node,
	resizeBarWidth: i32,
}

HorizontalSplit :: struct {
	children: [dynamic]^Node,
	resizeBarHeight: i32,
}

DebugSquare :: struct {
	color: rl.Color,
}

Element :: union {
	DebugSquare,
	Button,
	VerticalSplit,
	HorizontalSplit,
}

Node :: struct {
	parent: ^Node,
	element: Element,
	using box: Box,
	oldBox: Box,
	preferNotResize: bool, // Used when in a VerticalSplit/HorizontalSplit
	minimumSize: i32, // Used when in a VerticalSplit/HorizontalSplit
}

UserInterfaceState :: struct {
	lastFrameCursor: MouseCursor,
	lastMouse1Pressed: bool,

	hoveredNode: ^Node,

	hoveredResizeBar: ^Node,
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

UiColors :: struct {
	passiveOutlineColor: rl.Color,
	hoveredOutlineColor: rl.Color,
	backgroundColor: rl.Color,
}

get_default_ui_colors :: proc() -> UiColors {
	return UiColors{
		passiveOutlineColor = PASSIVE_OUTLINE_COLOR,
		hoveredOutlineColor = HOVERED_OUTLINE_COLOR,
		backgroundColor = BACKGROUND_COLOR,
	}
}

UserInterfaceData :: struct {
	colors: UiColors,

	buttonShader: rl.Shader,
	buttonShaderBoxLoc: c.int,
	buttonShaderScreenHeightLoc: c.int,
	buttonShaderColorLoc: c.int,
	buttonShaderPixelsRoundedLoc: c.int,

	buttonShaderDropshadowColorLoc: c.int,
	buttonShaderDropshadowSmoothnessLoc: c.int,
}

init_ui_data :: proc() -> (data: UserInterfaceData) {
	data.colors = get_default_ui_colors()

	//data.buttonShader = rl.LoadShader(nil, "ui/shaders/outline_rounded.glsl") // FIXME: Use filepath join
	data.buttonShader = rl.LoadShader(nil, "ui/shaders/rectangle_rounded.glsl") // FIXME: Use filepath join
	//data.buttonShaderBoxLoc = rl.GetShaderLocation(data.buttonShader, "box")
	data.buttonShaderBoxLoc = rl.GetShaderLocation(data.buttonShader, "rect")
	data.buttonShaderScreenHeightLoc = rl.GetShaderLocation(data.buttonShader, "screen_height")
	data.buttonShaderColorLoc = rl.GetShaderLocation(data.buttonShader, "color")
	data.buttonShaderPixelsRoundedLoc = rl.GetShaderLocation(data.buttonShader, "pixels_rounded_in")

	data.buttonShaderDropshadowColorLoc = rl.GetShaderLocation(data.buttonShader, "dropshadow_color")
	data.buttonShaderDropshadowSmoothnessLoc = rl.GetShaderLocation(data.buttonShader, "dropshadow_smoothness")
	return
}

deinit_ui_data :: proc(uiData: ^UserInterfaceData) {
	rl.UnloadShader(uiData.buttonShader)
}

MouseCursor :: enum {
	DEFAULT,
	RESIZE_EW,
	RESIZE_NS,
}

PlatformProcs :: struct {
	setMouseCursorIconProc: proc(cursor: MouseCursor),
}

get_dummy_platform_procs :: proc() -> (procs: PlatformProcs) {
	return
}

get_raylib_platform_procs :: proc() -> (procs: PlatformProcs) {
	procs.setMouseCursorIconProc = proc(cursor: MouseCursor) {
		switch cursor {
			case .DEFAULT:
				rl.SetMouseCursor(.DEFAULT)
			case .RESIZE_EW:
				rl.SetMouseCursor(.RESIZE_EW)
			case .RESIZE_NS:
				rl.SetMouseCursor(.RESIZE_NS)
		}
	}
	return
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

// Scales up all children to the node's size.
// It respects their minimum sizes.
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
						child.w = max(child.minimumSize, node.w - (currX - node.x))
					} else {
						child.w = max(child.minimumSize, i32(math.ceil(f64(child.w) * ratio)))
					}

					currX += child.w
				}
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
						child.h = max(child.minimumSize, node.h - (currY - node.y))
					} else {
						child.h = max(child.minimumSize, i32(math.ceil(f64(child.h) * ratio)))
					}

					currY += child.h
				}
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
find_resizeable_child_index :: proc(node: ^Node, respectMinimumSize: bool) -> int {
	secondChoice := -1

	#partial switch &e in node.element {
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
	}

	return secondChoice
}

// Returns the amount not yet resized.
// Returns 0 if done resizing.
resize_child_until_minimum_size_for_window_resize :: proc(node: ^Node, itsIndex: int, diff: i32) -> i32 {
	diffCopy := diff

	assert(node.parent != nil)
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
			resizeableChild := e.children[resizeableIndex]
			selectedChild := e.children[selectedIndex]

			newSize := resizeableChild.h - abs(diffCopy)
			if newSize < resizeableChild.minimumSize {
				remainder = newSize - resizeableChild.minimumSize

				if diffCopy > 0 {
					remainder = -remainder
				}
				diffCopy -= remainder
			}

			if diffCopy < 0 {
				assert(resizeableIndex <= selectedIndex)

				e.children[selectedIndex + 1].y += diffCopy
				e.children[selectedIndex + 1].h -= diffCopy
				assert(e.children[selectedIndex + 1].h >= e.children[selectedIndex + 1].minimumSize)

				// Change size of the resizeable child
				resizeableChild.h += diffCopy
				assert(resizeableChild.h >= resizeableChild.minimumSize)

				// Move all the ones inbetween
				for i := resizeableIndex + 1; i < selectedIndex + 1; i += 1 {
					e.children[i].y += diffCopy
				}
			} else if diffCopy > 0 {
				assert(resizeableIndex > selectedIndex)

				selectedChild.h += diffCopy
				assert(selectedChild.h >= selectedChild.minimumSize)

				// Change size of the resizeable child
				resizeableChild.y += diffCopy
				resizeableChild.h -= diffCopy
				assert(resizeableChild.h >= resizeableChild.minimumSize)

				// Move all the ones inbetween
				for i := selectedIndex + 1; i < resizeableIndex; i += 1 {
					e.children[i].y += diffCopy
				}
			}
	}

	return remainder
}

// Returns how much we moved
resize_individual_child :: proc(parentSplitNode: ^Node, index: int, diff: i32) -> i32 {
	if diff == 0 {
		return 0
	}

	diffCopy := diff
	howMuchWeMoved: i32 = 0

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

		howMuchWeMoved += diffCopy
		diffCopy = resize_child_until_minimum_size_for_individual_resize(parentSplitNode, resizeableIndex, index, diffCopy)
		howMuchWeMoved -= diffCopy
		if diffCopy == 0 {
			break
		}
	}

	return howMuchWeMoved
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

inner_box_from_box :: proc(box: Box) -> Box {
	return Box{
		x = box.x + 5,
		y = box.y + 5,
		w = box.w - 10,
		h = box.h - 10,

		/*x = box.x + 20,
		y = box.y + 20,
		w = box.w - 40,
		h = box.h - 40,*/
	}
}

correct_boxes :: proc(node: ^Node, undo: bool) {
	#partial switch &e in node.element {
	case VerticalSplit:
		if undo {
			for child in e.children {
				child.box = child.oldBox
			}
		} else {
			for child in e.children {
				child.oldBox = child.box
				child.h = node.h
				//child.w -= e.resizeBarWidth //
			}

			/*lastChild := e.children[len(e.children) - 1]
			if lastChild.w >= lastChild.minimumSize {
				diff := lastChild.x + lastChild.w - (node.x + node.w)
				lastChild.w -= diff
			}*/

			for i := 0; i < len(e.children) - 1; i += 1 {
				e.children[i].w -= e.resizeBarWidth
			}
		}

		for child in e.children {
			correct_boxes(child, undo)
		}
	case HorizontalSplit:
		if undo {
			for child in e.children {
				child.box = child.oldBox
			}
		} else {
			for child in e.children {
				child.oldBox = child.box
				child.w = node.w
				//child.h -= e.resizeBarHeight //
			}

			for i := 0; i < len(e.children) - 1; i += 1 {
				e.children[i].h -= e.resizeBarHeight
			}

			/*lastChild := e.children[len(e.children) - 1]

			if lastChild.h >= lastChild.minimumSize {
				diff := lastChild.y + lastChild.h - (node.y + node.h)
				lastChild.h -= diff
			}*/
		}

		for child in e.children {
			correct_boxes(child, undo)
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

NodePointerAndBox :: struct {
	node: ^Node,
	box: Box,
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

	fmt.println(typeid_of(type_of(node.parent.element)))
	assert(false)
	return -1
}

find_hovered_node :: proc(node: ^Node, x, y: i32) -> ^Node {
	switch &e in node.element {
	case VerticalSplit:
		for child in e.children {
			if is_coord_in_box(child.box, x, y) {
				return find_hovered_node(child, x, y)
			}
		}

		return nil
	case HorizontalSplit:
		for child in e.children {
			if is_coord_in_box(child.box, x, y) {
				return find_hovered_node(child, x, y)
			}
		}

		return nil
	case Button:
		if is_coord_in_box(node.box, x, y) {
			return node
		} else {
			return nil
		}
	case DebugSquare:
		if is_coord_in_box(node.box, x, y) {
			return node
		} else {
			return nil
		}
	}

	assert(false)
	return nil
}

find_hovered_resize_bar :: proc(node: ^Node, x, y: i32) -> ^Node {
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

		theXLeftMost := e.x + e.w - e.parent.element.(VerticalSplit).resizeBarWidth
		if theXLeftMost >= e.parent.x + e.parent.w {
			continue
		}

		theX := e.x + e.w - e.parent.element.(VerticalSplit).resizeBarWidth / 2
		if x < (theX - 8) || x > (theX + 8) {
			continue
		}

		return e
	}

	for e in horizBarPositions {
		if x < e.x || x > (e.x + e.w) {
			continue
		}

		theYLeftMost := e.y + e.h - e.parent.element.(HorizontalSplit).resizeBarHeight
		if theYLeftMost >= e.parent.y + e.parent.h {
			continue
		}

		theY := e.y + e.h - e.parent.element.(HorizontalSplit).resizeBarHeight / 2
		if y < (theY - 8) || y > (theY + 8) {
			continue
		}

		return e
	}

	return nil
}

is_coord_in_box :: proc(box: Box, x, y: i32) -> bool {
	if box.w <= 0 || box.h <= 0 {
		return false
	}

	return x >= box.x && x <= box.x + box.w && y >= box.y && y <= box.y + box.h
}

Inputs :: struct {
	mouseLeftDown: bool,
	mouseX: i32,
	mouseY: i32,
	/*mouseMiddleDown: bool,
	mouseRightDown: bool,*/
}

inputs_from_raylib :: proc() -> (inputs: Inputs) {
	inputs.mouseX = rl.GetMouseX()
	inputs.mouseY = rl.GetMouseY()
	inputs.mouseLeftDown = rl.IsMouseButtonDown(.LEFT)
	return
}

// Call this on your root node
handle_input :: proc(node: ^Node, state: ^UserInterfaceState, platformProcs: PlatformProcs, inputs: Inputs) {
	if !rl.IsWindowFocused() {
		state.hoveredResizeBar = nil
		state.selectedResizeBar = nil
		state.hoveredNode = nil
		return
	}

	x := inputs.mouseX
	y := inputs.mouseY

	isLeftDown := inputs.mouseLeftDown

	if state.selectedResizeBar != nil {
		if state.selectedResizeBarIndexInParent == -1 {
			state.resizeBarStartX = x
			state.resizeBarStartY = y
			state.selectedResizeBarIndexInParent = index_of_node_in_parent_split(state.selectedResizeBar)
		}

		if isLeftDown {
			#partial switch &e in state.selectedResizeBar.parent.element {
				case VerticalSplit:
					xDiff := x - state.resizeBarStartX
					howMuchWeMoved := resize_individual_child(state.selectedResizeBar.parent, state.selectedResizeBarIndexInParent, xDiff)
					state.resizeBarStartX += howMuchWeMoved
				case HorizontalSplit:
					yDiff := y - state.resizeBarStartY
					howMuchWeMoved := resize_individual_child(state.selectedResizeBar.parent, state.selectedResizeBarIndexInParent, yDiff)
					state.resizeBarStartY += howMuchWeMoved
			}

			return
		} else {
			state.selectedResizeBar = nil
			state.selectedResizeBarIndexInParent = -1
		}
	}

	state.hoveredResizeBar = find_hovered_resize_bar(node, x, y)

	cursorWanted := MouseCursor.DEFAULT
	if state.hoveredResizeBar != nil {
		state.hoveredNode = nil

		assert(state.hoveredResizeBar.parent != nil)
		#partial switch &e in state.hoveredResizeBar.parent.element {
			case VerticalSplit:
				cursorWanted = MouseCursor.RESIZE_EW
			case HorizontalSplit:
				cursorWanted = MouseCursor.RESIZE_NS
		}
	} else {
		state.hoveredNode = find_hovered_node(node, x, y)
		if state.hoveredNode != nil {
			#partial switch &e in state.hoveredNode.element {
				case Button:
					button_handle_input(state.hoveredNode, state, inputs)
			}
		}
	}

	if cursorWanted != state.lastFrameCursor {
		if platformProcs.setMouseCursorIconProc != nil {
			platformProcs.setMouseCursorIconProc(cursorWanted)
		}
	}
	state.lastFrameCursor = cursorWanted

	if isLeftDown && !state.lastMouse1Pressed {
		state.selectedResizeBar = state.hoveredResizeBar
	}

	state.lastMouse1Pressed = isLeftDown
}

draw :: proc(node: ^Node, state: ^UserInterfaceState, uiData: ^UserInterfaceData, screenHeight: i32, inputs: Inputs) {
	switch n in node.element {
		case VerticalSplit:
			for child in n.children {
				draw(child, state, uiData, screenHeight, inputs)
			}

			// Resize bars
			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x + child.w
				y := child.y

				color := uiData.colors.passiveOutlineColor
				if child == state.hoveredResizeBar || child == state.selectedResizeBar {
					color = uiData.colors.hoveredOutlineColor
				}
				rl.DrawRectangle(x, y, n.resizeBarWidth, child.h, color)
			}

			for child in n.children {
				if false && n_parents(child) == 3 {
					cString := fmt.ctprintf("{}", child.w)
					//cString := fmt.ctprintf("{}", child.minimumSize)
					rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2, 30, rl.WHITE)
				}
			}
		case HorizontalSplit:
			for child in n.children {
				draw(child, state, uiData, screenHeight, inputs)
			}

			// Resize bars
			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x
				y := child.y + child.h

				color := uiData.colors.passiveOutlineColor
				if child == state.hoveredResizeBar || child == state.selectedResizeBar {
					color = uiData.colors.hoveredOutlineColor
				}
				rl.DrawRectangle(x, y, child.w, n.resizeBarHeight, color)
			}

			for child in n.children {
				if false && n_parents(child) == 3 {
					cString := fmt.ctprintf("{}", child.h)
					//cString := fmt.ctprintf("{}", child.minimumSize)
					rl.DrawText(cString, child.x + child.w/2, child.y + child.h/2, 30, rl.WHITE)
				}
			}
		case DebugSquare:
			rl.DrawRectangle(node.x, node.y, node.w, node.h, n.color)
		case Button:
			button_draw(node, state, uiData, screenHeight, inputs)
	}
}

new_vertical_split_from_nodes :: proc(parent: ^Node, nodes: []^Node) -> ^Node {
	node := new(Node)
	n := VerticalSplit{}
	n.resizeBarWidth = 1

	for &inNode in nodes {
		inNode.parent = node
		inNode.minimumSize = 100
		append(&n.children, inNode)
	}

	node.element = n
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

new_horizontal_split :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	horizSplit := HorizontalSplit{}
	horizSplit.resizeBarHeight = 1
	node.element = horizSplit
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

new_vertical_split :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	vertSplit := VerticalSplit{}
	vertSplit.resizeBarWidth = 1

	node.element = vertSplit
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

new_horizontal_split_from_nodes :: proc(parent: ^Node, nodes: []^Node) -> ^Node {
	node := new(Node)
	n := HorizontalSplit{}
	n.resizeBarHeight = 1

	for &inNode in nodes {
		inNode.parent = node
		inNode.minimumSize = 100
		append(&n.children, inNode)
	}

	node.element = n
	node.parent = parent
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
		case Button:
			free(node)
	}
}

// Remember to free() the return value!
new_debug_square :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	debugSquare := DebugSquare{
		color = BACKGROUND_COLOR,
	}
	node.element = debugSquare
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}

// Remember to delete() the return value!
get_me_some_debug_squares :: proc(numBoxes: int) -> (boxes: []^Node) {
	boxes = make([]^Node, numBoxes)

	for i := 0; i < numBoxes; i += 1 {
		debugSquare := new_debug_square(nil) // FIXME?
		c: u8 = u8(i) * 20
		//ds := &debugSquare.element.(DebugSquare)
		//ds.color = {c, c, c, 255}
		boxes[i] = debugSquare
	}

	return
}

// Remember to free() the return value!
new_button :: proc(parent: ^Node) -> ^Node {
	node := new(Node)
	button := Button{
		color = PASSIVE_OUTLINE_COLOR,
		pixels_rounded = 4,
		backgroundColor = BACKGROUND_COLOR,
	}
	node.element = button
	node.parent = parent
	node.w = 1
	node.h = 1
	node.minimumSize = 100
	return node
}
