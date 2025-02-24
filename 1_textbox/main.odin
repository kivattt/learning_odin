package main

import "core:fmt"
import "core:unicode/utf8"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 1280
HEIGHT :: 720

main :: proc() {
	rl.InitWindow(WIDTH, HEIGHT, "hello world")
	defer rl.CloseWindow()

	app: App
	app.textboxes[0] = {
		x = 0, y = 0,
		width = 500, height = 100,
	}

	app.textboxes[1] = {
		x = 100, y = 300,
		width = 500, height = 100,
	}

	/*x := "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
	for c in x {
		append(&app.textboxes[1].str, c)
	}*/

	font := rl.LoadFontEx("monospace.ttf", 60, nil, 0)

	for !rl.WindowShouldClose() {
		app_update(&app, rl.GetFrameTime(), rl.GetCharPressed())

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		app_draw(&app, &font, 60)

		rl.EndDrawing()
	}
}
