package main

import "core:math"
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

	shader := rl.LoadShader(nil, "outline_rounded.glsl")

	x: i32 = 300
	y: i32 = 150
	w: i32 = 400
	h: i32 = 250
	color: Color = {0,1,1, 0.7}
	alpha: f32 = 0.5

	boxLoc := rl.GetShaderLocation(shader, "box")
	screenHeightLoc := rl.GetShaderLocation(shader, "screen_height")
	colorLoc := rl.GetShaderLocation(shader, "color")
	pixelsRoundedLoc := rl.GetShaderLocation(shader, "pixels_rounded_in")

	time: f32 = 0
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({0,0,0, 255})

		//x = rl.GetMouseX() - w/2
		//y = rl.GetMouseY() - h/2
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

		time += 0.1

		//pixelsRounded := i32(f32(rl.GetMouseY()) / f32(height) * f32(30))
		pixelsRounded := i32(f32(rl.GetMouseY()) / f32(height) * f32(200))
		//pixelsRounded := i32((math.sin(time) + 1) * 16)
		//pixelsRounded := 4 + i32((math.sin(time) + 1) * 4)

		//rl.DrawRectangle(x-1, y-1, w+2, h+2, {0,75,0,255})

		rl.SetShaderValue(shader, boxLoc, &box, .IVEC4)
		rl.SetShaderValue(shader, screenHeightLoc, &height, .INT)
		rl.SetShaderValue(shader, colorLoc, &color, .VEC4)
		rl.SetShaderValue(shader, pixelsRoundedLoc, &pixelsRounded, .INT)

		rl.BeginShaderMode(shader)
		rl.DrawRectangle(x, y, w, h, {0,0,0,0})
		rl.EndShaderMode()

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	rl.UnloadShader(shader)
}
