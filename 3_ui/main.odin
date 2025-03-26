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
	rootNode.x = 0
	rootNode.y = 0
	rootNode.w = 100
	rootNode.h = 100

	nodes: [dynamic]^ui.Node
	//for i: u8 = 0; i < 10; i += 1 {
	for i: u8 = 0; i < 109; i += 1 {
		d := new(ui.Node)
		d.element = ui.DebugSquare{}
		d.relativeSize = 1

		#partial switch &e in d.element {
			case ui.DebugSquare:
				high: u8 = 80
				colorLol := u8(i & 1 * 10 + 10)

				e.color = {colorLol, colorLol, colorLol, 255}
		}
		append(&nodes, d)
	}

	//vertSplit1 := ui.vertical_split_from_nodes(nodes[:2])
	vertSplit1 := ui.horizontal_split_from_nodes(nodes[:2])
	vertSplit2 := ui.vertical_split_from_nodes(nodes[2:4])
	vertSplit3 := ui.vertical_split_from_nodes(nodes[4:])

	horizSplit := ui.horizontal_split_from_nodes({vertSplit2, vertSplit3})
	thing1 := horizSplit.element.(ui.HorizontalSplit)
	thing1.children[0].relativeSize = 3
	thing1.children[1].relativeSize = 1

	vertSplitTwoOfThem := ui.vertical_split_from_nodes({vertSplit1, horizSplit})
	vertSplitTwoOfThem.parent = nil
	thing2 := vertSplitTwoOfThem.element.(ui.VerticalSplit)
	thing2.children[0].relativeSize = 1
	thing2.children[1].relativeSize = 3

	rootNode = vertSplitTwoOfThem^
	rootNode.x = 0
	rootNode.y = 0
	rootNode.w = 100
	rootNode.h = 100

	fmt.println("vertSplit1[0] n parents (should be 2.):", ui.n_parents(nodes[0]))

	fmt.println("rootNode:", rootNode)

	state: ui.UserInterfaceState

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		//rl.ClearBackground({53, 53, 53, 255})
		rl.ClearBackground({255, 0, 0, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()

		/*#partial switch &e in rootNode.element {
			case ui.VerticalSplit:
				e.children[0].relativeSize = 1 + (math.sin(i) + 1) / 2
		}

		#partial switch &e in rootNode.element {
			case ui.VerticalSplit:
				#partial switch &ee in e.children[1].element {
					case ui.HorizontalSplit:
						ee.children[0].relativeSize = 1 + (math.sin(i) + 1) / 2
				}
		}*/

		ui.recompute_children_boxes(&rootNode)
		ui.handle_input(&rootNode, &state)
		ui.draw(&rootNode, &state)

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}
}
