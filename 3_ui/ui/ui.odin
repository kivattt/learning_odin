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
import "core:testing"

PASSIVE_OUTLINE_COLOR :: rl.Color{70, 70, 70, 255}
//PASSIVE_OUTLINE_COLOR :: rl.Color{110, 110, 110, 255}
HOVERED_OUTLINE_COLOR :: rl.Color{150, 150, 150, 255}
VISUAL_BREAK_COLOR :: rl.Color{80,80,80, 255}
BACKGROUND_COLOR :: rl.Color{25, 25, 25, 255}
TEXT_COLOR :: rl.Color{230, 230, 230, 255}
HIGHLIGHT_COLOR :: rl.Color{75, 110, 177, 255}
DEFAULT_FONT_SIZE :: 18

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

Element :: union {
	PaddingRect,
	Label,
	Button,
	Checkbox,
	VerticalSplit,
	HorizontalSplit,
	VerticalSplitUnresizeable,
	HorizontalSplitUnresizeable,
	VisualBreak,
	Container,
}

Node :: struct {
	parent: ^Node,
	element: Element,
	using box: Box,
	oldBox: Box,
	preferResize: bool, // Used when in a VerticalSplit, HorizontalSplit, VerticalSplitUnresizeable
	minimumSize: i32, // Used when in a VerticalSplit, HorizontalSplit
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
	highlightColor: rl.Color,
}

get_default_ui_colors :: proc() -> UiColors {
	return UiColors{
		passiveOutlineColor = PASSIVE_OUTLINE_COLOR,
		hoveredOutlineColor = HOVERED_OUTLINE_COLOR,
		backgroundColor = BACKGROUND_COLOR,
		highlightColor = HIGHLIGHT_COLOR,
	}
}

UserInterfaceData :: struct {
	colors: UiColors,

	fontSize: i32,
	fontVariable: rl.Font,

	// Button shader
	buttonShader: rl.Shader,
	buttonShaderRectLoc: c.int,
	buttonShaderScreenHeightLoc: c.int,
	buttonShaderColorLoc: c.int,
	buttonShaderPixelsRoundedLoc: c.int,
	buttonShaderDropshadowColorLoc: c.int,
	buttonShaderDropshadowSmoothnessLoc: c.int,
	buttonShaderOutlineColorLoc: c.int,

	// Checkbox shader
	checkboxShader: rl.Shader,
	checkboxShaderRectLoc: c.int,
	checkboxShaderScreenHeightLoc: c.int,
	checkboxShaderColorLoc: c.int,
	checkboxShaderPixelsRoundedLoc: c.int,
	checkboxShaderDropshadowColorLoc: c.int,
	checkboxShaderDropshadowOffsetLoc: c.int,
	checkboxShaderDrawCheckmark: c.int,
}

FONT_VARIABLE_DATA :: #load("fonts/Adwaita/AdwaitaSans-Regular.ttf")

init_ui_data :: proc() -> (data: UserInterfaceData) {
	data.colors = get_default_ui_colors()

	data.fontSize = DEFAULT_FONT_SIZE
	data.fontVariable = rl.LoadFontFromMemory(
		".ttf",
		raw_data(FONT_VARIABLE_DATA),
		i32(len(FONT_VARIABLE_DATA)),
		data.fontSize,
		nil,
		0,
	)

	// Button shader
	data.buttonShader = rl.LoadShader(nil, "ui/shaders/button.glsl") // FIXME: Use filepath join
	data.buttonShaderRectLoc = rl.GetShaderLocation(data.buttonShader, "rect")
	data.buttonShaderScreenHeightLoc = rl.GetShaderLocation(data.buttonShader, "screen_height")
	data.buttonShaderColorLoc = rl.GetShaderLocation(data.buttonShader, "color")
	data.buttonShaderPixelsRoundedLoc = rl.GetShaderLocation(data.buttonShader, "pixels_rounded_in")
	data.buttonShaderDropshadowColorLoc = rl.GetShaderLocation(data.buttonShader, "dropshadow_color")
	data.buttonShaderOutlineColorLoc = rl.GetShaderLocation(data.buttonShader, "outline_color")
	data.buttonShaderDropshadowSmoothnessLoc = rl.GetShaderLocation(data.buttonShader, "dropshadow_smoothness")

	// Checkbox shader
	data.checkboxShader = rl.LoadShader(nil, "ui/shaders/checkbox.glsl")
	data.checkboxShaderRectLoc = rl.GetShaderLocation(data.checkboxShader, "rect")
	data.checkboxShaderScreenHeightLoc = rl.GetShaderLocation(data.checkboxShader, "screen_height")
	data.checkboxShaderColorLoc = rl.GetShaderLocation(data.checkboxShader, "color")
	data.checkboxShaderPixelsRoundedLoc = rl.GetShaderLocation(data.checkboxShader, "pixels_rounded_in")
	data.checkboxShaderDropshadowColorLoc = rl.GetShaderLocation(data.checkboxShader, "dropshadow_color")
	data.checkboxShaderDropshadowOffsetLoc = rl.GetShaderLocation(data.checkboxShader, "dropshadow_offset")
	data.checkboxShaderDrawCheckmark = rl.GetShaderLocation(data.checkboxShader, "draw_checkmark")
	return
}

