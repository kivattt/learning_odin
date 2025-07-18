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
		left, bottom, 0, 0,
		right, bottom, 1, 0,
		right, top, 1, 1,

		left, bottom, 0, 0,
		right, top, 1, 1,
		left, top, 0, 1,
	}

	quadVAO: u32
	quadVBO: u32

	gl.GenVertexArrays(1, &quadVAO)
	gl.GenBuffers(1, &quadVBO)

	gl.BindVertexArray(quadVAO)
	gl.BindBuffer(gl.ARRAY_BUFFER, quadVBO)
	gl.BufferData(gl.ARRAY_BUFFER, 4 * len(quadVertices), raw_data(quadVertices), gl.STATIC_DRAW)

	gl.EnableVertexAttribArray(0)
	//gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 8, 0)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 16, 0)

	gl.BindVertexArray(quadVAO)
	//gl.DrawArraysInstanced(gl.TRIANGLES, 0, i32(len(quadVertices) / 2), 1)
	gl.DrawArraysInstanced(gl.TRIANGLES, 0, i32(len(quadVertices) / 4), 1)
	gl.BindVertexArray(0)
}
