package main

App :: struct {
	textboxes: [2]TextBox,
}

draw_app :: proc(app: ^App) {
	for &textbox in app.textboxes {
		draw_textbox(&textbox)
	}
}
