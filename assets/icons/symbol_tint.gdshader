shader_type canvas_item;

// 0: original palette, 1: luminance monochrome, 2: flat alpha silhouette.
// Mode 1 preserves the dark outline and bright interior from the source vectors.
uniform int appearance_mode : hint_range(0, 2) = 0;
uniform vec4 ink : source_color = vec4(1.0);
// Set a light paper tone with dark ink when monochrome is used on parchment.
uniform vec4 monochrome_paper : source_color = vec4(0.0, 0.0, 0.0, 1.0);
varying vec4 vertex_modulate;

void vertex() {
	vertex_modulate = COLOR;
}

void fragment() {
	vec4 sampled = texture(TEXTURE, UV);
	if (appearance_mode == 1) {
		float value = dot(sampled.rgb, vec3(0.2126, 0.7152, 0.0722));
		sampled.rgb = mix(monochrome_paper.rgb, ink.rgb, value);
	} else if (appearance_mode == 2) {
		sampled.rgb = ink.rgb;
	}
	COLOR = sampled * vertex_modulate * vec4(1.0, 1.0, 1.0, ink.a);
}
