#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "ui"
import "core:fmt"
import "core:math"

WIDTH :: 2000
HEIGHT :: 720

main :: proc() {
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
	ui.scale_up_children(rootNode)

	state: ui.UserInterfaceState

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		rl.ClearBackground({255, 0, 0, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		ui.recompute_children_boxes(rootNode)
		ui.handle_input(rootNode, &state)
		ui.draw(rootNode, &state)

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
