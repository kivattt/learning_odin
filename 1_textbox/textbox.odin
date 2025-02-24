package main

import "core:strings"
import rl "vendor:raylib"

TextBox :: struct {
	stringBuilder: strings.Builder,
	x: i32,
	y: i32,
	width: i32,
	height: i32,
}

draw_textbox :: proc(t: ^TextBox, font: ^rl.Font, fontSize: f32) {
	//t.stringBuilder = strings.builder_from_bytes({'h', 'e', 'l', 'l', 'o'})

	rl.DrawRectangle(t.x, t.y, t.width, t.height, {30,30,30,255})
	//rl.DrawTextEx(font^, strings.to_cstring(&t.stringBuilder), {f32(t.x), f32(t.y)}, fontSize, 0, {255,255,255,255})
	//rl.DrawTextEx(font^, strings.to_cstring(&t^.stringBuilder), {f32(t.x), f32(t.y)}, fontSize, 0, {255,255,255,255})
	rl.DrawTextEx(font^, strings.to_cstring(&(t^).stringBuilder), {f32(t.x), f32(t.y)}, fontSize, 0, {255,255,255,255})
}
