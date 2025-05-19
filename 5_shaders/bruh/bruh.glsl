#version 330

out vec4 fragColor;

void main() {
	fragColor = vec4(gl_FragCoord.x / 255, gl_FragCoord.y / 255, 0, 1);
}
