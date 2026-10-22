shader_type canvas_item;
uniform float progress = 0.0;
uniform float strip_height = 16.0;
uniform float viewport_height = 600.0;

void fragment() {
	vec4 outgoing = texture(TEXTURE, UV);
	float row = mod(UV.y * viewport_height, strip_height);
	float edge = strip_height * (1.0 - progress);
	float coverage = 1.0 - smoothstep(edge - 0.5, edge + 0.5, row);
	if (progress <= 0.0) coverage = 1.0;
	if (progress >= 1.0) coverage = 0.0;
	COLOR = vec4(outgoing.rgb, outgoing.a * coverage);
}
