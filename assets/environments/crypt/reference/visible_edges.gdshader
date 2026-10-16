shader_type canvas_item;
render_mode unshaded;
#include "res://assets/enemies/shadeling/reference/approved_actor_mask.gdshaderinc"

uniform vec3 tone = vec3(1.0);

float label_coverage(vec2 p, vec4 bounds) {
    vec2 start = smoothstep(bounds.xy - vec2(2.0), bounds.xy, p);
    vec2 finish = vec2(1.0) - smoothstep(bounds.zw, bounds.zw + vec2(2.0), p);
    return start.x * start.y * finish.x * finish.y;
}

void fragment() {
    vec4 painted = texture(TEXTURE, UV);
    vec2 p = UV * vec2(841.0, 1870.0);
    // Keep every visible architectural pixel outside the separate actor and
    // four small dynamic UI regions. The clean plate only fills those holes.
    float ui = label_coverage(p, vec4(376.0, 101.0, 460.0, 158.0));
    ui = max(ui, label_coverage(p, vec4(397.0, 412.0, 449.0, 432.0)));
    ui = max(ui, label_coverage(p, vec4(370.0, 432.0, 476.0, 457.0)));
    ui = max(ui, label_coverage(p, vec4(306.0, 455.0, 532.0, 492.0)));
    painted.a *= 1.0 - max(approved_actor_coverage(p), ui);
    painted.rgb = clamp(painted.rgb * tone, vec3(0.0), vec3(1.0));
    COLOR = painted;
}
