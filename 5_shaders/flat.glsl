#version 330

uniform float time;

uniform float x;
uniform float y;
uniform float w;
uniform float h;
uniform int width;
uniform int height;

void main() {
	float realX = (gl_FragCoord.x - x) / w;
	float realY = ((height - gl_FragCoord.y) - y) / h;
	//float realY = (gl_FragCoord.y + y) / h;

	float tX = 0.5;
	float tY = 0.5;

	//float val = realX * realX + realY * realY;
	float val = realY;
	gl_FragColor = vec4(val, val, val, 1.0);

	//gl_FragColor = vec4((sin(float(gl_FragCoord.x) / 6) + 1) / float(2), 0.0, 0.0, 1.0);
	//gl_FragColor = vec4(realX / float(800), 0.0, 0.0, 1.0);
	//gl_FragColor = vec4(realX / w, 0.0, 0.0, 1.0);

	//gl_FragColor = vec4(gl_FragCoord.x / 1280, 0.0, 0.0, 1.0);

	//gl_FragColor = vec4((sin((float(gl_FragCoord.x) / 6) + time) + 1) / float(2), 0.0, 0.0, 1.0);
}
