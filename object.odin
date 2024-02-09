package raytracing

Sphere :: struct {
	center:   Vec3,
	radius:   f32,
	material: Material,
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

SPHERES := [?]Sphere{
	{
		center = {0.5, 0, 0}, 
		radius = 0.5,
		material = {
			albedo = {0.9, 0.9, 0.9},
			roughness = 0.1,
			metalic = 0,
			emission = 0,
		},
	}, 
	{
		center = {-0.5, 0, 0}, 
		radius = 0.3,
		material = {
			albedo = RED_ISH,
			roughness = 1,
			metalic = 0,
			emission = 0,
		},
	},
	{
		center = {0, -100.5, 0}, 
		radius = 100,
		material = {
			albedo = GREEN_ISH,
			roughness = 0.9,
			metalic = 0,
			emission = 0,
		},
	}, 
}
