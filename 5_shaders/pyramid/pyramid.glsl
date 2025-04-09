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

	bool pyramid = true;

	if (pyramid) {
		float xx = gl_FragCoord.x - box.x;
		float yy = gl_FragCoord.y - box.y;
		float aspect = float(box.z) / float(box.w);

		bool aa = gl_FragCoord.y > midPointY ? true : false;
		bool bb = (!aa && xx/aspect < yy) ? true : false;
		bool cc = (!aa && !bb && (box.z/2 - (xx - box.z/2))/aspect < yy) ? true : false;
		if (aa || bb || cc) {
			angle /= 3;
		}
	}

	gl_FragColor = vec4(angle,angle,angle,1);
}