deinit_ui_data :: proc(uiData: ^UserInterfaceData) {
	rl.UnloadShader(uiData.buttonShader)
}

MouseCursor :: enum {
	DEFAULT,
	RESIZE_EW,
	RESIZE_NS,
	POINTING_HAND,
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
			case .POINTING_HAND:
				rl.SetMouseCursor(.POINTING_HAND)
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

first_parent_container :: proc(node: ^Node) -> ^Node {
	p := node.parent
	for p != nil {
		#partial switch &e in p.element {
			case Container:
				return p
		}

		p = p.parent
	}

	return nil
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
		case Container:
			e.child.box = container_inner_box(node)
			scale_up_children(e.child)
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

				if child.preferResize {
					return index
				}

				if !child.preferResize && secondChoice == -1 {
					secondChoice = index
				}
			}
		case HorizontalSplit:
			for child, index in e.children {
				if respectMinimumSize && child.h <= child.minimumSize {
					continue
				}

				if child.preferResize {
					return index
				}

				if !child.preferResize && secondChoice == -1 {
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

inner_box_from_box :: proc{
	inner_box_from_box_simple,
	inner_box_from_box_n,
}

inner_box_from_box_simple :: proc(box: Box) -> Box {
	return inner_box_from_box_n(box, 5)
}

inner_box_from_box_n :: proc(box: Box, n: i32) -> Box {
	return Box{
		x = box.x + n,
		y = box.y + n,
		w = box.w - 2*n,
		h = box.h - 2*n,
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
			}

			if node.parent != nil {
				lastChild := e.children[len(e.children) - 1]
				lastChild.w -= abs(node.w - node.oldBox.w)
			}

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
			}

			if node.parent != nil {
				lastChild := e.children[len(e.children) - 1]
				lastChild.h -= abs(node.h - node.oldBox.h)
			}

			for i := 0; i < len(e.children) - 1; i += 1 {
				e.children[i].h -= e.resizeBarHeight
			}
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
		case Container:
			recompute_children_boxes(e.child)
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
		case Container:
			vertBarsToAdd, horizBarsToAdd := get_resizeable_children(e.child)
			append(&vertBars, ..vertBarsToAdd[:])
			append(&horizBars, ..horizBarsToAdd[:])

			delete(horizBarsToAdd)
			delete(vertBarsToAdd)
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

// Only used in interactable elements except for Container
// That is, Button and Checkbox
is_hovered :: proc(node: ^Node, firstParentContainer: ^Node, state: ^UserInterfaceState, inputs: Inputs) -> bool {
	hovered := false
	if firstParentContainer == nil {
		hovered = is_coord_in_box(node.box, inputs.mouseX, inputs.mouseY)
	} else {
		hovered = is_coord_in_box(container_inner_box(firstParentContainer), inputs.mouseX, inputs.mouseY)
	}

	hovered &= state.hoveredNode == node
	return hovered
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
	case VerticalSplitUnresizeable:
		for child in e.children {
			if is_coord_in_box(child.box, x, y) {
				return find_hovered_node(child, x, y)
			}
		}

		return nil
	case HorizontalSplitUnresizeable:
		for child in e.children {
			if is_coord_in_box(child.box, x, y) {
				return find_hovered_node(child, x, y)
			}
		}

		return nil
	case Container:
		if is_coord_in_box(container_inner_box(node), x, y) {
			container := node.element.(Container)
			n, onlyChild := num_interactable(container.child)

			// If there is only 1 interactable element in the Container,
			// we handle input for it even when the mouse isn't directly over it.
			if n == 1 {
				return onlyChild
			} else {
				return find_hovered_node(e.child, x, y)
			}
		}
		return nil
	case Label, Button, Checkbox, PaddingRect:
		if is_coord_in_box(node.box, x, y) {
			return node
		} else {
			return nil
		}
	case VisualBreak:
		return nil
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

@(test)
box_clip_within_test :: proc(t: ^testing.T) {
	a, b, result: Box

	a = Box{0,0,50,50}
	b = Box{0,0,50,50}
	result = box_clip_within(a, b)
	testing.expect(t, result == b)

	a = Box{0,0,50,50}
	b = Box{0,0,40,40}
	result = box_clip_within(a, b)
	testing.expect(t, result == b)

	a = Box{50,50,50,50}
	b = Box{60,60,20,20}
	result = box_clip_within(a, b)
	testing.expect(t, result == b)

	a = Box{10,0,50,50}
	b = Box{0, 0,50,50}
	result = box_clip_within(a, b)
	testing.expect(t, result == Box{10,0,40,50})

	a = Box{50,50,50,50}
	b = Box{0, 0,50,50}
	result = box_clip_within(a, b)
	testing.expect(t, (result.w == 0) && (result.h == 0))

	a = Box{0, 0,50,50}
	b = Box{50,50,50,50}
	result = box_clip_within(a, b)
	testing.expect(t, (result.w == 0) && (result.h == 0))
}

// Returns `inner` such that it fits within `outer`
box_clip_within :: proc(outer, inner: Box) -> Box {
	left  := clamp(inner.x, outer.x, outer.x + outer.w)
	right := clamp(inner.x + inner.w, outer.x, outer.x + outer.w)
	up    := clamp(inner.y, outer.y, outer.y + outer.h)
	down  := clamp(inner.y + inner.h, outer.y, outer.y + outer.h)

	return Box{
		x = left,
		y = up,
		w = right - left,
		h = down - up,
	}
}

// Traverses the parents to return the visible area for drawing
visible_area_for_drawing :: proc(node: ^Node) -> Box {
	nodeCopy := node
	visibleArea := node.box

	for nodeCopy.parent != nil {
		visibleArea = box_clip_within(nodeCopy.parent.box, visibleArea)
		nodeCopy = nodeCopy.parent
	}

	return visibleArea
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
					cursorWanted = MouseCursor.POINTING_HAND
				case Checkbox:
					checkbox_handle_input(state.hoveredNode, state, inputs)
					cursorWanted = MouseCursor.POINTING_HAND
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
				if child.w >= child.parent.x + child.parent.w {
					break
				}

				draw(child, state, uiData, screenHeight, inputs)
			}

			// Resize bars
			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x + child.w
				y := child.y

				if x >= child.parent.x + child.parent.w {
					break
				}

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
				if child.y >= child.parent.y + child.parent.h {
					break
				}

				draw(child, state, uiData, screenHeight, inputs)
			}

			// Resize bars
			for child in n.children[:max(0, len(n.children)-1)] {
				x := child.x
				y := child.y + child.h

				if y >= child.parent.y + child.parent.h {
					break
				}

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
		case VerticalSplitUnresizeable:
			vertical_split_unresizeable_draw(node, state, uiData, screenHeight, inputs)
		case HorizontalSplitUnresizeable:
			horizontal_split_unresizeable_draw(node, state, uiData, screenHeight, inputs)
		case Container:
			container_draw(node, state, uiData, screenHeight, inputs)
		case PaddingRect:
			padding_rect_draw(node, state, uiData, screenHeight, inputs)
		case Button:
			button_draw(node, state, uiData, screenHeight, inputs)
		case Checkbox:
			checkbox_draw(node, state, uiData, screenHeight, inputs)
		case Label:
			label_draw(node, state, uiData, screenHeight, inputs)
		case VisualBreak:
			visual_break_draw(node, state, uiData, screenHeight, inputs)
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
		case VerticalSplitUnresizeable:
			for &child in e.children {
				delete_node_and_its_children(child)
			}

			delete(e.children)
			free(node)
		case HorizontalSplitUnresizeable:
			for &child in e.children {
				delete_node_and_its_children(child)
			}

			delete(e.children)
			free(node)
		case Container:
			delete_node_and_its_children(e.child)
			free(node)
		case PaddingRect, Button, Checkbox, Label, VisualBreak:
			free(node)
	}
}
