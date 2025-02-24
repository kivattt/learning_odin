package main

import rl "vendor:raylib"

App :: struct {
	textboxes: [2]TextBox,
}

app_draw :: proc(app: ^App, font: ^rl.Font, fontSize: f32) {
	for &textbox in app.textboxes {
		textbox_draw(&textbox, font, fontSize)
	}
}
