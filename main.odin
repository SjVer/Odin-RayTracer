package raytracing

import "core:fmt"
import "core:time"
import "core:log"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1000
WINDOW_HEIGHT :: 1000
GUI_SCALE :: 2

RESOLUTION_SCALE :: 1
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

main :: proc() {
	context.logger = log.create_console_logger()

	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raytracing")
	defer rl.CloseWindow()
	rl.ClearWindowState({.WINDOW_RESIZABLE})

	// setup gui
	// {
	// 	rl.GuiSetStyle(
	// 		auto_cast rl.GuiControl.DEFAULT,
	// 		auto_cast rl.GuiDefaultProperty.TEXT_SIZE,
	// 		20,
	// 	)
	// 	font := rl.LoadFontEx(
	// 		"C:\\Windows\\Fonts\\JetBrainsMonoNerdFont-Regular.ttf",
	// 		100, nil, 0
	// 	)
	// 	rl.GuiSetFont(font)
	// }

	image_target := rl.LoadRenderTexture(RESOLUTION_X, RESOLUTION_Y)
	defer rl.UnloadRenderTexture(image_target)

	duration: time.Duration
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
		if RENDER || RENDER_ONCE {
			rl.BeginTextureMode(image_target)
			{
				rl.ClearBackground({0, 0, 0, 0})
				RENDER_ONCE = false
				start := time.now()
				render_image()
				duration = time.since(start)
			}
			rl.EndTextureMode()
		}

		// render it all to the window
		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)

			rl.DrawTexturePro(
				image_target.texture,
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
					time.duration_milliseconds(duration),
				)
				if ACCUMULATE do draw_text(3, "accumulated frames: %d", frame_count)

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
}
