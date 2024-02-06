package raytracing

Sphere :: struct {
	center: Vec3,
	radius: f32,
}

// ray_hit_object :: proc(
// 	object: any,
// 	ray: Ray,
// 	t_max: f32,
// ) -> (
// 	hit: bool,
// 	info: HitInfo,
// ) {
// 	switch object in object {
// 		case Sphere:
// 			hit, info = ray_hit_sphere(object, ray, t_max)
// 		case:
// 			panic("invalid object type")
// 	}
// 	return
// }

// OBJECTS := [dynamic]any {
// 	Sphere{{0, 0, 0}, 0.5}
// }