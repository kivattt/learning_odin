#version 330

uniform ivec4 box;
uniform vec4 color = vec4(1, 1, 1, 1);
uniform int screen_height;
uniform int pixels_rounded_in = 10;

void main() {
	int x = box.x;
	int y = box.y;
	int w = box.z;
	int h = box.w;

	int realX = int(gl_FragCoord.x - x);
	int realY = int((screen_height - gl_FragCoord.y) - y);

	float val = 0;

	int pixels_rounded = min(min(w,h) / 2, pixels_rounded_in);

	// Straight lines
	if (realX == 0 || realX == w-1) {
		if (realY >= pixels_rounded && realY <= h-1-pixels_rounded) {
			val = 1;
		}
	} else if (realY == 0 || realY == h-1) {
		if (realX >= pixels_rounded && realX <= w-1-pixels_rounded) {
			val = 1;
		}
	}

	int maxDistance = 2 * pixels_rounded*pixels_rounded;
	float steepness = pixels_rounded;
	if (pixels_rounded < 6) {
		steepness = pixels_rounded * 1.5;
	}
	float theOffset = steepness / 2 - 1;

	bool corner = true;

	int relativeX = 0;
	int relativeY = 0;
	if (realX < pixels_rounded && realY < pixels_rounded ) { // Top-left corner
		relativeX = realX - pixels_rounded + 1;
		relativeY = realY - pixels_rounded + 1;
	} else if (realX >= w - pixels_rounded && realY < pixels_rounded) { // Top-right corner
		relativeX = realX - (w - pixels_rounded);
		relativeY = realY - pixels_rounded + 1;
	} else if (realX < pixels_rounded && realY >= h - pixels_rounded) { // Bottom-left corner
		relativeX = realX - pixels_rounded + 1;
		relativeY = realY - (h - pixels_rounded);
	} else if (realX >= w - pixels_rounded && realY >= h - pixels_rounded) { // Bottom-right corner
		relativeX = realX - (w - pixels_rounded);
		relativeY = realY - (h - pixels_rounded);
	} else {
		corner = false;
	}

	if (corner) {
		float distance = float(relativeX*relativeX + relativeY*relativeY) / maxDistance;
		val = 1 - (steepness * distance - theOffset) * (steepness * distance - theOffset);
	}


	gl_FragColor = vec4(color.x, color.y, color.z, val * color.w);
}
