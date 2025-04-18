#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "ui"
import "core:fmt"
import "core:math"
import "core:time"
import "core:math/rand"

WIDTH :: 1000
HEIGHT :: 720

main :: proc() {
	debug := false

	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))
	rl.SetWindowMinSize(300,200)

	//nBoxes := 7
	nBoxes := 8
	boxes := make([]^ui.Node, nBoxes)
	for i := 0; i < nBoxes; i += 1 {
		ds: ui.DebugSquare
		c: u8 = u8(i) * 20
		ds.color = {c, c, c, 255}

		node := new(ui.Node)
		node.element = ds
		node.w = 1
		node.h = 1
		boxes[i] = node
	}

//	horizSplit1 := ui.horizontal_split_from_nodes(boxes[2:])
//	horizSplit1 := ui.horizontal_split_from_nodes(boxes[3:])

	/*horizSplit1 := ui.horizontal_split_from_nodes(boxes[4:])
	horizSplit1.element.(ui.HorizontalSplit).children[0].preferNotResize = true
	horizSplit1.element.(ui.HorizontalSplit).children[2].preferNotResize = true
	horizSplit1.element.(ui.HorizontalSplit).children[3].preferNotResize = true*/

	horizSplit1 := ui.new_horizontal_split(nil)
	//for i := 0; i < 100; i += 1 {
	for i := 0; i < 5; i += 1 {
		append_elem(&(&horizSplit1.element.(ui.HorizontalSplit)).children, nil)
	}

	vertSplitMoment := ui.new_vertical_split(nil)
	for i := 0; i < 4; i += 1 {
		append_elem(&(&vertSplitMoment.element.(ui.VerticalSplit)).children, nil)
	}

	vert1 := ui.new_vertical_split_from_nodes(nil, {boxes[0], boxes[1], horizSplit1})
	vert1.element.(ui.VerticalSplit).children[1].w = 2
	vert1.element.(ui.VerticalSplit).children[0].preferNotResize = true
	vert1.element.(ui.VerticalSplit).children[0].minimumSize = 74 // correct krita minsize

	vert1.element.(ui.VerticalSplit).children[2].preferNotResize = true
	vert1.element.(ui.VerticalSplit).children[2].minimumSize = 264

	bottomVertSplit := ui.new_vertical_split_from_nodes(nil, boxes[2:4])

	//horizSplit2 := ui.horizontal_split_from_nodes({vert1, boxes[2]})
	horizSplit2 := ui.new_horizontal_split_from_nodes(nil, {vert1, bottomVertSplit})
	//horizSplit2.element.(ui.HorizontalSplit).children[0].h = 2
	horizSplit2.element.(ui.HorizontalSplit).children[0].h = 5
	boxes[2].preferNotResize = true

	//rootNode := vert1
	rootNode := horizSplit2
	//(&rootNode.element.(ui.HorizontalSplit)).resizeBarHeight = 8
	(&rootNode.element.(ui.HorizontalSplit)).children[0].minimumSize = 400

	/*for i := 0; i < len(horizSplit1.element.(ui.HorizontalSplit).children); i += 1 {
		button := ui.new_button(nil)

		button.minimumSize = 15
		vert := ui.new_vertical_split_from_nodes(nil, {button, ui.new_debug_square(nil)})
		vert.parent = rootNode.element.(ui.HorizontalSplit).children[0].element.(ui.VerticalSplit).children[2]
		vert.minimumSize = 15 + i32(60 * rand.float32())
		fmt.println(vert.minimumSize)
		vert.element.(ui.VerticalSplit).children[0].preferNotResize = true
		//rootNode.element.(ui.HorizontalSplit).children[0].element.(ui.VerticalSplit).children[2].element.(ui.HorizontalSplit).children[i] = vert
		horizSplit1.element.(ui.HorizontalSplit).children[i] = vert

		button.parent = vert
	}*/

	for i := 0; i < len(horizSplit1.element.(ui.HorizontalSplit).children); i += 1 {
		horizSplit1.element.(ui.HorizontalSplit).children[i] = ui.new_button(horizSplit1)
	}

	append_elem(&(&bottomVertSplit.element.(ui.VerticalSplit)).children, nil)
	bottomVertSplit.element.(ui.VerticalSplit).children[2] = bottomVertSplit.element.(ui.VerticalSplit).children[1]
	bottomVertSplit.element.(ui.VerticalSplit).children[1] = bottomVertSplit.element.(ui.VerticalSplit).children[0]
	vertSplitMoment.parent = bottomVertSplit
	bottomVertSplit.element.(ui.VerticalSplit).children[0] = vertSplitMoment
	for i := 0; i < len(vertSplitMoment.element.(ui.VerticalSplit).children); i += 1 {
		button := ui.new_button(vertSplitMoment)
		button.minimumSize = 15
		//button.parent = vertSplitMoment

		vertSplitMoment.element.(ui.VerticalSplit).children[i] = button

		iCopy := new(int)
		iCopy^ = i

		ui.button_set_on_click(button, iCopy, proc(iPtr: rawptr) {
			i := (transmute(^int)iPtr)^
			fmt.println("hello from", i)
		})

		/*(&button.element.(ui.Button)).onClickData = iCopy*/

		/*buttonCopy := new(^ui.Node)
		buttonCopy^ = button

		ui.button_set_on_click(button, buttonCopy, proc(nodeIn: rawptr) {
			node := (transmute(^^ui.Node)nodeIn)^

			x := ui.index_of_node_in_parent_split(node)
			fmt.println("hello from", x)
		})*/

		/*(&button.element.(ui.Button)).onClickData = buttonCopy
		(&button.element.(ui.Button)).onClickProc = proc(nodeIn: rawptr) {
			node := (transmute(^^ui.Node)nodeIn)^
			x := ui.index_of_node_in_parent_split(node)
			fmt.println("hello from", x)

			//fmt.println("hello from horiz button #", (transmute(^int)i)^)
		}*/
	}

	rootNode.w = rl.GetScreenWidth()
	rootNode.h = rl.GetScreenHeight()

	/*rootNode.element.(ui.HorizontalSplit).children[1].element.(ui.VerticalSplit).children[0].preferNotResize = true
	rootNode.element.(ui.HorizontalSplit).children[1].element.(ui.VerticalSplit).children[1].preferNotResize = true
	rootNode.element.(ui.HorizontalSplit).children[1].element.(ui.VerticalSplit).children[2].preferNotResize = false*/

	t := time.now()

	ui.scale_up_children(rootNode)
	boxes[2].h = 100

	if debug do fmt.println("scale_up_children()         time:", time.since(t))

	state := ui.ui_state_default_values()
	uiData := ui.init_ui_data()
	platformProcs := ui.get_raylib_platform_procs()

	lastmousey: i32 = 0

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		//rl.ClearBackground({255, 0, 0, 255})
		rl.ClearBackground({50, 50, 50, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		totalTime := time.now()

		inputs := ui.inputs_from_raylib()
		t = time.now()
		ui.handle_input(rootNode, &state, platformProcs, inputs)
		if debug do fmt.println("handle_input()             time:", time.since(t))

		t = time.now()
		if true || rl.IsKeyPressed(.F5) {
			ui.recompute_children_boxes(rootNode)
		}
		if debug do fmt.println("recompute_children_boxes() time:", time.since(t))

		t = time.now()

		if inputs.mouseLeftDown && inputs.mouseY != lastmousey {
			fmt.println("test")
		}
		lastmousey = inputs.mouseY

		ui.correct_boxes(rootNode, false)
		if debug do fmt.println("correct_boxes(..., false)  time:", time.since(t))

		t = time.now()
		ui.draw(rootNode, &state, &uiData, rl.GetScreenHeight(), inputs)
		if debug do fmt.println("draw()                     time:", time.since(t))

		t = time.now()
		ui.correct_boxes(rootNode, true)
		if debug do fmt.println("correct_boxes(..., true)   time:", time.since(t))
		//fmt.println("root parent:", rootNode.parent)

		if debug do fmt.println("TOTAL                   time:", time.since(totalTime))
		if debug do fmt.println()

		text := fmt.ctprintf("x: {}, y: {}", inputs.mouseX, inputs.mouseY)
		rl.DrawText(text, 5, 40, 24, {255,255,255,255})

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
