package main

import rl "vendor:raylib"

App :: struct {
	textboxes: [2]TextBox,
}

draw_app :: proc(app: ^App, font: ^rl.Font, fontSize: f32) {
	for &textbox in app.textboxes {
		draw_textbox(&textbox, font, fontSize)
	}
}
