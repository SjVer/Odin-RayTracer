package raytracing

import "core:math/linalg"
import "core:math/rand"

Material :: struct {
	albedo:    Color,
	roughness: f32,
	metalic:   f32,
}

reflect_off_mat :: proc(ray: Ray, info: HitInfo) -> (new_ray: Ray) {
	random_point_in_unit_sphere :: proc() -> Vec3 {
		// NOTE: excludes 1, but that isn't a big deal?
		p := Vec3 {
			rand.float32_range(-1, 1),
			rand.float32_range(-1, 1),
			rand.float32_range(-1, 1),
		}

		if linalg.dot(p, p) < 1 do return p
		return random_point_in_unit_sphere()
	}

	new_ray.origin = point_at_ray(ray, info.t) + info.normal * 0.0001

    dir_offset := info.material.roughness * random_point_in_unit_sphere()
    new_ray.direction = linalg.reflect(ray.direction, info.normal + dir_offset)
    return new_ray
}
