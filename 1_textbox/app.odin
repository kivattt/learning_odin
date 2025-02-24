package main

import rl "vendor:raylib"

App :: struct {
	textboxes: [100]TextBox,
}

app_update :: proc(app: ^App, deltaTime: f32, charPressed: rune) {
	for &textbox in app.textboxes {
		textbox_update(&textbox, deltaTime, charPressed)
	}
}

app_draw :: proc(app: ^App, deltaTime: f32, font: ^rl.Font, fontSize: f32) {
	for &textbox in app.textboxes {
		textbox_draw(&textbox, deltaTime, font, fontSize)
	}
}
