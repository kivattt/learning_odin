#version 330 core

layout (location = 0) in vec3 pos;

uniform vec2 windowSize;

void main() {
	float x = 2 * (pos.x / windowSize.x - 0.5);
	float y = 2 * ((windowSize.y - pos.y) / windowSize.y - 0.5);
	gl_Position = vec4(x, y, 0.0, 1.0);
}
