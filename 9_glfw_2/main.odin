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

VERTEX_SHADER_SOURCE :: #load("vertex.glsl", cstring)

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

	vertexShaderSource := VERTEX_SHADER_SOURCE
	vertexShaderSourceLength: i32 = len(VERTEX_SHADER_SOURCE)

	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)
	vertexShader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertexShader, 1, &vertexShaderSource, nil)
	gl.CompileShader(vertexShader)
	isCompiled: i32 = 0
	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &isCompiled)
	if isCompiled == 0 {
		maxLength: i32 = 0
		gl.GetShaderiv(vertexShader, gl.INFO_LOG_LENGTH, &maxLength)

		fmt.println("maxLength:", maxLength)
		//errorLog := make([dynamic]byte, maxLength)
		errorLog := make([]byte, maxLength)
		gl.GetShaderInfoLog(vertexShader, maxLength, &maxLength, &errorLog[0])
		fmt.println(string(errorLog))
		gl.DeleteShader(vertexShader)
		return
	}

	fmt.println("iscompiled:", isCompiled)
	fmt.println("vertexshadersourcelength:", vertexShaderSourceLength)

	id := gl.CreateProgram()
	gl.AttachShader(id, vertexShader)
	gl.LinkProgram(id)
	defer gl.DeleteShader(vertexShader)

	windowSize := gl.GetUniformLocation(id, "windowSize")
	gl.UseProgram(id)
	gl.Uniform2f(windowSize, f32(width), f32(height))

	t := time.now()
	for !glfw.WindowShouldClose(window) && running {
		glfw.PollEvents()
		draw()
		glfw.SwapBuffers(window)

		gl.Uniform2f(windowSize, f32(width), f32(height))

		//fmt.println(time.since(t))
		t = time.now()
	}
}

draw :: proc() {
	gl.ClearColor(0, 0.3, 0, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	draw_rect(0, 0, 50, 50, f32(width), f32(height))
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
