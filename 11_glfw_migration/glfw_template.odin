package main

import "core:fmt"
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

	t := time.now()
	for !glfw.WindowShouldClose(window) && running {
		glfw.PollEvents()
		draw()
		glfw.SwapBuffers(window)

		//fmt.println(time.since(t))
		t = time.now()
	}
}

draw :: proc() {
	gl.ClearColor(0.6313725490196078, 0.6039215686274509, 0.43137254901960786, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)
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
