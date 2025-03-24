package main

import rl "vendor:raylib"

WIDTH :: 1280
HEIGHT :: 720

Spreadsheet :: struct {
	data: map[string]string,
}

init_spreadsheet :: proc(s: ^Spreadsheet) {
	s.data = make(map[string]string)
}

delete_spreadsheet :: proc(s: ^Spreadsheet) {
	delete(s.data)
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "hello")
	defer rl.CloseWindow()
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

	s: Spreadsheet
	init_spreadsheet(&s)
	defer delete_spreadsheet(&s)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground({53, 53, 53, 255})
		rl.EndDrawing()
	}
}
