package main

import "core:fmt"
import "core:time"
import "core:math"
import "core:strings"
import "core:c"
import gl "vendor:OpenGL"
import "vendor:stb/image"
import "vendor:glfw"

WIDTH :: 1280
HEIGHT :: 720
GL_MAJOR_VERSION: c.int : 4
GL_MINOR_VERSION:: 6

VERTEX_SHADER_SOURCE :: #load("vertex.glsl", cstring)
FRAGMENT_SHADER_SOURCE :: #load("fragment.glsl", cstring)

running: b32 = true
width: i32 = WIDTH
height: i32 = HEIGHT

main :: proc() {
	fmt.println("Loading fox.jpg...")
	x, y: i32 = 0, 0
	channels: i32 = 3
	foxImage := image.load("fox.jpg", &x, &y, &channels, 3)
	fmt.println("Finished loading fox.jpg")
	fmt.println("w,h:", x, y)

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

	// Vertex shader
	gl.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address)
	vertexShaderSource := VERTEX_SHADER_SOURCE
	vertexShaderSourceLength: i32 = len(VERTEX_SHADER_SOURCE)
	vertexShader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertexShader, 1, &vertexShaderSource, nil)
	gl.CompileShader(vertexShader)
	isCompiled: i32 = 0
	gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &isCompiled)
	if isCompiled == 0 {
		maxLength: i32 = 0
		gl.GetShaderiv(vertexShader, gl.INFO_LOG_LENGTH, &maxLength)

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

	// Fragment shader
	fragmentShaderSource := FRAGMENT_SHADER_SOURCE
	fragmentShaderSourceLength: i32 = len(FRAGMENT_SHADER_SOURCE)
	fragmentShader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragmentShader, 1, &fragmentShaderSource, nil)
	gl.CompileShader(fragmentShader)
	isCompiled = 0
	gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &isCompiled)
	if isCompiled == 0 {
		maxLength: i32 = 0
		gl.GetShaderiv(fragmentShader, gl.INFO_LOG_LENGTH, &maxLength)

		errorLog := make([]byte, maxLength)
		gl.GetShaderInfoLog(fragmentShader, maxLength, &maxLength, &errorLog[0])
		fmt.println(string(errorLog))
		gl.DeleteShader(fragmentShader)
		return
	}
	fmt.println("fragment iscompiled:", isCompiled)
	fmt.println("fragmentshadersourcelength:", fragmentShaderSourceLength)
	id = gl.CreateProgram()
	gl.AttachShader(id, fragmentShader)
	gl.LinkProgram(id)
	defer gl.DeleteShader(fragmentShader)
	//windowSize := gl.GetUniformLocation(id, "windowSize")
	//gl.Uniform2f(windowSize, f32(width), f32(height))
	gl.UseProgram(id)

	texture: u32
	gl.ActiveTexture(0)
	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB8, x, y, 0, gl.RGB, gl.UNSIGNED_BYTE, foxImage)
	gl.BindTexture(gl.TEXTURE_2D, 0)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	gl.Enable(gl.BLEND)
	image.image_free(foxImage)
	defer gl.DeleteTextures(1, &texture)

	textureLoc := gl.GetUniformLocation(fragmentShader, "u_Texture")
	gl.Uniform1i(textureLoc, 0)

	t := time.now()
	for !glfw.WindowShouldClose(window) && running {
		gl.Uniform2f(windowSize, f32(width), f32(height))

		glfw.PollEvents()
		draw(texture)
		glfw.SwapBuffers(window)

		//fmt.println(time.since(t))
		t = time.now()
	}
}

draw :: proc(texture: u32) {
	gl.ClearColor(0.6313725490196078, 0.6039215686274509, 0.43137254901960786, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.BindTexture(gl.TEXTURE_2D, texture)
	draw_rect(50, 50, 500, 500, f32(width), f32(height))
//	gl.BindTexture(gl.TEXTURE_2D, 0)
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
