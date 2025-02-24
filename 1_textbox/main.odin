package main

import "core:fmt"
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


	strings.builder_init_none(&app.textboxes[1].stringBuilder)
	strings.write_byte(&app.textboxes[1].stringBuilder, 'a')
	font := rl.LoadFontEx("monospace.ttf", 60, nil, 0)


	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		draw_app(&app, &font, 60)
		rl.EndDrawing()
	}
}
