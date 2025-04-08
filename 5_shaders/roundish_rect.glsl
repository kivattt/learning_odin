#version 330

uniform ivec4 box;
uniform vec4 color = vec4(1, 1, 1, 1);
uniform int screen_height;

void main() {
	gl_FragColor = color;
}
