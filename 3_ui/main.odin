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
	for i: u8 = 0; i < 7; i += 1 {
		d := new(ui.Node)
		d.element = ui.DebugSquare{}
		d.relativeSize = 1

		#partial switch &e in d.element {
			case ui.DebugSquare:
				high: u8 = 80
				colorLol := u8(i*20)

				e.color = {colorLol, colorLol/2, colorLol, 255}
				/*if i == 0 {
					e.color = {high, 0, 0, 255}
				} else if i == 1 {
					e.color = {0, high, 0, 255}
				} else if i == 2 {
					e.color = {0, 0, high, 255}
				} else if i == 3 {
					e.color = {high, high, high, 255}
				} else i*/
		}
		append(&nodes, d)
	}

	//vertNode: ui.Node
	//vertNode.parent = &rootNode
	//rootNode.element = ui.vertical_split_from_nodes(nodes)^
	vertSplit1 := ui.vertical_split_from_nodes(nodes[:2])^
	vertSplit2 := ui.vertical_split_from_nodes(nodes[2:4])^
	vertSplit3 := ui.vertical_split_from_nodes(nodes[4:])^
	//vertSplit2 := ui.horizontal_split_from_nodes(nodes[2:])^

	vertSplit2.relativeSize = 1
	vertSplit3.relativeSize = 2
	horizSplit := ui.horizontal_split_from_nodes({&vertSplit2, &vertSplit3})^

	vertSplitTwoOfThem := ui.vertical_split_from_nodes({&vertSplit1, &horizSplit})
	rootNode = vertSplitTwoOfThem^
	rootNode.x = 0
	rootNode.y = 0
	rootNode.w = 100
	rootNode.h = 100

	//rootNode.element = vertSplitTwoOfThem.element

	fmt.println("rootNode:", rootNode)

	i: f64 = 0
	for !rl.WindowShouldClose() {
		i += 0.05
		rl.BeginDrawing()
		rl.ClearBackground({53, 53, 53, 255})

		rootNode.w = rl.GetScreenWidth()
		rootNode.h = rl.GetScreenHeight()
		#partial switch &e in rootNode.element {
			case ui.VerticalSplit:
				e.children[0].relativeSize = 1 + (math.sin(i) + 1) / 2
		}

		#partial switch &e in rootNode.element {
			case ui.VerticalSplit:
				#partial switch &ee in e.children[1].element {
					case ui.HorizontalSplit:
						ee.children[0].relativeSize = 1 + (math.sin(i) + 1) / 2
				}
		}

		ui.recompute_children_boxes(&rootNode)
		ui.draw(&rootNode)
		rl.EndDrawing()
	}
}
