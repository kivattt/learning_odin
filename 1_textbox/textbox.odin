#+feature dynamic-literals

package main

import "core:strings"
import "core:unicode/utf8"
import "core:fmt"
import "core:time"
import "core:math/linalg"
import rl "vendor:raylib"

TEXT_FIELD_DELIMITERS :: " #@%/\\.?!§*-_:;\",&(){}[]"

//cursorLastBlinkTime: time.Time

TextBox :: struct {
	//stringBuilder: strings.Builder,
	str: [dynamic]rune,
	cursorIndex: int,
	cursorLastBlinkTime: time.Time,
	cursorBlink: bool,

	cursorPosX: f32,

	//selectionStart:
	//selectionEnd:

	x: i32,
	y: i32,
	width: i32,
	height: i32,
}

nextWordLeft :: proc(text: ^[dynamic]rune, index: int) -> int {
	nextPosition := 0
	inWord := false

	for i := 0; i < index; i += 1 {
		if strings.contains_rune(TEXT_FIELD_DELIMITERS, text[i]) {
			inWord = false
			continue
		}

		if !inWord {
			nextPosition = i
			inWord = true
		}
	}

	return nextPosition
}

nextWordRight :: proc(text: ^[dynamic]rune, index: int) -> int {
	nextPosition := len(text)
	inWord := false

	for i := len(text) - 1; i >= index; i -= 1 {
		if strings.contains_rune(TEXT_FIELD_DELIMITERS, text[i]) {
			inWord = false
			continue
		}

		if !inWord {
			nextPosition = i + 1
			inWord = true
		}
	}

	return nextPosition
}

is_key_pressed :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key) || rl.IsKeyPressedRepeat(key)
}

// Returns the new cursor position
delete_substring :: proc(str: ^[dynamic]rune, startIndex, endIndex: int) -> int {
	leftMostIndex := min(startIndex, endIndex)
	count := abs(startIndex - endIndex)

	left := str[:leftMostIndex]
	right := str[leftMostIndex+count:]
	clear(str)
	append(str, ..left)
	append(str, ..right)

	return leftMostIndex
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

	isCtrlDown := rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL)

	if is_key_pressed(.BACKSPACE) {
		if t.cursorIndex == 0 {
			return
		}
		if isCtrlDown {
			if len(t.str) != 0 {
				t.cursorIndex = delete_substring(&t.str, nextWordLeft(&t.str, t.cursorIndex), t.cursorIndex)
			}
		} else {
			t.cursorIndex -= 1
			ordered_remove(&t.str, t.cursorIndex)
		}
	} else if is_key_pressed(.DELETE) {
		if len(t.str) == 0 {
			return
		}

		if t.cursorIndex == len(t.str) {
			return
		}

		if isCtrlDown {
			if len(t.str) != 0 {
				t.cursorIndex = delete_substring(&t.str, t.cursorIndex, nextWordRight(&t.str, t.cursorIndex))
			}
		} else {
			ordered_remove(&t.str, max(0, t.cursorIndex))
		}
	} else if is_key_pressed(.W) && isCtrlDown {
		if len(t.str) != 0 {
			t.cursorIndex = delete_substring(&t.str, nextWordLeft(&t.str, t.cursorIndex), t.cursorIndex)
		}
	} else if is_key_pressed(.LEFT) {
		if isCtrlDown {
			t.cursorIndex = nextWordLeft(&t.str, t.cursorIndex)
		} else {
			t.cursorIndex -= 1
			if t.cursorIndex < 0 {
				t.cursorIndex = 0
			}
		}
	} else if is_key_pressed(.RIGHT) {
		if isCtrlDown {
			t.cursorIndex = nextWordRight(&t.str, t.cursorIndex)
		} else {
			t.cursorIndex += 1
			if t.cursorIndex >= len(t.str) {
				t.cursorIndex = max(0, len(t.str))
			}
		}
	} else if is_key_pressed(.HOME) {
		t.cursorIndex = 0
	} else if is_key_pressed(.END) {
		t.cursorIndex = len(t.str)
	} else if isCtrlDown && is_key_pressed(.V) {
		s := string(rl.GetClipboardText())
		s, _ = strings.remove_all(s, "\n")
		inject_at(&t.str, t.cursorIndex, ..utf8.string_to_runes(s, context.temp_allocator))
		t.cursorIndex += len(s)
	}
}

textbox_draw :: proc(t: ^TextBox, deltaTime: f32, font: ^rl.Font, fontSize: f32) {
	//rl.DrawRectangle(t.x, t.y, t.width, t.height, {30,30,30,255})
	rl.DrawTextCodepoints(font^, raw_data(t.str[:]), i32(len(t.str)), {f32(t.x), f32(t.y)}, fontSize, 0, rl.WHITE);

	fontFullSize := rl.MeasureTextEx(font^, "a", fontSize, 0)

	heightDiff := fontSize * 0.1
	target := f32(t.cursorIndex) * fontFullSize[0]
	if abs(t.cursorPosX - target) > 1 {
		t.cursorPosX = linalg.lerp(t.cursorPosX, target, deltaTime * 15)
	}

	if !t.cursorBlink {
		rl.DrawRectangle(t.x + i32(t.cursorPosX), t.y + i32(heightDiff/2), 2, i32(fontSize - heightDiff), rl.WHITE)
	} else {
		rl.DrawRectangle(t.x + i32(t.cursorPosX), t.y + i32(heightDiff/2), 2, i32(fontSize - heightDiff), {100,100,100,255})
	}
}
