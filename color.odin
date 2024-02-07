package raytracing

import rl "vendor:raylib"

Color :: distinct [3]f32

WHITE :: Color{1, 1, 1}
RED_ISH :: Color{1, 0.2, 0.2}
GREEN_ISH :: Color{0.2, 1, 0.2}
BLUE_ISH :: Color{0.2, 0.2, 1}
BLACK :: Color{0, 0, 0}
NO_COLOR :: Color{0, 0, 0}
BACKGROUND_COLOR :: Color{0.9, 0.9, 1}

color_to_rl :: proc(color: Color) -> rl.Color {
	return rl.ColorFromNormalized({color.r, color.g, color.b, 1})
}

clamp_color :: proc(color: Color) -> Color {
	return Color {
		clamp(color.r, 0, 1),
		clamp(color.g, 0, 1),
		clamp(color.b, 0, 1),
	}
}
