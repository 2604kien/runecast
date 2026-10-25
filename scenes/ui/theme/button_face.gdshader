shader_type canvas_item;
render_mode unshaded;

uniform sampler2D face_texture : source_color, filter_linear, repeat_disable;
uniform vec4 face_region = vec4(0.0, 0.0, 1.0, 1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 frame = texture(TEXTURE, UV);
	// The Continue face and inner bevel are cyan; its warm gold rim and
	// transparent silhouette remain the original, unmodified painted pixels.
	float cool = min(frame.g - frame.r, frame.b - frame.r);
	float face_mask = smoothstep(0.015, 0.08, cool);
	vec2 face_uv = clamp((UV - vec2(0.109375, 0.140625)) / vec2(0.78125, 0.71875), vec2(0.0), vec2(1.0));
	vec3 material_color = texture(face_texture, face_region.xy + face_uv * face_region.zw).rgb;
	// Retain the luminous bevel without changing the source material's hue.
	float bevel = smoothstep(0.72, 0.98, max(frame.g, frame.b));
	material_color = mix(material_color, min(vec3(1.0), material_color * 1.7), bevel * 0.65);
	COLOR = vertex_tint * vec4(mix(frame.rgb, material_color, face_mask), frame.a);
}
