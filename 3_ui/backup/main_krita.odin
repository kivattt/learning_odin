#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "ui"
import "core:fmt"
import "core:math"
import "core:time"

WIDTH :: 2000
HEIGHT :: 720

main :: proc() {
	debug := false

	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

	//nBoxes := 7
	nBoxes := 8
	boxes := make([]^ui.Node, nBoxes)
	for i := 0; i < nBoxes; i += 1 {
		ds: ui.DebugSquare
		c: u8 = u8(i) * 20
		ds.color = {c, c, c, 255}

		node := new(ui.Node)
		node.element = ds
		node.w = 1
		node.h = 1
		boxes[i] = node
	}

//	horizSplit1 := ui.horizontal_split_from_nodes(boxes[2:])
//	horizSplit1 := ui.horizontal_split_from_nodes(boxes[3:])
	horizSplit1 := ui.horizontal_split_from_nodes(boxes[4:])
	horizSplit1.element.(ui.HorizontalSplit).children[0].preferNotResize = true
	horizSplit1.element.(ui.HorizontalSplit).children[2].preferNotResize = true
	horizSplit1.element.(ui.HorizontalSplit).children[3].preferNotResize = true
	vert1 := ui.vertical_split_from_nodes({boxes[0], boxes[1], horizSplit1})
	vert1.element.(ui.VerticalSplit).children[0].preferNotResize = true
	vert1.element.(ui.VerticalSplit).children[0].minimumSize = 74 // correct krita minsize

	vert1.element.(ui.VerticalSplit).children[2].preferNotResize = true
	vert1.element.(ui.VerticalSplit).children[2].minimumSize = 264

	//horizSplit2 := ui.horizontal_split_from_nodes({vert1, boxes[2]})
	horizSplit2 := ui.horizontal_split_from_nodes({vert1, ui.vertical_split_from_nodes(boxes[2:4])})
	boxes[2].preferNotResize = true

	//rootNode := vert1
	rootNode := horizSplit2

	rootNode.w = rl.GetScreenWidth()
	rootNode.h = rl.GetScreenHeight()

	t := time.now()

	ui.scale_up_children(rootNode)
	boxes[2].h = 100

	if debug do fmt.println("scale_up_children()         time:", time.since(t))

	state := ui.ui_state_default_values()

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		rl.ClearBackground({255, 0, 0, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		t = time.now()
		ui.handle_input(rootNode, &state)
		if debug do fmt.println("handle_input()             time:", time.since(t))

		t = time.now()
		if true || rl.IsKeyPressed(.F5) {
			ui.recompute_children_boxes(rootNode)
		}
		if debug do fmt.println("recompute_children_boxes() time:", time.since(t))

		t = time.now()
		ui.draw(rootNode, &state)
		if debug do fmt.println("draw()                     time:", time.since(t))

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
