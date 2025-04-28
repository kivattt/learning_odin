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
	//bruh: f32 = 0.33725490196078434
	bruh: f32 = f32(47) / f32(255)
	color: Color = {bruh,bruh,bruh, 1}

	outlineColor: Color = {1, 1, 1, 0.05}

	//dropshadowColor: Color = {0, 0, 0, 1}
	dropshadowColor: Color = {0, 0, 0, 0.5}
	//dropshadowColor: Color = {0, 0, 0, 0.5}
	//dropshadowColor: Color = {0, 0, 0, 0}

	rectLoc := rl.GetShaderLocation(shader, "rect")
	screenHeightLoc := rl.GetShaderLocation(shader, "screen_height")
	screenWidthLoc := rl.GetShaderLocation(shader, "screen_width")
	colorLoc := rl.GetShaderLocation(shader, "color")
	outlineColorLoc := rl.GetShaderLocation(shader, "outline_color")
	pixelsRoundedLoc := rl.GetShaderLocation(shader, "pixels_rounded_in")
	dropshadowOffsetLoc := rl.GetShaderLocation(shader, "dropshadow_offset")
	dropshadowColorLoc := rl.GetShaderLocation(shader, "dropshadow_color")
	dropshadowSmoothnessLoc := rl.GetShaderLocation(shader, "dropshadow_smoothness")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		//rl.ClearBackground({0,80,100, 255})
		//rl.ClearBackground({36,36,36, 255})
		//rl.ClearBackground({48,48,48, 255})
		rl.ClearBackground({28,28,26, 255})
		//rl.ClearBackground({170,170,170, 255})

		//x = rl.GetMouseX() - w/2
		//y = rl.GetMouseY() - h/2
		height: i32 = rl.GetScreenHeight()
		width: i32 = rl.GetScreenWidth()

		/*w := i32(f32(rl.GetScreenWidth()) / 1.5)
		h := i32(f32(rl.GetScreenHeight()) / 1.5)
		x := i32(f32(rl.GetScreenWidth() - w) / 2)
		y := i32(f32(rl.GetScreenHeight() - h) / 2)*/

		x: i32 = 150
		y: i32 = 150
		w: i32 = 25
		h: i32 = 25

		box := Box{
			x = x,
			y = y,
			w = w,
			h = h,
		}

		dropshadowOffset := [2]i32{0, 0}
		dropshadowSmoothness: f32 = 5

		pixelsRounded := i32(3)
		//pixelsRounded := i32(rl.GetMouseY() / 4)

		fmt.println(pixelsRounded)

		rl.SetShaderValue(shader, rectLoc, &box, .IVEC4)
		rl.SetShaderValue(shader, screenHeightLoc, &height, .INT)
		rl.SetShaderValue(shader, screenWidthLoc, &width, .INT)
		rl.SetShaderValue(shader, colorLoc, &color, .VEC4)
		rl.SetShaderValue(shader, outlineColorLoc, &outlineColor, .VEC4)
		rl.SetShaderValue(shader, pixelsRoundedLoc, &pixelsRounded, .INT)
		rl.SetShaderValue(shader, dropshadowColorLoc, &dropshadowColor, .VEC4)
		rl.SetShaderValue(shader, dropshadowOffsetLoc, &dropshadowOffset, .IVEC2)
		rl.SetShaderValue(shader, dropshadowSmoothnessLoc, &dropshadowSmoothness, .FLOAT)

		rl.BeginShaderMode(shader)
		//rl.DrawRectangle(x, y, w, h, {0,0,0,0})
		rl.DrawRectangle(0, 0, width, height, {0,0,0,0})
		rl.EndShaderMode()

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	rl.UnloadShader(shader)
}
