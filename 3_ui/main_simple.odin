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

	nBoxes := 4
	boxes := make([]^ui.Node, nBoxes)
	for i := 0; i < nBoxes; i += 1 {
		ds: ui.DebugSquare
		c: u8 = u8(i) * 20
		ds.color = {c, c, c, 255}

		node := new(ui.Node)
		node.element = ds
		node.w = 1
		boxes[i] = node
	}

	vert1 := ui.vertical_split_from_nodes(boxes[:3])
	vert1.element.(ui.VerticalSplit).children[0].preferNotResize = true
	vert1.element.(ui.VerticalSplit).children[0].w = 2
	vert1.element.(ui.VerticalSplit).children[nBoxes - 2].preferNotResize = true

	vert2 := ui.vertical_split_from_nodes(boxes[3:])

	rootNode := ui.vertical_split_from_nodes({vert1, vert2})

	rootNode.w = rl.GetScreenWidth()
	rootNode.h = rl.GetScreenHeight()

	t := time.now()
	ui.scale_up_children(rootNode)
	if debug do fmt.println("scale_up_children()         time:", time.since(t))

	state: ui.UserInterfaceState

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		rl.ClearBackground({255, 0, 0, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		t = time.now()
		ui.recompute_children_boxes(rootNode)
		if debug do fmt.println("recompute_children_boxes() time:", time.since(t))

		t = time.now()
		ui.handle_input(rootNode, &state)
		if debug do fmt.println("handle_input()             time:", time.since(t))

		t = time.now()
		ui.draw(rootNode, &state)
		if debug do fmt.println("draw()                     time:", time.since(t))

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
