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
			label := ui.new_label(nil, "Text goes here. Text goes here.\nText goes here. Text goes here.\nText goes here. Text goes here.\nText goes here. Text goes here.\nText goes here. Text goes here.\n", .Middle, .Middle, ui.TEXT_COLOR, ui.BACKGROUND_COLOR)
			boxes[i] = ui.new_container(boxes[i], label, {0,0,0,0})
			boxes[i].preferResize = true
		} else {
			c: u8 = u8(i) * 20
			boxes[i] = ui.new_padding_rect(nil, 100, ui.Color{c, c, c, 255})
		}
	}

	horizSplit1 := ui.new_horizontal_split_unresizeable(nil)
	for i := 0; i < 10; i += 1 {
		append_elem(&(&horizSplit1.element.(ui.HorizontalSplitUnresizeable)).children, nil)
	}

	vertSplitMoment := ui.new_vertical_split(nil)
	for i := 0; i < 4; i += 1 {
		append_elem(&(&vertSplitMoment.element.(ui.VerticalSplit)).children, nil)
	}

	debugSize: i32 = 27

	debugCheckbox := ui.new_checkbox(nil)
	debugCheckbox.minimumSize = debugSize - 10

	debugLabel := ui.new_label_simple(nil, "Debug mode", .Middle, .Left)
	debugVert := ui.new_vertical_split_unresizeable_from_nodes(nil, {debugCheckbox, ui.new_padding_rect_extra(nil, 5, ui.UNSET_DEFAULT_COLOR), debugLabel})
	debugVert.minimumSize = debugSize

	debugSection := ui.new_container_simple(nil, debugVert, ui.BACKGROUND_COLOR)
	(&debugSection.element.(ui.Container)).allowOuterBoxInput = true
	middle := ui.new_horizontal_split_unresizeable_from_nodes(nil, {debugSection, boxes[1]})

	vert1 := ui.new_vertical_split_from_nodes(nil, {boxes[0], middle, horizSplit1})
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
		if i == len(horizSplit1.element.(ui.HorizontalSplitUnresizeable).children) - 6 {
			visualBreak := ui.new_visual_break(horizSplit1, .Horizontal, 12)
			horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i] = visualBreak
			continue
		} else if i >= len(horizSplit1.element.(ui.HorizontalSplitUnresizeable).children) - 3 {
			textbox := ui.new_textbox(horizSplit1, "Search...")
			if i & 1 == 0 {
				(&textbox.element.(ui.TextBox)).labelStr = "I'm uneditable..."
				(&textbox.element.(ui.TextBox)).editable = false
			}
			container := ui.new_container(horizSplit1, textbox, {0,0,0,0})
			size: i32 = 30

			horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i] = container
			horizSplit1.element.(ui.HorizontalSplitUnresizeable).children[i].minimumSize = size
			continue
		} else if i >= len(horizSplit1.element.(ui.HorizontalSplitUnresizeable).children) - 6 {
			s := i & 1 == 1 ? "Long" : "Long2"

			label := ui.new_label(nil, s, .Middle, .Left)
			button := ui.new_button(nil)
			(&button.element.(ui.Button)).text = s
			sCopy := new(string)
			sCopy^ = s
			ui.button_set_on_click(button, sCopy, proc(sCopy: rawptr) {
				s := (transmute(^string)sCopy)^
				fmt.println(s, "click")
			})
			button.preferResize = true
			size: i32 = 30
			button.minimumSize = size

			thing := ui.new_vertical_split_unresizeable_from_nodes(horizSplit1, {label, button})
			container := ui.new_container(horizSplit1, thing, {0,0,0,0})
			(&container.element.(ui.Container)).allowOuterBoxInput = true

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
		if i >= 0 && i <= 3 {
			(&container.element.(ui.Container)).allowOuterBoxInput = true
		}

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

	t := time.now()

	ui.scale_up_children(rootNode, rl.GetScreenWidth(), rl.GetScreenHeight())
	boxes[2].h = 100

	if debug do fmt.println("scale_up_children()         time:", time.since(t))

	state := ui.ui_state_default_values()
	platformProcs := ui.get_raylib_platform_procs()
	uiData := ui.init_ui_data(platformProcs)

	lastmousey: i32 = 0

	/*image := rl.LoadImage("image.jpg")
	texture := rl.LoadTextureFromImage(image)*/

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05

		rl.BeginDrawing()
		rl.ClearBackground({255, 0, 0, 255})
		//rl.DrawTexture(texture, 0, 0, {255,255,255,255})
		//rl.ClearBackground({50, 50, 50, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		totalTime := time.now()

		if rl.IsKeyPressed(.F5) {
			uiData.buttonShader = rl.LoadShader(nil, "ui/shaders/button.glsl") // FIXME: Use filepath join
			uiData.checkboxShader = rl.LoadShader(nil, "ui/shaders/checkbox.glsl")
			uiData.controllerOutlineShader = rl.LoadShader(nil, "ui/shaders/controller_outline.glsl")
		}

		if rl.IsKeyPressed(.Q) || rl.IsKeyPressed(.CAPS_LOCK) {
			break
		}

		inputs := ui.inputs_from_raylib()
		t = time.now()
		ui.handle_input(rootNode, &state, platformProcs, inputs)
		uiData.debug = debugCheckbox.element.(ui.Checkbox).checked
		debug = rootNode.element.(ui.HorizontalSplit).children[0].element.(ui.VerticalSplit).children[2].element.(ui.HorizontalSplitUnresizeable).children[0].element.(ui.Container).child.element.(ui.VerticalSplitUnresizeable).children[0].element.(ui.Checkbox).checked
		if debug do fmt.println("handle_input()             time:", time.since(t))

		t = time.now()
		ui.recompute_children_boxes(rootNode)
		if debug do fmt.println("recompute_children_boxes() time:", time.since(t))

		t = time.now()

		lastmousey = inputs.mouseY

		ui.correct_boxes(rootNode, false)
		if debug do fmt.println("correct_boxes(..., false)  time:", time.since(t))

		t = time.now()
		ui.draw(rootNode, &state, &uiData, rl.GetScreenHeight(), inputs, rl.GetFrameTime())
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
