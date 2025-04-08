#version 330

uniform ivec4 box;
uniform int screen_height;
uniform vec4 color = vec4(1, 1, 1, 1);

void main() {
	gl_FragColor = color;
}
