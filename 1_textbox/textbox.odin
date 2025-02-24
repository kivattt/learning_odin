#+feature dynamic-literals

package main

import "core:strings"
import "core:fmt"
import "core:time"
import rl "vendor:raylib"

TextBox :: struct {
	//stringBuilder: strings.Builder,
	str: [dynamic]rune,
	cursorIndex: int,
	cursorLastBlinkTime: time.Time,
	cursorBlink: bool,

	//selectionStart:
	//selectionEnd:

	x: i32,
	y: i32,
	width: i32,
	height: i32,
}

textbox_update :: proc(t: ^TextBox, deltaTime: f32, charPressed: rune) {
	if time.duration_milliseconds(time.since(t.cursorLastBlinkTime)) > 300 {
		t.cursorLastBlinkTime = time.now()
		t.cursorBlink = !t.cursorBlink
	}

	if charPressed != 0 {
		inject_at(&t.str, t.cursorIndex, charPressed)
		t.cursorIndex += 1
	}

	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) || rl.IsKeyPressedRepeat(rl.KeyboardKey.BACKSPACE) {
		if t.cursorIndex == 0 {
			return
		}

		t.cursorIndex -= 1
		ordered_remove(&t.str, t.cursorIndex)
	} else if rl.IsKeyPressed(rl.KeyboardKey.DELETE) || rl.IsKeyPressedRepeat(rl.KeyboardKey.DELETE) {
		if len(t.str) == 0 {
			return
		}

		if t.cursorIndex == len(t.str) {
			return
		}

		ordered_remove(&t.str, max(0, t.cursorIndex))
	} else if rl.IsKeyPressed(rl.KeyboardKey.LEFT) || rl.IsKeyPressedRepeat(rl.KeyboardKey.LEFT) {
		t.cursorIndex -= 1
		if t.cursorIndex < 0 {
			t.cursorIndex = 0
		}
	} else if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) || rl.IsKeyPressedRepeat(rl.KeyboardKey.RIGHT) {
		t.cursorIndex += 1
		if t.cursorIndex >= len(t.str) {
			t.cursorIndex = max(0, len(t.str))
		}
	} else if rl.IsKeyPressed(rl.KeyboardKey.HOME) || rl.IsKeyPressedRepeat(rl.KeyboardKey.HOME) {
		t.cursorIndex = 0
	} else if rl.IsKeyPressed(rl.KeyboardKey.END) || rl.IsKeyPressedRepeat(rl.KeyboardKey.END) {
		t.cursorIndex = len(t.str)
	}
}

textbox_draw :: proc(t: ^TextBox, font: ^rl.Font, fontSize: f32) {
	rl.DrawRectangle(t.x, t.y, t.width, t.height, {30,30,30,255})
	//rl.DrawTextEx(font^, fmt.ctprintf("%s", t.str), {f32(t.x), f32(t.y)}, fontSize, 0, {255,255,255,255})
	rl.DrawTextCodepoints(font^, raw_data(t.str[:]), i32(len(t.str)), {f32(t.x), f32(t.y)}, fontSize, 0, {255,255,255,255});

	fontFullSize := rl.MeasureTextEx(font^, "a", fontSize, 0)
	if !t.cursorBlink {
		heightDiff := fontSize * 0.1
		rl.DrawRectangle(t.x + i32(f32(t.cursorIndex)*fontFullSize[0]), t.y + i32(heightDiff/2), 2, i32(fontSize - heightDiff), {255,255,255,255})
	}
}
