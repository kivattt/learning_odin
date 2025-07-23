package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

Vertex :: struct {
    position: glm.vec2,
    texcoord: glm.vec2,
}

main :: proc() {
    glfw.Init()
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 1)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    window := glfw.CreateWindow(800, 600, "window", nil, nil)
    glfw.MakeContextCurrent(window)

    gl.load_up_to(4, 1, glfw.gl_set_proc_address)

    vertices := [?]Vertex {
        {position = {-0.5, 0.5}, texcoord = {0,0}},
        {position = {0.5, 0.5},  texcoord = {1,0}},
        {position = {0.5, -0.5}, texcoord = {1,1}},

        {position = {-0.5, 0.5},  texcoord = {0,0}},
        {position = {0.5, -0.5},  texcoord = {1,1}},
        {position = {-0.5, -0.5}, texcoord = {0,1}},
    }

    vbo: u32
    gl.GenBuffers(1, &vbo)

    vao: u32
    gl.GenVertexArrays(1, &vao)
    gl.BindVertexArray(vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), raw_data(&vertices), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, texcoord))

    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    image_width, image_height, image_channels: i32
    image_data := stbi.load("image.jpg", &image_width, &image_height, &image_channels, 4)

    texture: u32
    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, image_width, image_height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image_data)

    program, err := gl.load_shaders_file("vert.glsl", "frag.glsl")
    gl.UseProgram(program)
    gl.Uniform1i(gl.GetUniformLocation(program, "texture0"), 0)

    for !glfw.WindowShouldClose(window) {
        gl.ClearColor(0.1, 0.1, 0.1, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, texture)
        gl.UseProgram(program)
        gl.BindVertexArray(vao)
        gl.DrawArrays(gl.TRIANGLES, 0, i32(len(vertices)))

        glfw.PollEvents()
        glfw.SwapBuffers(window)
    }
}
