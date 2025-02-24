package main

import "core:fmt"
import "core:math"
import "core:unicode/utf8"
import "core:strings"
import rl "vendor:raylib"

WIDTH :: 1280
HEIGHT :: 720

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "hello world")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	app: App

	TAU :: 6.28318530717958647692528676655900576839433879875021

	for i := 0; i < 100; i += 1 {
		app.textboxes[i] = {
			x = i32((math.sin(f32(i) / 100 * TAU) * 400) + 400),
			y = i32((math.cos(f32(i) / 100 * TAU) * 400) + 400),
			//y = 28 * i32(i),
			//x = 0, y = 28 * i32(i),
			width = 500, height = 28,
		}
	}

	/*x := "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
	for c in x {
		append(&app.textboxes[1].str, c)
	}*/

	font := rl.LoadFontEx("monospace.ttf", 28, nil, 0)

	for !rl.WindowShouldClose() {
		delta := rl.GetFrameTime()
		app_update(&app, delta, rl.GetCharPressed())

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		app_draw(&app, delta, &font, 28)

		rl.DrawFPS(0,0)

		rl.EndDrawing()
	}
}
