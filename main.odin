package raytracing

import "core:fmt"
import "core:log"
import "core:thread"
import "core:time"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1000
WINDOW_HEIGHT :: 1000
GUI_SCALE :: 2

RESOLUTION_SCALE :: 4
RESOLUTION_X :: WINDOW_WIDTH / RESOLUTION_SCALE
RESOLUTION_Y :: WINDOW_HEIGHT / RESOLUTION_SCALE

RANDOMIZED_SAMPLES :: true
SAMPLES_PER_PIXEL :: 4
MAX_SAMPLE_BOUNCES :: 100

RENDER := true
RENDER_ONCE := false
ACCUMULATE := true
VISUALIZE_BOUNCES := false

draw_text :: proc(y: i32, msg: string, args: ..any) {
	str := fmt.caprintf(msg, ..args)
	start := y < 0 ? cast(i32)WINDOW_HEIGHT - 10 : 10
	rl.DrawText(str, 10, start + 25 * y, 20, rl.WHITE)
	delete(str)
}

render_texture: rl.RenderTexture2D
render_thread: ^thread.Thread = nil

copy_image_to_render_texture :: proc() {
	rl.BeginTextureMode(render_texture)

	for y in 0 ..< cast(i32)RESOLUTION_Y {
		for x in 0 ..< cast(i32)RESOLUTION_X {
			color := frame_data[x + RESOLUTION_X * y]
			rl.DrawPixel(x, y, color_to_rl(color))
		}
	}

	rl.EndTextureMode()
}

async_render_image :: proc() {
	if render_thread == nil && (RENDER || RENDER_ONCE) {
		render_thread = thread.create_and_start(render_image)
	}

	if thread.is_done(render_thread) {
		thread.join(render_thread)

		copy_image_to_render_texture()

		// start next render
		if RENDER || RENDER_ONCE {
			RENDER_ONCE = false

			thread.destroy(render_thread)
			render_thread = thread.create_and_start(render_image)
		}
	}
}

main :: proc() {
	context.logger = log.create_console_logger()
	rl.SetTraceLogLevel(.WARNING)
	rl.SetConfigFlags({.VSYNC_HINT})

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raytracing")
	rl.ClearWindowState({.WINDOW_RESIZABLE})
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	render_texture = rl.LoadRenderTexture(RESOLUTION_X, RESOLUTION_Y)
	defer rl.UnloadRenderTexture(render_texture)

	for !rl.WindowShouldClose() {
		// handle input
		if rl.IsKeyPressed(.B) {
			frame_count = 0
			VISUALIZE_BOUNCES = !VISUALIZE_BOUNCES
			RENDER_ONCE = true
		}
		if rl.IsKeyPressed(.SPACE) do RENDER = !RENDER
		if rl.IsKeyPressed(.ENTER) do RENDER_ONCE = true
		if rl.IsKeyPressed(.A) {
			ACCUMULATE = !ACCUMULATE
			frame_count = 0
		}

		// render the image
		async_render_image()

		// render it all to the window
		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			rl.DrawTexturePro(
				render_texture.texture,
				{0, 0, RESOLUTION_X, RESOLUTION_Y},
				{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT},
				{0, 0},
				0,
				rl.WHITE,
			)

			// render the gui
			{
				draw_text(0, "resolution: %vx%v", RESOLUTION_X, RESOLUTION_Y)
				draw_text(
					1,
					"samples: %d per pixel%s",
					SAMPLES_PER_PIXEL,
					RANDOMIZED_SAMPLES ? " (randomized)" : "",
				)
				draw_text(
					2,
					"render time: %01.3fms",
					time.duration_milliseconds(frame_duration),
				)
				if ACCUMULATE do draw_text(3, "accumulated frames: %d", frame_count - 1)

				draw_text(-4, "press [space] to toggle rendering")
				draw_text(-3, "press [enter] to render once")
				draw_text(-2, "press [A] to toggle accumulation")
				draw_text(-1, "press [B] to toggle bounce visualization")

				// // draw settings
				// rl.GuiCheckBox({10, 200, 10, 10}, "render", &render)
			}
		}
		rl.EndDrawing()
	}

	thread.terminate(render_thread, 0)
	thread.destroy(render_thread)
}
