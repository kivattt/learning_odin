package main

import "core:math"
import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

WIDTH :: 1280
HEIGHT :: 720

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(75)

	shader := rl.LoadShader(nil, "bruh.glsl")

	t: f32 = 0.0
	for !rl.WindowShouldClose() {
		rl.ClearBackground({0,0,255,255})

		width := rl.GetScreenWidth()
		height := rl.GetScreenHeight()

		rl.BeginShaderMode(shader)
		rl.DrawRectangle(0, 0, width, height, {0,0,0,0})
		rl.EndShaderMode()

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	rl.UnloadShader(shader)
}
