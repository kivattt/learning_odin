#version 330

uniform ivec4 rect; // x y w h
uniform vec4 color = vec4(1, 1, 1, 1);
uniform int screen_height;
uniform int pixels_rounded_in = 10;

float circle_distance(float maxDistance, vec2 point) {
	return (point.x*point.x + point.y*point.y) / maxDistance;
}

float bruh(float n) {
	//return 1 - pow(n + 0.4, 100);
	return pow(n + 0.4, 100);
}

void main() {
	// Cap the pixels_rounded value
	int pixels_rounded = min(min(rect.z, rect.w) / 2, pixels_rounded_in);

	int x = int(gl_FragCoord.x) - rect.x;
	int y = ((screen_height-1) - int(gl_FragCoord.y)) - rect.y;
	int w = rect.z;
	int h = rect.w;

	vec2 point = vec2(x, y);
	
	float maxDistance = 2 * pixels_rounded*pixels_rounded;
	vec4 distances = vec4(
		circle_distance(maxDistance, point - pixels_rounded + 1),                                          // Top left
		circle_distance(maxDistance, vec2(point.x - (w - pixels_rounded), point.y - pixels_rounded + 1)),  // Top right
		circle_distance(maxDistance, vec2(point.x - pixels_rounded + 1, point.y - (h - pixels_rounded))),  // Bottom left
		circle_distance(maxDistance, vec2(point.x - (w - pixels_rounded), point.y - (h - pixels_rounded))) // Bottom right
	);

	// TODO: Make left,right,top,bottom bools to simplify
	bvec4 whichCornerMask = bvec4(
		x <= pixels_rounded && y <= pixels_rounded,        // Top left
		x >= w - pixels_rounded && y <= pixels_rounded,    // Top right
		x <= pixels_rounded && y >= h - pixels_rounded,    // Bottom left
		x >= w - pixels_rounded && y >= h - pixels_rounded // Bottom right
	);
	//vec2 b2 = max(vec4(whichCornerMask).xy, vec4(whichCornerMask).zw);
	//bool isCorner = max(b2.x, b2.y) > 0;

	distances = distances * vec4(whichCornerMask);
	vec2 max2 = max(distances.xy, distances.zw);
	float distance = max(max2.x, max2.y);

	//bool within = distance > 0.5;

	//float within = pow(0.5 + distance, 10);
	//float val = 2 - (within);

	//float within = pow(20 * (distance - 0.5), 2);
	float within = pow(10 * (distance - 0.5), 2);
	if (distance < 0.5) {
		within = 0;
	} else {
		within = 0.5;
	}
	float val = 1 - (within);

	//float val = 1 - distance;
	//float val = 1 - bruh(distance);
	//float val = 1 - clamp(distance + 0.5, 0.0, 1.0);

	gl_FragColor = vec4(color.x, color.y, color.z, val * color.w);
}
