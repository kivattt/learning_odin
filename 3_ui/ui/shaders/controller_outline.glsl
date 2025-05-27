#version 330

out vec4 fragColor;

uniform vec2 dpi_scale;
uniform ivec4 rect; // x y w h
uniform vec4 color = vec4(1, 1, 1, 1);
uniform int screen_height;
uniform int pixels_rounded_in = 10;

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

float round_box2(int x, int y, int w, int h, int pixels_rounded, float smoothness) {
	float maxSize = float(min(w, h));
	vec2 p = (vec2(x, y) - vec2(w, h) / 2) / maxSize;
	vec2 b = vec2(float(w), float(h)) / maxSize / 2;
	float val = sdRoundBox(p, b, vec4(float(pixels_rounded) / maxSize));

	return val * maxSize;
}

void main() {
	int x = int(gl_FragCoord.x / dpi_scale.x) - rect.x;
	int y = ((screen_height-1) - int(gl_FragCoord.y / dpi_scale.y)) - rect.y;
	int w = rect.z - 1;
	int h = rect.w - 1;

	// Cap the pixels_rounded_in value
	int pixels_rounded = int(min(min(w, h) / 2, pixels_rounded_in));

	float outline = round_box2(x, y, w, h, pixels_rounded, 1.0);
	// Paste this into Desmos to see: 1 - (1.5x)^2
	// Keep in mind round_box2() probably has totally different output ranges compared to round_box()

	float thickness = 2.0;

	outline = outline/thickness;

	float strength = 1.4;
	outline = 1 - pow(strength*outline, 2.0*thickness);
	//outline = 1 - ((strength*outline) * (strength*outline));

	outline = max(0, min(1, outline));

	fragColor = vec4(color.r, color.g, color.b, outline * color.a);
}
