shader_type canvas_item;
render_mode unshaded;

uniform sampler2D ink_wear : filter_nearest, repeat_disable;
uniform float highlight : hint_range(0.0, 1.0) = 0.0;
uniform float wear_strength = 1.0;
varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	// Actual original ink wear has broad intact areas and occasional scrapes.
	// It is independent of wood brightness, so cleaner strokes stay intact.
	float worn_ink = texture(ink_wear, local_position / vec2(400.0, 44.0)).r;
	COLOR.a *= mix(1.0, worn_ink, wear_strength * (1.0 - highlight));
}
