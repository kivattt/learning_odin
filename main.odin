package main

import "core:fmt"
import rl "vendor:raylib"

WIDTH :: 1280
HEIGHT :: 720

main :: proc() {
	rl.InitWindow(WIDTH, HEIGHT, "hello world")
	defer rl.CloseWindow()

	app: App
	app.textboxes[0] = {
		position = {0,0},
		size = {500,100},
	}

	app.textboxes[1] = {
		position = {100,300},
		size = {500,100},
	}

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		draw_app(&app)
		rl.EndDrawing()
	}
}
