shader_type canvas_item;
uniform sampler2D next_frame : filter_linear;
uniform float blend_amount = 0.0;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	COLOR = mix(texture(TEXTURE, UV), texture(next_frame, UV), blend_amount) * tint;
}
