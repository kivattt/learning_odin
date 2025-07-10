package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

draw_rect :: proc(x, y, w, h: i32, screenWidth, screenHeight: f32) {
	left := f32(x)
	right := f32(x + w)
	top := f32(y)
	bottom := f32(y + h)

	quadVertices := []f32{
		left, bottom,
		right, bottom,
		right, top,

		left, bottom,
		right, top,
		left, top,
	}

	quadVAO: u32
	quadVBO: u32

	gl.GenVertexArrays(1, &quadVAO)
	gl.GenBuffers(1, &quadVBO)

	gl.BindVertexArray(quadVAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, quadVBO)
	gl.BufferData(gl.ARRAY_BUFFER, 4 * len(quadVertices), raw_data(quadVertices), gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 8, 0)

	gl.BindVertexArray(quadVAO)
	gl.DrawArraysInstanced(gl.TRIANGLES, 0, i32(len(quadVertices) / 2), 1)
	gl.BindVertexArray(0)
}
