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

ray_trace :: proc(ray: Ray) -> (hit: bool, info: HitInfo) {
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

	return hit_anything, closest_hit
}

// the meat of it all
ray_color :: proc(ray: Ray, depth := 0) -> Color {
	did_hit, hit_info := ray_trace(ray)

	if !did_hit {
		if VISUALIZE_BOUNCES {
			return WHITE * cast(f32)depth / MAX_SAMPLE_BOUNCES
		}
		return BACKGROUND_COLOR
	}

	color := hit_info.material.albedo

	light := color

	if depth == MAX_SAMPLE_BOUNCES do return light
	
	scattered_ray := scatter_off_material(ray, hit_info)
	scattered_light := ray_color(scattered_ray, depth + 1)
	
	if VISUALIZE_BOUNCES {
		return scattered_light
	}
	return light * scattered_light
}