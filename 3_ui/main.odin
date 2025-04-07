package main

import rl "vendor:raylib"
import "ui"

WIDTH :: 1280
HEIGHT :: 720

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

	boxes := ui.get_me_some_debug_squares(3)
	button1 := ui.new_button()
	button2 := ui.new_button()
	button3 := ui.new_button()
	button4 := ui.new_button()
	//vert1 := ui.vertical_split_from_nodes({boxes[0], boxes[1], boxes[2], button1})
	vert1 := ui.vertical_split_from_nodes({button1, button2, button3, button4})

	rootNode := vert1

	rootNode.w = rl.GetScreenWidth()
	rootNode.h = rl.GetScreenHeight()
	ui.scale_up_children(rootNode)

	state := ui.ui_state_default_values()
	uiData := ui.init_ui_data()
	defer ui.deinit_ui_data(&uiData)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({255, 0, 0, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		ui.handle_input(rootNode, &state)
		ui.recompute_children_boxes(rootNode)
		ui.draw(rootNode, &state, &uiData, rl.GetScreenHeight())

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
