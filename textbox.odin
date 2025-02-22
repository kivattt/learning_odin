package main

import "core:strings"
import rl "vendor:raylib"

TextBox :: struct {
	stringBuilder: strings.Builder,
	position: [2]i32,
	size: [2]i32,
}

draw_textbox :: proc(t: ^TextBox) {
	rl.DrawRectangle(t.position[0], t.position[1], t.size[0], t.size[1], {255,255,255,255})
}
