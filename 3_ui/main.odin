#+feature dynamic-literals

package main

import rl "vendor:raylib"
import "ui"
import "core:fmt"
import "core:math"

WIDTH :: 1280
HEIGHT :: 720

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(WIDTH, HEIGHT, "ui test")
	defer rl.CloseWindow()
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()))

	rootNode: ui.Node
	rootNode.parent = nil
	//rootNode.element = ui.VerticalSplit{}
	rootNode.x = 0
	rootNode.y = 0
	rootNode.w = 100
	rootNode.h = 100

	nodes: [dynamic]^ui.Node
	for i: u8 = 0; i < 2; i += 1 {
		d := new(ui.Node)
		d.element = ui.DebugSquare{}
		d.relativeSize = 1
		ii: u8 = i * 20
		fmt.println(ii)
		#partial switch &e in d.element {
			case ui.DebugSquare:
				e.color = {ii, ii, ii, 255}
		}
		append(&nodes, d)
	}

	vertNode: ui.Node
	vertNode.parent = &rootNode
	rootNode.element = ui.vertical_split_from_nodes(nodes)^

	fmt.println("rootNode:", rootNode)

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		rl.ClearBackground({53, 53, 53, 255})

		rootNode.w = rl.GetScreenWidth()
		/*#partial switch &e in rootNode.element {
			case ui.VerticalSplit:
				e.children[0].relativeSize = abs(math.sin(i) * 1) + 1
		}*/
		ui.recompute_children_boxes(&rootNode)
		ui.draw(&rootNode)
		rl.EndDrawing()
	}
}
