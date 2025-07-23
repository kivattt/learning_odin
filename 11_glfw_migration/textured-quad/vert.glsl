#version 410 core

layout(location = 0) in vec2 attr_pos;
layout(location = 1) in vec2 attr_texcoord;

out vec2 texcoord;

void main() {
    texcoord = attr_texcoord;
    gl_Position = vec4(attr_pos, 0.0, 1.0);
}
