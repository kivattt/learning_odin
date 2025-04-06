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

	boxes := ui.get_me_some_debug_squares(4)
	vert1 := ui.vertical_split_from_nodes(boxes)

	rootNode := vert1

	rootNode.w = rl.GetScreenWidth()
	rootNode.h = rl.GetScreenHeight()
	ui.scale_up_children(rootNode)

	state: ui.UserInterfaceState

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({255, 0, 0, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		ui.handle_input(rootNode, &state)
		if rl.IsKeyPressed(.F5) {
			ui.recompute_children_boxes(rootNode)
		}
		ui.draw(rootNode, &state)

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
