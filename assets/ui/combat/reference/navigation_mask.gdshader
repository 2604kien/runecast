shader_type canvas_item;
render_mode unshaded;

// Source-space contours keep the original painted icon, including its dark
// edge, while removing the surrounding paint. Menu and Sound need separate
// contours so the slate between bars and sound waves remains transparent.
uniform vec2 vertices[96];
uniform ivec4 contour_ends = ivec4(0);
varying vec4 icon_modulate;

void vertex() {
    icon_modulate = COLOR;
}

float contour_coverage(vec2 p, int first, int end) {
    bool inside = false;
    float nearest = 10000.0;
    for (int i = 0; i < 96; i++) {
        if (i >= end) { break; }
        if (i < first) { continue; }
        int next = i + 1 < end ? i + 1 : first;
        vec2 a = vertices[i];
        vec2 b = vertices[next];
        vec2 edge = b - a;
        float along = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.0001), 0.0, 1.0);
        nearest = min(nearest, length(p - a - edge * along));
        if ((a.y > p.y) != (b.y > p.y)) {
            float crossing = a.x + (p.y - a.y) * (b.x - a.x) / (b.y - a.y);
            if (p.x < crossing) { inside = !inside; }
        }
    }
    return smoothstep(-0.55, 0.55, inside ? nearest : -nearest);
}

void fragment() {
    vec2 source = UV * vec2(841.0, 1870.0);
    float coverage = 0.0;
    int first = 0;
    for (int shape = 0; shape < 4; shape++) {
        int end = contour_ends[shape];
        if (end > first) {
            coverage = max(coverage, contour_coverage(source, first, end));
            first = end;
        }
    }
    vec4 painted = texture(TEXTURE, UV);
    painted.a *= coverage;
    COLOR = painted * icon_modulate;
}
