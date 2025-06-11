package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

WIDTH :: 1280
HEIGHT :: 720

draw_sinc :: proc(x, y, screenWidth, screenHeight, mul: i32) -> []f64 {
	// -1 to 1

	//mulCopy := mul
	//mulCopy := f64(mul) / f64(math.PI)
	mulCopy := f64(mul) / 3.9

	ret := make([]f64, screenWidth)

	for dx: i32 = 0; dx < screenWidth; dx += 1 {
		t := f64(dx) / f64(screenWidth) * f64(2) - 1
		t -= f64(x) / f64(screenWidth) * 2 - 1
		//t -= f64(x) / f64(mulCopy) / f64(screenWidth)
		theY := math.sin(math.PI * f64(mulCopy) * t) / (math.PI * f64(mulCopy) * t) // sinc function
		theY *= ((f64(y) / f64(screenHeight)) - 0.5) * 2

		//theY *= 13
		theY *= 2
		//theY *= -1

		theY = (theY + 1) / 2 * f64(screenHeight)
		//theY += f64(y) - f64(screenHeight) / 2

		//theY -= (f64(y) - f64(screenHeight) / 2) / (f64(screenHeight)/2)

		ret[dx] = theY
		rl.DrawRectangle(dx, i32(theY), 1, 1, {255,0,0,255})
	}

	return ret
}

draw_list :: proc(list: []f64, l: i32) {
	for sample, x in list {
		theY := ((sample / f64(l)))

		rl.DrawRectangle(i32(x), i32(f64(theY)), 1, 1, {255,0,0,255})
		//rl.DrawRectangle(i32(x), i32(f64(sample) / f64(l)), 1, 1, {255,0,0,255})
		//rl.DrawRectangle(x, i32(f64(sample)), 1, 1, {255,0,0,255})
	}
}

main :: proc() {
	samples := []f64{0, 0, 0, -0.1, -0.25, -0.3, -0.3, -0.25, -0.1, 0, 0.1, 0.4, 0.9, 0.4, 0.2, 0.1, 0.1, 0, 0, 0, 1, 0, 0, 0}
	fmt.println(len(samples))
	fmt.println(samples)

	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "sinc")
	defer rl.CloseWindow()
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

	j := 0
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({0,0,0,0})

		screenWidth := rl.GetScreenWidth()
		screenHeight := rl.GetScreenHeight()

		res := make([]f64, screenWidth)
		//res: [WIDTH]f64

		x: f32 = 0
		lastY: i32
		lastX: i32
		i := 0
		for s in samples {
			y := f64(-s + f64(1)) / f64(2) * f64(screenHeight)
			rl.DrawRectangle(i32(x), i32(y), 5, 5, {0,255,0,255})

			if false || i == ((j / 8) % len(samples)) {
				add := draw_sinc(i32(x), i32(y), screenWidth, screenHeight, i32(len(samples)))
				for sample, i in add {
					res[i] += sample
				}
			}

			if i != 0 {
				rl.DrawLine(lastX, lastY, i32(x), i32(y), {0,255,0,100})
			}
			i += 1

			lastY = i32(y)
			lastX = i32(x)
			x += f32(screenWidth) / f32(len(samples))
		}
		rl.EndDrawing()

		//draw_list(res[:], i32(len(samples)))
		delete(res)

		j += 1
	}
}
