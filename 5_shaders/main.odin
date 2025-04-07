package main

import "core:math"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

WIDTH :: 1280
HEIGHT :: 720

RL_TRIANGLES :: 0x0004

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(75)

	shader := rl.LoadShader(nil, "flat.glsl")

	x: i32 = 300
	y: i32 = 150
	w: i32 = 400
	h: i32 = 250

	time: f32 = 0.0
	timeLoc := rl.GetShaderLocation(shader, "time")
	xLoc := rl.GetShaderLocation(shader, "x")
	yLoc := rl.GetShaderLocation(shader, "y")
	wLoc := rl.GetShaderLocation(shader, "w")
	hLoc := rl.GetShaderLocation(shader, "h")
	widthLoc := rl.GetShaderLocation(shader, "width")
	heightLoc := rl.GetShaderLocation(shader, "height")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({0,0,0, 255})

		time += 0.1
		if time > 6 {
			time = 0
		}

		//x = 100 + i32(math.sin(time) * 100)
		x = rl.GetMouseX() - w/2
		y = rl.GetMouseY() - h/2
		fx := f32(x)
		fy := f32(y)
		fw := f32(w)
		fh := f32(h)
		width: i32 = WIDTH
		height: i32 = HEIGHT

		rl.DrawRectangle(x-1, y-1, w+2, h+2, {255,255,255,255})

		rl.SetShaderValue(shader, timeLoc, &time, .FLOAT)
		rl.SetShaderValue(shader, xLoc, &fx, .FLOAT)
		rl.SetShaderValue(shader, yLoc, &fy, .FLOAT)
		rl.SetShaderValue(shader, wLoc, &fw, .FLOAT)
		rl.SetShaderValue(shader, hLoc, &fh, .FLOAT)
		rl.SetShaderValue(shader, widthLoc, &width, .INT)
		rl.SetShaderValue(shader, heightLoc, &height, .INT)

		rl.BeginShaderMode(shader)
		//rl.SetShaderValue(shader, timeLoc, &time, .FLOAT)

		rlgl.Begin(RL_TRIANGLES)
		//rlgl.Color4ub(0, 255, 0, 255)
		rlgl.Vertex2i(x, y)
		rlgl.Vertex2i(x, y+h)
		rlgl.Vertex2i(x+w, y)

		rlgl.Vertex2i(x+w, y)
		rlgl.Vertex2i(x, y+h)
		rlgl.Vertex2i(x+w, y+h)
		rlgl.End()

		rl.EndShaderMode()

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}

	rl.UnloadShader(shader)
}
