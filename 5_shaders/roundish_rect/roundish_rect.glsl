#version 330

uniform ivec4 box; // x y w h
uniform int screen_height;
uniform vec4 color = vec4(1, 1, 1, 1);

#define M_PI 3.1415926535897932384626433832795

void main() {
	int midPointX = box.x + box.z/2;
	int midPointY = box.y + box.w/2;

	float x = gl_FragCoord.x - midPointX;
	float y = gl_FragCoord.y - midPointY;

	float angle;
	if (gl_FragCoord.x > midPointX) {
		angle = ((atan(y / x) / (M_PI/2)) + 1) / 4;
	} else {
		angle = 0.5 + ((atan(y / x) / (M_PI/2)) + 1) / 4;
	}

	angle *= 2*M_PI;

	float maxDistance = box.z/2 * box.z/2 + box.w/2 * box.w/2;
	float distance = (x*x + y*y) / maxDistance;

	float wantedDistance = 0.1 + (sin(4*angle - M_PI/2) + 1)/100;

	float result = (distance - wantedDistance);
	float resultBorder = 1 - pow(800*result, 2);

	gl_FragColor = vec4(resultBorder, resultBorder, resultBorder, 1);
}
