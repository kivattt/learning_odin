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
	rl.SetWindowMinSize(550,200)

	nBoxes := 8
	boxes := make([]^ui.Node, nBoxes)
	for i := 0; i < nBoxes; i += 1 {
		if i == 1 { // A label
			boxes[i] = ui.new_label(nil, "Fuck macOS Fuck macOS Fuck macOS\nFuck macOS Fuck macOS Fuck macOS\nFuck macOS Fuck macOS Fuck macOS\nFuck macOS Fuck macOS Fuck macOS\nFuck macOS Fuck macOS Fuck macOS", .Middle, .Middle)
		} else {
			c: u8 = u8(i) * 20
			boxes[i] = ui.new_padding_rect(nil, rl.Color{c, c, c, 255})
		}
	}

	horizSplit1 := ui.new_horizontal_split_unresizeable(nil)
	for i := 0; i < 6; i += 1 {
		append_elem(&(&horizSplit1.element.(ui.HorizontalSplitUnresizeable)).children, nil)
	}

	vertSplitMoment := ui.new_vertical_split(nil)
	for i := 0; i < 4; i += 1 {
		append_elem(&(&vertSplitMoment.element.(ui.VerticalSplit)).children, nil)
	}

	vert1 := ui.new_vertical_split_from_nodes(nil, {boxes[0], boxes[1], horizSplit1})
	vert1.element.(ui.VerticalSplit).children[1].w = 2
	vert1.element.(ui.VerticalSplit).children[0].minimumSize = 74 // correct krita minsize

	vert1.element.(ui.VerticalSplit).children[1].preferResize = true

	vert1.element.(ui.VerticalSplit).children[2].minimumSize = 264

	bottomVertSplit := ui.new_vertical_split_from_nodes(nil, boxes[2:4])

	horizSplit2 := ui.new_horizontal_split_from_nodes(nil, {vert1, bottomVertSplit})
	bottomVertSplit.minimumSize = 20
	horizSplit2.element.(ui.HorizontalSplit).children[0].h = 5

	rootNode := horizSplit2

	for i := 0; i < len(horizSplit1.element.(ui.HorizontalSplitUnresizeable).children); i += 1 {
		if i == len(horizSplit1.element.(ui.HorizontalSplitUnresizeable).children) - 2 {
			visualBreak := ui.new_visual_break(horizSplit1, .Horizontal, 12)
			horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i] = visualBreak
			continue
		} else if i == len(horizSplit1.element.(ui.HorizontalSplitUnresizeable).children) - 1 {
			label := ui.new_label(nil, "Long boi", .Middle, .Left)
			button := ui.new_button(nil)
			(&button.element.(ui.Button)).text = "the long"
			ui.button_set_on_click(button, nil, proc(iPtr: rawptr) {
				fmt.println("long boi click")
			})
			button.preferResize = true
			size: i32 = 30
			button.minimumSize = size

			thing := ui.new_vertical_split_unresizeable_from_nodes(horizSplit1, {label, button})
			container := ui.new_container(horizSplit1, thing, {0,0,0,0})

			horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i] = container
			horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i].minimumSize = size
			continue
		}

		s := "Combined"
		if i == 1 {
			s = "Z"
		} else if i == 2 {
			s = "Mist"
		} else if i == 3 {
			s = "Normal"
		}

		label := ui.new_label(nil, s, .Middle, .Left)
		button := ui.new_checkbox(nil)

		//size: i32 = 30
		size: i32 = 27

		button.minimumSize = size - 10

		filler := ui.new_padding_rect(nil)
		filler.minimumSize = 5

		thing: ^ui.Node
		if i == 3 {
			filler2 := ui.new_padding_rect(nil)
			filler2.minimumSize = 5

			button2 := ui.new_checkbox(nil)
			button2.minimumSize = size - 10

			thing = ui.new_vertical_split_unresizeable_from_nodes(horizSplit1, {button, filler, button2, filler2, label})
		} else {
			thing = ui.new_vertical_split_unresizeable_from_nodes(horizSplit1, {button, filler, label})
		}
		container := ui.new_container(horizSplit1, thing, {0,0,0,0})

		horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i] = container
		horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i].minimumSize = size
	}

	append_elem(&(&bottomVertSplit.element.(ui.VerticalSplit)).children, nil)
	bottomVertSplit.element.(ui.VerticalSplit).children[2] = bottomVertSplit.element.(ui.VerticalSplit).children[1]
	bottomVertSplit.element.(ui.VerticalSplit).children[1] = bottomVertSplit.element.(ui.VerticalSplit).children[0]
	vertSplitMoment.parent = bottomVertSplit
	vertSplitMoment.minimumSize = 320
	bottomVertSplit.element.(ui.VerticalSplit).children[0] = vertSplitMoment
	for i := 0; i < len(vertSplitMoment.element.(ui.VerticalSplit).children); i += 1 {
		button := ui.new_button(vertSplitMoment)
		button.minimumSize = 80
		(&button.element.(ui.Button)).text = string(fmt.ctprintf("hello {}", i))

		vertSplitMoment.element.(ui.VerticalSplit).children[i] = ui.new_container(vertSplitMoment, button, ui.BACKGROUND_COLOR)

		iCopy := new(int)
		iCopy^ = i

		ui.button_set_on_click(button, iCopy, proc(iPtr: rawptr) {
			i := (transmute(^int)iPtr)^
			fmt.println("hello from", i)
		})
	}

	rootNode.w = rl.GetScreenWidth()
	rootNode.h = rl.GetScreenHeight()

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
		rl.ClearBackground({255, 0, 0, 255})
		//rl.ClearBackground({50, 50, 50, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		totalTime := time.now()

		inputs := ui.inputs_from_raylib()
		t = time.now()
		ui.handle_input(rootNode, &state, platformProcs, inputs)
		debug = rootNode.element.(ui.HorizontalSplit).children[0].element.(ui.VerticalSplit).children[2].element.(ui.HorizontalSplitUnresizeable).children[0].element.(ui.Container).child.element.(ui.VerticalSplitUnresizeable).children[0].element.(ui.Checkbox).checked
		if debug do fmt.println("handle_input()             time:", time.since(t))

		t = time.now()
		if true || rl.IsKeyPressed(.F5) {
			ui.recompute_children_boxes(rootNode)
		}
		if debug do fmt.println("recompute_children_boxes() time:", time.since(t))

		t = time.now()

		lastmousey = inputs.mouseY

		ui.correct_boxes(rootNode, false)
		if debug do fmt.println("correct_boxes(..., false)  time:", time.since(t))

		t = time.now()
		ui.draw(rootNode, &state, &uiData, rl.GetScreenHeight(), inputs)
		if debug do fmt.println("draw()                     time:", time.since(t))

		t = time.now()
		ui.correct_boxes(rootNode, true)
		if debug do fmt.println("correct_boxes(..., true)   time:", time.since(t))

		if debug do fmt.println("TOTAL                   time:", time.since(totalTime))
		if debug do fmt.println()

		//text := fmt.ctprintf("x: {}, y: {}", inputs.mouseX, inputs.mouseY)
		//rl.DrawText(text, 5, 40, 24, {255,255,255,255})

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
