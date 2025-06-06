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

	shader := rl.LoadShader(nil, "rectangle_rounded.glsl")

	//color: Color = {0,0.213,0.22, 1}
	bruh: f32 = 0.33725490196078434
	color: Color = {bruh,bruh,bruh, 1}
	alpha: f32 = 0.5

	rectLoc := rl.GetShaderLocation(shader, "rect")
	screenHeightLoc := rl.GetShaderLocation(shader, "screen_height")
	colorLoc := rl.GetShaderLocation(shader, "color")
	pixelsRoundedLoc := rl.GetShaderLocation(shader, "pixels_rounded_in")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		//rl.ClearBackground({0,80,100, 255})
		rl.ClearBackground({36,36,36, 255})

		//x = rl.GetMouseX() - w/2
		//y = rl.GetMouseY() - h/2
		height: i32 = rl.GetScreenHeight()

		w := i32(f32(rl.GetScreenWidth()) / 1.5)
		h := i32(f32(rl.GetScreenHeight()) / 1.5)
		x := i32(f32(rl.GetScreenWidth() - w) / 2)
		y := i32(f32(rl.GetScreenHeight() - h) / 2)

		box := Box{
			x = x,
			y = y,
			w = w,
			h = h,
		}

		//pixelsRounded := i32(f32(rl.GetMouseY()) / f32(height) * f32(200))
		pixelsRounded := i32(7)
		//pixelsRounded: i32 = 10
		fmt.println(pixelsRounded)

		rl.SetShaderValue(shader, rectLoc, &box, .IVEC4)
		rl.SetShaderValue(shader, screenHeightLoc, &height, .INT)
		rl.SetShaderValue(shader, colorLoc, &color, .VEC4)
		rl.SetShaderValue(shader, pixelsRoundedLoc, &pixelsRounded, .INT)

		//rl.DrawRectangle(x-1, y-1, w+2, h+2, {255,0,0,255})

		rl.BeginShaderMode(shader)
		rl.DrawRectangle(x, y, w, h, {0,0,0,0})
		rl.EndShaderMode()

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	rl.UnloadShader(shader)
}
