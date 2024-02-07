package raytracing

import "core:log"
import "core:math"
import l "core:math/linalg"

Vec3 :: l.Vector3f32

Ray :: struct {
	origin:    Vec3,
	direction: Vec3,
}

point_at_ray :: proc(ray: Ray, t: f32) -> Vec3 {
	return ray.origin + t * ray.direction
}

HitInfo :: struct {
	t:        f32,
	normal:   Vec3,
	material: Material,
}

ray_hit_sphere :: proc(
	sphere: Sphere,
	ray: Ray,
	t_max: f32,
) -> (
	hit := false,
	info: HitInfo,
) {
	Crel := ray.origin - sphere.center

	a := l.dot(ray.direction, ray.direction)
	b := 2 * l.dot(Crel, ray.direction)
	c := l.dot(Crel, Crel) - sphere.radius * sphere.radius
	d := b * b - 4 * a * c

	if d >= 0 {
		t1 := (-b - l.sqrt(d)) / (2 * a)
		t2 := (-b + l.sqrt(d)) / (2 * a)
		info.t = min(t1, t2)

		if 0 < info.t && info.t <= t_max {
			hit = true
			position := point_at_ray(ray, info.t)
			info.normal = l.normalize(position - sphere.center)
			info.material = sphere.material
			return
		}
	}
	return
}

// the meat of it all
ray_color :: proc(ray: Ray, depth := 0) -> Color {
	hit_anything := false
	closest_hit := HitInfo {
		t = math.F32_MAX,
	}

	for sphere in SPHERES {
		if hit, info := ray_hit_sphere(sphere, ray, closest_hit.t); hit {
			closest_hit = info
			hit_anything = true
		}
	}

	if hit_anything {
		color := closest_hit.material.albedo
		if depth == MAX_SAMPLE_BOUNCES do return color
		
		scattered_ray := reflect_off_mat(ray, closest_hit)
		scattered_color := color * ray_color(scattered_ray, depth + 1)
		return scattered_color
	} else {
		return BACKGROUND_COLOR
	}
}
