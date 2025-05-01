## TODO
- Photoshop-style tool selection where only 1 button can be active at a time. Pseudocode below:
```go
// Since this struct is only a node pointer, maybe it shouldn't exist...
SingleSelectedGroup :: struct {
    selectedButton: ^Node,
}

Button :: struct {
    toggleable: bool, // When true, it's a toggle button, when false its a simple onclick button (like a close window button)
    toggled: bool, // Only used when toggleable = true ?
    singleSelectedGroup: ^SingleSelectedGroup,
}

button_on_click :: proc(node: ^Node) {
    button := node.element.(Button)

    if button.singleSelectedGroup == nil {
        if button.toggleable {
            button.toggled = !button.toggled
        }
        // normal behaviour
    } else {
        button.singleSelectedGroup.selectedButton = node
    }
}

button_draw :: proc(node: ^Node, ...) {
    button := node.element.(Button)

    isToggled := false

    if button.singleSelectedGroup == nil {
        if toggleable {
            isSelected = button.toggled
        }

        // normal behaviour
    } else {
        isSelected = button.singleSelectedGroup.selectedButton == node
    }

    if isToggled {
        color = colorSelectedHighlightedColorWhatever
    }

    // draw button with `color`
}
```

- (stupid) Change button gradient to a dithered gradient?

Debug menu ideas (bonus points: make it a separate window):
- Disable scissor draw limit
- Rootnode draw in middle (x+50, y+50, w-100, h-100 kinda thing)
- Resize bar draw dropdown setting [dont draw, transparent, normal]
- Middle click on any element to see its properties and edit them

<img src="screenshot.png" width="80%"></img>

The included [AdwaitaSans-Regular](ui/fonts/Adwaita/AdwaitaSans-Regular.ttf) font is licensed under the OFL-1.1. A copy of this license is included [here](ui/fonts/Adwaita/LICENSE).
