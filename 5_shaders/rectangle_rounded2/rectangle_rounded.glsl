#version 330

uniform ivec4 rect; // x y w h
uniform vec4 color = vec4(1, 1, 1, 1);
uniform int screen_height;
uniform int pixels_rounded_in = 10;

//uniform ivec4 dropshadow_rect; // x y w h
uniform ivec2 dropshadow_offset; // x y
uniform vec4 dropshadow_color = vec4(0, 0, 0, 1);
uniform float dropshadow_smoothness = 1.0;

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

float round_box(int x, int y, int w, int h, int pixels_rounded, float smoothness = 1.0) {
	float maxSize = float(max(w, h));
	vec2 p = (vec2(x, y) - vec2(w, h) / 2) / maxSize;
	vec2 b = vec2(float(w), float(h)) / maxSize / 2;
	float val = sdRoundBox(p, b, vec4(float(pixels_rounded) / maxSize));
	//return 1 - max(0, val * maxSize * smoothness); // Anti-aliasing at the outer edges

	float bruh = 1 - min(1, max(0, val * maxSize * smoothness));
	return bruh * bruh; // Anti-aliasing at the outer edges

	//float bruh = max(0, min(1, val * maxSize * smoothness));
	//return 1 - bruh * bruh; // Anti-aliasing at the outer edges
}

void main() {
	int x = int(gl_FragCoord.x) - rect.x;
	int y = ((screen_height-1) - int(gl_FragCoord.y)) - rect.y;
	int w = rect.z - 1;
	int h = rect.w - 1;

	// Cap the pixels_rounded_in value
	int pixels_rounded = int(min(min(w, h) / 2, pixels_rounded_in));

	float val = round_box(x, y, w, h, pixels_rounded);
	float dropshadow = round_box(x - dropshadow_offset.x, y - dropshadow_offset.y, w, h, pixels_rounded+1, 1.0 / dropshadow_smoothness);
	val = max(0, min(1, val));
	//dropshadow = 2*dropshadow - 1;
	dropshadow = max(0, min(1, dropshadow));
	//dropshadow = dropshadow * dropshadow;

	vec4 theColor = vec4(color.x, color.y, color.z, val * color.w);
	vec4 theDropshadowColor = vec4(dropshadow_color.x, dropshadow_color.y, dropshadow_color.z, dropshadow * dropshadow_color.w);

	gl_FragColor = theColor;

	//gl_FragColor = mix(theColor, theDropshadowColor, 1-val);
	//gl_FragColor = mix(theColor, theDropshadowColor, 1-val * theColor.a);
	//gl_FragColor = mix(theColor, theDropshadowColor, (1-val) * theColor.a);

	//gl_FragColor = mix(theColor, theDropshadowColor, dropshadow * dropshadow_color.w);

	//gl_FragColor = mix(theDropshadowColor, theColor, theColor.a);
}
