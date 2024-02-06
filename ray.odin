package raytracing

import "core:log"
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
	t:      f32,
	normal: Vec3,
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

		if info.t <= t_max {
			hit = true
			position := point_at_ray(ray, info.t)
			info.normal = l.normalize(position - sphere.center)
			return
		}
	}
	return
}
