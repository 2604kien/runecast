shader_type canvas_item;
render_mode unshaded;

uniform vec3 tone = vec3(1.0);

float label_coverage(vec2 p, vec4 bounds) {
    vec2 start = smoothstep(bounds.xy - vec2(2.0), bounds.xy, p);
    vec2 finish = vec2(1.0) - smoothstep(bounds.zw, bounds.zw + vec2(2.0), p);
    return start.x * start.y * finish.x * finish.y;
}

void fragment() {
    vec4 painted = texture(TEXTURE, UV);
    vec2 p = UV * vec2(841.0, 1870.0);
    // A fixed, broad feathered clean-center composition reveals coherent
    // architecture when the actor changes pose or disappears. A silhouette-
    // shaped hole left a recognizable ghost of the neutral in the scenery.
    // The entire original actor, outline, shadow and intent are inside the
    // fully clean rectangle; outer architecture remains the approved atlas.
    vec2 outside_center = max(abs(p - vec2(425.0, 271.5)) - vec2(145.0, 177.5), vec2(0.0));
    float clean_center = 1.0 - smoothstep(0.0, 44.0, length(outside_center));
    float ui = label_coverage(p, vec4(376.0, 101.0, 460.0, 158.0));
    ui = max(ui, label_coverage(p, vec4(397.0, 412.0, 449.0, 432.0)));
    ui = max(ui, label_coverage(p, vec4(370.0, 432.0, 476.0, 457.0)));
    ui = max(ui, label_coverage(p, vec4(306.0, 455.0, 532.0, 492.0)));
    painted.a *= 1.0 - max(clean_center, ui);
    painted.rgb = clamp(painted.rgb * tone, vec3(0.0), vec3(1.0));
    COLOR = painted;
}
