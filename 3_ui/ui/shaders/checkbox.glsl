#version 330

out vec4 fragColor;

uniform ivec4 rect; // x y w h
uniform vec4 color = vec4(1, 1, 1, 1);
uniform int screen_height;
uniform int pixels_rounded_in = 10;

uniform ivec2 dropshadow_offset; // x y
uniform vec4 dropshadow_color = vec4(0, 0, 0, 1);

uniform float checkmark_thickness = 0.8;

uniform int draw_checkmark = 0;

#define M_PI 3.1415926535897932384626433832795

// The MIT License
// Copyright © 2015 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org


// Signed distance to a 2D rounded box. Tutorials explaining
// how it works: 
//
// https://www.youtube.com/watch?v=62-pRVZuS5c
// https://www.youtube.com/watch?v=s5NGeUV2EyU
//
// See also generalization to other corner shapes here:
//
// https://www.shadertoy.com/view/4cG3R1
//
//
// List of some other 2D distances: https://www.shadertoy.com/playlist/MXdSRf
// and iquilezles.org/articles/distfunctions2d


// b.x = half width
// b.y = half height
// r.x = roundness top-right  
// r.y = roundness boottom-right
// r.z = roundness top-left
// r.w = roundness bottom-left
float sdRoundBox(in vec2 p, in vec2 b, in vec4 r) {
	r.xy = (p.x>0.0)?r.xy : r.zw;
	r.x  = (p.y>0.0)?r.x  : r.y;
	vec2 q = abs(p)-b+r.x;
	return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

float sdOrientedBox(in vec2 p, in vec2 a, in vec2 b, float th) {
	float l = length(b-a);
	vec2  d = (b-a)/l;
	vec2  q = (p-(a+b)*0.5);
		  q = mat2(d.x,-d.y,d.y,d.x)*q;
		  q = abs(q)-vec2(l,th)*0.5;
	return length(max(q,0.0)) + min(max(q.x,q.y),0.0);    
}

float straight_line(in ivec4 box, in vec2 a, in vec2 b) {
	float maxSize = float(min(box.z, box.w));
	vec2 p = (vec2(box.xy) - vec2(box.zw) / 2) / maxSize;

	float val = max(0, min(1, sdOrientedBox(p, a / 2, b / 2, checkmark_thickness / maxSize) * maxSize));
	return 1 - val * val;
}

float round_box(int x, int y, int w, int h, int pixels_rounded, float smoothness) {
	float maxSize = float(max(w, h));
	vec2 p = (vec2(x, y) - vec2(w, h) / 2) / maxSize;
	vec2 b = vec2(float(w), float(h)) / maxSize / 2;
	float val = sdRoundBox(p, b, vec4(float(pixels_rounded) / maxSize));

	float bruh = max(0, min(1, val * maxSize * smoothness));
	return 1 - bruh * bruh; // Anti-aliasing at the outer edges
}

float round_box(int x, int y, int w, int h, int pixels_rounded) {
	return round_box(x, y, w, h, pixels_rounded, 1.0);
}

// Disclaimer: this function was written by Github Copilot
vec4 blend(vec4 src, vec4 dst) {
	float outAlpha = src.a + dst.a * (1.0 - src.a);
	vec3 outColor = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / max(outAlpha, 1e-6);
	return vec4(outColor, outAlpha);
}

void main() {
	int x = int(gl_FragCoord.x / 2) - rect.x;
	int y = ((screen_height-1) - int(gl_FragCoord.y / 2)) - rect.y;
	int w = rect.z - 1;
	int h = rect.w - 1;

	// Cap the pixels_rounded_in value
	int pixels_rounded = int(min(min(w, h) / 2, pixels_rounded_in));

	float val = round_box(x, y, w, h, pixels_rounded);
	float dropshadow = round_box(x - dropshadow_offset.x, y - dropshadow_offset.y, w, h, pixels_rounded);
	val = max(0, min(1, val));
	dropshadow = max(0, min(1, dropshadow));
	dropshadow = dropshadow * dropshadow * dropshadow * dropshadow;
	vec4 theDropshadowColor = vec4(dropshadow_color.x, dropshadow_color.y, dropshadow_color.z, dropshadow * dropshadow_color.w);

	vec4 theColor = vec4(color.x, color.y, color.z, val * color.w);

	vec4 colorWithoutCheckmark = blend(theColor, theDropshadowColor);

	// Checkmark
	float scale = 1.1;
	vec2 pointA = scale * vec2(-0.6, 0.1);
	vec2 pointB = scale * vec2(-0.15, 0.5);
	vec2 pointC = scale * vec2(0.6, -0.5);

	vec2 diff = pointB - pointA;
	float angleBetweenAB = atan(diff.y / diff.x) / (M_PI/2);

	float checkmarkL = straight_line(ivec4(x, y, w, h), pointB, pointA);
	checkmarkL = max(0, min(1, checkmarkL));

	float maxSize = float(min(rect.z, rect.w));
	pointB = pointB - vec2(
		checkmark_thickness * cos(angleBetweenAB) / maxSize,
		checkmark_thickness * sin(angleBetweenAB) / maxSize
	);

	float checkmarkR = straight_line(ivec4(x, y, w, h), pointB, pointC);
	checkmarkR = max(0, min(1, checkmarkR));

	vec4 checkmarkLColor = vec4(1,1,1, checkmarkL);
	vec4 checkmarkRColor = vec4(1,1,1, checkmarkR);
	vec4 checkmarkColor = blend(checkmarkLColor, checkmarkRColor);

	checkmarkColor.a = draw_checkmark * checkmarkColor.a;

	fragColor = blend(checkmarkColor, colorWithoutCheckmark);
}
