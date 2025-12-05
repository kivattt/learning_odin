package mylib

import "core:fmt"
import "core:math"
import "base:runtime"
import rl "vendor:raylib"

Player :: struct {
	x: f32,
	y: f32,
	direction: rl.Vector2, // {angle, speed}
	name: string,
}

Game :: struct {
	player: Player,
	time: u64,
}

@export
update :: proc(g: ^Game, delta: f32) {
	context = runtime.default_context()
//	fmt.println("Hello from Odin")

	g.player.x += math.cos(g.player.direction[0]) * g.player.direction[1]
	g.player.y += math.sin(g.player.direction[0]) * g.player.direction[1]

	g.player.direction[1] -= 0.01 * delta // TODO: Check ...
	g.player.direction[1] = max(0.0, g.player.direction[1])

	g.player.direction[0] += 0.01 * delta
}
