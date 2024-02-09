package raytracing

import "core:math/linalg"
import "core:math/rand"
import "core:time"
import "core:slice"

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
accum_data: []Color
frame_data: []Color = make([]Color, RESOLUTION_X * RESOLUTION_Y)
frame_duration: time.Duration

get_accumulated_color :: proc(x, y: i32, color: Color) -> Color {
	accum_data[x + y * RESOLUTION_X] += color

	accumulated_color := accum_data[x + y * RESOLUTION_X]
	accumulated_color /= cast(f32)frame_count
	accumulated_color = clamp_color(accumulated_color)

	return accumulated_color
}

render_image :: proc() {
	if ACCUMULATE {
		if frame_count == 0 {
			delete(accum_data)
			accum_data = make([]Color, RESOLUTION_X * RESOLUTION_Y)
		}
        frame_count += 1
	}

	slice.fill(frame_data, BLACK)
    start_time := time.now()

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

			if VISUALIZE_BOUNCES {
				// remap it to a curve for better readability
				G :: MAX_SAMPLE_BOUNCES / 2
				color = WHITE - linalg.pow(WHITE - color, G)
			}

			// apply accum_data
			if ACCUMULATE {
				color = get_accumulated_color(x, y, color)
			}

			frame_data[x + RESOLUTION_X * y] = color
		}
	}

    frame_duration = time.since(start_time)   
}
