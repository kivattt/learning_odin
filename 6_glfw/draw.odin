package main

import gl "vendor:OpenGL"
import "vendor:glfw"

Color :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

draw_rectangle :: proc(x, y, w, h: i32, color: Color) {
	vertices := []f32{
		-0.5, -0.5, 0.0,
		0.5, -0.5, 0.0,
		0.0,  0.5, 0.0,
	}

	gl.DrawElements(gl.TRIANGLES, len(vertices), )
}
