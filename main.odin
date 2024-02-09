package raytracing

import "core:fmt"
import "core:log"
import "core:math/linalg"
import "core:math/rand"
import "core:slice"
import "core:time"
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

calc_uv_coord :: proc(value: f32, res: f32) -> f32 {
	v := value
	when RANDOMIZED_SAMPLES {
		v += rand.float32_range(0, 1)
	}
	return v / res * 2 - 1
}

get_ray_from_camera :: proc(u, v: f32) -> Ray {
	ray := Ray{}
	ray.origin = Vec3{0, 0, 1}
	ray.direction = Vec3{u, v, -1}
	return ray
}

frame_count := 0
accumulation: []Color

get_accumulated_color :: proc(x, y: i32, color: Color) -> Color {
	accumulation[x + y * RESOLUTION_X] += color

	accumulated_color := accumulation[x + y * RESOLUTION_X]
	accumulated_color /= cast(f32)frame_count
	accumulated_color = clamp_color(accumulated_color)

	return accumulated_color
}

@(require)
render_image :: proc() {
	if ACCUMULATE {
		if frame_count == 0 {
			delete(accumulation)
			accumulation = make([]Color, RESOLUTION_X * RESOLUTION_Y)
		}
		frame_count += 1
	}

	for y in 0 ..< cast(i32)RESOLUTION_Y {
		for x in 0 ..< cast(i32)RESOLUTION_X {
			// multi-sample the color
			color := Color{0, 0, 0}
			for s in 0 ..< SAMPLES_PER_PIXEL {
				u := calc_uv_coord(auto_cast x, RESOLUTION_X)
				v := calc_uv_coord(auto_cast y, RESOLUTION_Y)

				ray := get_ray_from_camera(u, v)
				color += ray_color(ray)
			}
			color /= SAMPLES_PER_PIXEL

			// apply accumulation
			if ACCUMULATE {
				color = get_accumulated_color(x, y, color)
			}

			if VISUALIZE_BOUNCES {
				color =
					WHITE - linalg.pow(WHITE - color, MAX_SAMPLE_BOUNCES / 2)
			}

			rl.DrawPixel(x, y, color_to_rl(color))
		}
	}
}

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
