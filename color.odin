package raytracing

import rl "vendor:raylib"

Color :: distinct [4]f32

color_to_rl :: proc(color: Color) -> rl.Color {
	return rl.ColorFromNormalized(auto_cast color)
}

clamp_color :: proc(color: Color) -> Color {
	return Color {
		clamp(color.r, 0, 1),
		clamp(color.g, 0, 1),
		clamp(color.b, 0, 1),
		clamp(color.a, 0, 1),
	}
}