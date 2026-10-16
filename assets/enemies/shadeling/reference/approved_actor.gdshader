shader_type canvas_item;
render_mode unshaded;
#include "res://assets/enemies/shadeling/reference/approved_actor_mask.gdshaderinc"

void fragment() {
    COLOR.a *= approved_actor_coverage(UV * vec2(841.0, 1870.0));
}
