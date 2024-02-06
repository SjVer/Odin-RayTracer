package raytracing

import "core:fmt"
import "core:log"
import "core:math/linalg"
import "core:math/rand"
import "core:math"
import "core:time"
import rl "vendor:raylib"

WINDOW_WIDTH :: 1000
WINDOW_HEIGHT :: 1000

RESOLUTION_SCALE :: 0.5
RESOLUTION_X :: WINDOW_WIDTH * RESOLUTION_SCALE
RESOLUTION_Y :: WINDOW_HEIGHT * RESOLUTION_SCALE

RENDER_ONLY_ONCE :: false
RANDOMIZED_SAMPLES :: true
SAMPLES_PER_PIXEL :: 4
ACCUMULATE_FRAMES :: true
MAX_FRAME_COUNT :: 100

SPHERES :: [?]Sphere {
	Sphere{{0, 0, 0}, 0.5},
	Sphere{{-1, 0, -1}, 1},
} 

// the meat of it all
ray_color :: proc(ray: Ray) -> Color {
	hit_anything := false
	closest_hit := HitInfo{t = math.F32_MAX}

	for sphere in SPHERES {
		if hit, info := ray_hit_sphere(sphere, ray, closest_hit.t); hit {
			closest_hit = info
			hit_anything = true
		}
	}

	if hit_anything {
		rgb := closest_hit.normal * 0.5 + 0.5
		return Color{rgb.r, rgb.g, rgb.b, 1}
	} 
	else {
		return {0, 0, 0, 1}
	}
}

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
accumulation : []Color

get_accumulated_color :: proc(x, y: i32, color: Color) -> Color {
	accumulation[x + y * RESOLUTION_X] += color

	accumulated_color := accumulation[x + y * RESOLUTION_X] 
	accumulated_color /= cast(f32)frame_count
	accumulated_color = clamp_color(accumulated_color)

	return accumulated_color
}

@(require)
render_image :: proc() {
	when ACCUMULATE_FRAMES {
		if MAX_FRAME_COUNT > 0 && frame_count > MAX_FRAME_COUNT {
			frame_count = 0
		} 
		if frame_count == 0 {
			delete(accumulation)
			accumulation = make([]Color, RESOLUTION_X * RESOLUTION_Y)
		}
		frame_count += 1
	}
	
	for y in 0 ..< cast(i32)RESOLUTION_Y {
		for x in 0 ..< cast(i32)RESOLUTION_X {
			// multi-sample the color
			color := Color{0, 0, 0, 0}
			for s in 0..<SAMPLES_PER_PIXEL {
				u := calc_uv_coord(auto_cast x, RESOLUTION_X)
				v := calc_uv_coord(auto_cast y, RESOLUTION_Y)
				
				ray := get_ray_from_camera(u, v)
				color += ray_color(ray)
			}
			color /= SAMPLES_PER_PIXEL

			// apply accumulation
			when ACCUMULATE_FRAMES {
				color = get_accumulated_color(x, y, color)
			}
	
			rl.DrawPixel(x, y, color_to_rl(color))
		}
	}
}

draw_text :: proc(y: i32, msg: string, args: ..any) {
	str := fmt.caprintf(msg, ..args)
	rl.DrawText(str, 10, 10 + 25 * y, 20, rl.WHITE)
	delete(str)
}

main :: proc() {
	context.logger = log.create_console_logger()

	rl.SetTraceLogLevel(.WARNING)
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "raytracing")
	defer rl.CloseWindow()
	rl.ClearWindowState({.WINDOW_RESIZABLE})
	
	target := rl.LoadRenderTexture(RESOLUTION_X, RESOLUTION_Y)
	defer rl.UnloadRenderTexture(target)

	duration: time.Duration
	first_frame := true
	for !rl.WindowShouldClose() {
		// render the image
		rl.BeginTextureMode(target)
		{
			if RENDER_ONLY_ONCE && first_frame || !RENDER_ONLY_ONCE {
				first_frame = false

				start := time.now()
				render_image()
				duration = time.since(start)
			}
		}
		rl.EndTextureMode()

		rl.BeginDrawing()
		{
			rl.ClearBackground(rl.BLACK)
			// render the final image to the window
			rl.DrawTexturePro(
				target.texture,
				{0, 0, RESOLUTION_X, RESOLUTION_Y},
				{0, 0, WINDOW_WIDTH, WINDOW_HEIGHT},
				{0, 0}, 0, rl.WHITE,
			)

			// draw fps counter
			draw_text(0, "resolution: %vx%v", RESOLUTION_X, RESOLUTION_Y)
			draw_text(1, "samples: %d per pixel (randomized: %v)", SAMPLES_PER_PIXEL, RANDOMIZED_SAMPLES)
			draw_text(2, "render time: %01.3fms", time.duration_milliseconds(duration))
			when ACCUMULATE_FRAMES do draw_text(3, "accumulated frames: %d", frame_count)
		}
		rl.EndDrawing()
	}
}
