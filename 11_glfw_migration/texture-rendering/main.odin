package main

import "core:fmt"
import "vendor:stb/image"
import "core:time"
import "core:math"
import "core:strings"
import "core:c"
import gl "vendor:OpenGL"
import "vendor:glfw"

WIDTH :: 1280
HEIGHT :: 720
GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION:: 6

running: b32 = true
width: i32 = WIDTH
height: i32 = HEIGHT

main :: proc() {
	fmt.println("Loading fox.jpg...")
	x, y: i32 = 0, 0
	channels: i32 = 3
	foxImage := image.load("fox.jpg", &x, &y, &channels, 3)
	fmt.println("Finished loading fox.jpg")

	glfw.WindowHint(glfw.RESIZABLE, 1)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR_VERSION)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR_VERSION)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	
	if glfw.Init() != true {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	window := glfw.CreateWindow(WIDTH, HEIGHT, "Odin GLFW + OpenGL", nil, nil)
	defer glfw.DestroyWindow(window)

	if window == nil {
		fmt.println("Unable to create window")
		return
	}

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1) // Enable VSYNC
	glfw.SetKeyCallback(window, key_callback)
	glfw.SetFramebufferSizeCallback(window, size_callback)

	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)

	vertices := []f32{
		-0.5, -0.5, 0.0, 0.0,
		 0.5, -0.5, 1.0, 0.0,
		 0.5,  0.5, 1.0, 1.0,
		-0.5,  0.5, 0.0, 1.0,
	}
	indices := []u32{ // ???
		0, 1, 2, 2, 3, 0
	}

	vao, vbo, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 4 * len(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, 4 * len(indices), &indices, gl.STATIC_DRAW)

	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * 4, uintptr(0))
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * 4, uintptr(2 * 4))
	gl.EnableVertexAttribArray(1)
	gl.BindVertexArray(0)

	texture: u32
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, x, y, 0, gl.RGB, gl.UNSIGNED_BYTE, foxImage)
	//gl.GenerateMipmap(gl.TEXTURE_2D)
	image.image_free(foxImage)

	t := time.now()
	for !glfw.WindowShouldClose(window) && running {
		glfw.PollEvents()

		gl.ClearColor(0.6313725490196078, 0.6039215686274509, 0.43137254901960786, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.BindTexture(gl.TEXTURE_2D, texture)
		gl.BindVertexArray(vao)
		//gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, uintptr(0))

		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, &vbo)

		glfw.SwapBuffers(window)

		//fmt.println(time.since(t))
		t = time.now()
	}
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if key == glfw.KEY_ESCAPE || key == glfw.KEY_CAPS_LOCK || key == glfw.KEY_Q {
		running = false
	}
}

size_callback :: proc "c" (window: glfw.WindowHandle, w, h: i32) {
	gl.Viewport(0, 0, w, h)
	width = w
	height = h
}
