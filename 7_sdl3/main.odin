package main

import "core:fmt"
import sdl "vendor:sdl3"

main :: proc() {
	ok := sdl.Init({.VIDEO})
	if !ok {
		fmt.println("Failed to initialize SDL")
		return
	}

	window := sdl.CreateWindow("ui test", 1280, 720, {.RESIZABLE})
	if window == nil {
		fmt.println("Failed to create window")
		return
	}

	gpu := sdl.CreateGPUDevice({.SPIRV}, true, nil)
	if gpu == nil {
		fmt.println("Failed to create GPU device")
		return
	}

	ok = sdl.ClaimWindowForGPUDevice(gpu, window)
	if !ok {
		fmt.println("Failed to claim window for gpu")
		return
	}

	running := true

	for running {
		ev: sdl.Event
		for sdl.PollEvent(&ev) {
			#partial switch ev.type {
				case .QUIT:
					running = false
					break
			}
		}

		cmd_buf := sdl.AcquireGPUCommandBuffer(gpu)
		swapchain_tex: ^sdl.GPUTexture
		ok = sdl.WaitAndAcquireGPUSwapchainTexture(cmd_buf, window, &swapchain_tex, nil, nil)

		color_target := sdl.GPUColorTargetInfo{
			texture = swapchain_tex,
			load_op = .CLEAR,
			clear_color = {0, 0.2, 0.4, 1},
			store_op = .STORE,
		}

		render_pass := sdl.BeginGPURenderPass(cmd_buf, &color_target, 1, nil)
		sdl.EndGPURenderPass(render_pass)

		ok = sdl.SubmitGPUCommandBuffer(cmd_buf)
	}
}
