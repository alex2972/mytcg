shader_type canvas_item;
uniform sampler2D rainbow_sheet : filter_linear, repeat_enable;
uniform vec2 crop_size;
uniform vec2 sheet_size;
uniform float offset_px = 0.0;
uniform float strength = 0.0;

void fragment() {
	vec2 sample_uv = vec2(
		UV.x * crop_size.x / sheet_size.x,
		(UV.y * crop_size.y + offset_px) / sheet_size.y
	);
	COLOR = texture(rainbow_sheet, sample_uv);
	COLOR.a *= strength;
}
