# Shared crypt — RC-015

Use `environment.tscn` as a presentation-only Node2D. Its origin is the top-left of both aligned **841 × 570** textures. `Background` is opaque and continues behind the entire transparent floor. Both Sprite2D children retain identity transforms, linear filtering and repeat disabled. No foreground layer is needed.

```gdscript
var crypt = preload("res://assets/environments/crypt/environment.tscn").instantiate()
presentation.add_child(crypt)
var k = comparison_width / 841.0
crypt.position = Vector2(0, -60) * k
crypt.scale = Vector2.ONE * k
crypt.set_lighting(&"warm_candle") # call after ready; returns false for unknown names

# Character and UI belong outside the environment's material scope.
var actor = preload("res://assets/enemies/shadeling/character.tscn").instantiate()
presentation.add_child(actor)
actor.position = Vector2(446, 368) * k
actor.scale = Vector2.ONE * 0.75 * k
```

The fixed lighting names are `base_cool`, `warm_candle`, and `dark`. Edit their per-channel RGB multipliers in `lighting.tres`, keeping [the JSON source settings](../../../source-assets/environments/crypt/lighting.json) in sync. The scene creates one ShaderMaterial instance shared by its two layers, so different scene instances can choose different presets. RGB is multiplied and clamped; straight alpha is unchanged. Base cool is the original indigo painting. No global CanvasModulate, autoload, duplicated background, extra biome, actor tint or UI tint is introduced. `get_layer_nodes()` exposes the two existing layer nodes for isolated diagnostics. Unknown names leave the current preset unchanged.

The default presentation crop is **Rect(0,60,841,450)**. At widths 720/450/360, the respective comparison viewports are **720 × 385, 450 × 241, 360 × 193**. Use one exact scale `k = width / 841`; rounding viewport height must not stretch the artwork. The unchanged RC-014 actor root is the foot, and the common source foot `(256,448)` maps to full composition `(446,428)` or crop-local `(446,368)`.

There is **zero horizontal overscan**, and 60 pixels of art above/below the default crop. Raw art supports 450-high crops with top Y0–120, shown separately in art-only previews. Only Y60 is validated here with the actor and live overlay fixtures. Alternate presentation crops, responsive full-screen placement, safe areas and live model binding belong to RC-016. Keep static layers together; do not rotate, offset independently or add parallax. Source master coordinates are twice export coordinates; source canvas is 1682 × 1140.

`tools/preview_environments.ps1` copies exact resources into an excluded disposable staging project, imports them with pinned Godot 4.7.2, and renders actual viewports. It does not change the main gameplay scene. PNG imports are lossless, straight alpha, no mipmaps and no size limit. Two full RGBA8 canvases cost **3,834,960 bytes / 3.6573 MiB** decoded; shaders/settings add no painted textures. These dimension estimates exclude GPU overhead, framebuffers and font atlases and are not device measurements.

See the [source delivery](../../../source-assets/environments/crypt/delivery.md), [metadata](../../../source-assets/environments/crypt/metadata.json) and [Godot render evidence](../../../output/qa/rc-015/godot-render-results.json). Shared crypt use does not make Shadeling an ordinary enemy or final guardian. RC-017 owns event-driven actor animation. Home remains a separate illustration with separate RC-013 wordmark and controls.
