shader_type canvas_item;
render_mode unshaded;

// Per-channel multipliers, deliberately not a source_color conversion.
// Alpha is unchanged and the same material is assigned to both aligned layers.
uniform vec3 tone = vec3(1.0);

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	COLOR = vec4(clamp(texel.rgb * tone, vec3(0.0), vec3(1.0)), texel.a);
}
