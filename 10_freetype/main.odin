package main

import freetype "odin-freetype"
import "core:fmt"
import "core:time"
import "core:os"
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
	ftLib: freetype.Library
	err := freetype.init_free_type(&ftLib)
	assert(err == .Ok)

	face: freetype.Face
	err = freetype.new_face(ftLib, "adwaita.ttf", 0, &face)
	assert(err == .Ok)

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
	i := 0
	for !glfw.WindowShouldClose(window) && running {
		if i == 1 {
			break
		}
		i += 1
		//fontHeight: u32 = 18 * 64
		fontHeight: u32 = 30 * 64
		dpi: u32 = 109.0
		err = freetype.set_char_size(face, 0, cast(freetype.F26Dot6)fontHeight, dpi, dpi)
		assert(err == .Ok)
		c: u64 = 97
		err = freetype.load_char(face, c, {.Bitmap_Metrics_Only})
		assert(err == .Ok)
		//err = freetype.render_glyph(face.glyph, .Normal)
		err = freetype.render_glyph(face.glyph, .Normal)
		assert(err == .Ok)
		fmt.println(face.glyph.bitmap)

		for y := 0; y < int(face.glyph.bitmap.rows); y += 1 {
			for x := 0; x < int(face.glyph.bitmap.width); x += 1 {
				os.write_byte(os.stdout, face.glyph.bitmap.buffer[y * int(face.glyph.bitmap.width) + x])
				//fmt.printf("%c", face.glyph.bitmap.buffer[y * int(face.glyph.bitmap.width) + x])
			}
		}

		/*for i := -5000; i < int(face.glyph.bitmap.width * face.glyph.bitmap.rows) + 5000; i += 1 {
			fmt.printf("%c", face.glyph.bitmap.buffer[i])
		}*/

		glfw.PollEvents()

		gl.ClearColor(0, 0.3, 0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

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
