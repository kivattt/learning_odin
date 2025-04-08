package main

import "core:math"
import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

WIDTH :: 1280
HEIGHT :: 720

RL_TRIANGLES :: 0x0004

Box :: struct {
	x: i32,
	y: i32,
	w: i32,
	h: i32,
}

Color :: struct {
	r: f32,
	g: f32,
	b: f32,
	a: f32,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(75)

	shader := rl.LoadShader(nil, "roundish_rect.glsl")
	defer rl.UnloadShader(shader)

	x: i32 = 300
	y: i32 = 150
	w: i32 = 400
	h: i32 = 250

	boxLoc := rl.GetShaderLocation(shader, "box")
	screenHeightLoc := rl.GetShaderLocation(shader, "screen_height")
	colorLoc := rl.GetShaderLocation(shader, "color")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({0,80,100, 255})

		height: i32 = rl.GetScreenHeight()
		w = i32(f32(rl.GetScreenWidth()) / 1.5)
		h = i32(f32(rl.GetScreenHeight()) / 1.5)
		x = i32(f32(rl.GetScreenWidth() - w) / 2)
		y = i32(f32(rl.GetScreenHeight() - h) / 2)

		box := Box{
			x = x,
			y = y,
			w = w,
			h = h,
		}

		color := Color{1,1,1,1}

		//rl.DrawRectangle(x-1, y-1, w+2, h+2, {0,75,0,255})

		rl.SetShaderValue(shader, boxLoc, &box, .IVEC4)
		rl.SetShaderValue(shader, screenHeightLoc, &height, .INT)
		rl.SetShaderValue(shader, colorLoc, &color, .VEC4)

		rl.BeginShaderMode(shader)
		rl.DrawRectangle(x, y, w, h, {0,0,0,0})
		rl.EndShaderMode()

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

}
