# Shadeling character pack — RC-014

Instantiate [character.tscn](character.tscn) under the arena's presentation node. Its root is the **foot position**. The full 512×512 pose starts at `(-256,-448)`; the common source foot is `(512,896)` on the 1024×1024 master. Position and uniformly scale the root in the consumer. Never independently crop or center the poses.

Shadeling is the boss for one designated map encounter. Preserve training fixtures; release placement and tuning belong to RC-025/RC-034/RC-036. Names, health, intent, damage and role labels belong to live UI; none is baked into the pack. The character scene is isolated from gameplay and has no combat/controller dependency. See the [source delivery](../../../source-assets/characters/shadeling/delivery.md) for artwork, rights, measured scale, bounds and actual preview evidence.

**October 12 owner feedback:** keep the current dodge-looking hit pose and record dodging as a possible future boss mechanic. The existing `hit` name, source/export and idle/attack/hit/defeat interface remain unchanged. This supersedes the earlier claim that the study clearly reads as impact recoil. No dodge state or behavior is implemented. RC-034 owns the possible mechanic; if adopted, RC-017 must provide distinct feedback for damage, dodge and zero-damage outcomes. See the [decision record](../../../docs/decisions.md#october-12-2026--preserve-shadeling-pose-and-consider-dodging).

```gdscript
var actor = load("res://assets/enemies/shadeling/character.tscn").instantiate()
arena.add_child(actor) # Wait for ready before invoking the visual API.
actor.position = enemy_foot
actor.scale = Vector2.ONE * texture_pixels_to_arena_pixels
actor.show_pose(&"neutral")
```

The retained r006 SVG uses an **841×1870** coordinate system. Its actor canvas is 384×384 at `(254,92)`, directly under the SVG root: runtime-to-composition scale `384/512 = 0.75`, foot `(446,428)`. The RC-014 arena crop is `Rect(0,60,841,450)`, so that foot becomes `(446,368)` in the crop. For a uniformly resized crop of width `W`, multiply both coordinates by `W/841` and use actor scale `0.75*W/841`. Transform the retained crypt through that same crop mapping. These coordinates do not describe a 720-wide source arena or the older 680×300 placeholder arena. The old `0.46` scale and 181-pixel height ceiling are superseded; use the final mapping in the source delivery for the revised artwork.

**October 12 framing correction:** the 360-wide arena specimen now follows the same proportional mapping as 720/450: viewport `360×193`, actor scale `0.75*360/841 = 0.3210463734`, foot `(446,368)*360/841 = (190.9156,157.5268)` and sprite canvas `164.3757×164.3757`. The rounded viewport height does not change the uniform art transform. The old separate r006 native layout—scale `0.3515625`, foot `(180,217.5)`, 180×180 canvas at `(90,60)`, previously shown in a `360×280` isolated specimen—is historical and superseded for the RC-014 arena comparison. This proportional crop does not establish full native-phone layout, touch/readability or physical-device acceptance.

## Scene and attachment contract

| Node / resource | Purpose |
| --- | --- |
| `Shadeling` | Stable foot origin; no automatic preview playback by default |
| `ContactShadow` | Optional separate vector ellipse; draw order −20; disabled by default |
| `PoseRoot` | Local study transforms around the foot; draw order 0 |
| `PoseRoot/FullPose` | One active whole-pose texture, draw order 0, linear filtering, repeat disabled |
| `PoseRoot/Head` | Current pose head attachment |
| `PoseRoot/BodyCenter` | Current pose body center attachment |
| `PoseRoot/AttackOrigin` | Current pose illustrative attack attachment, with no collision/damage meaning |
| `PoseRoot/LanternPivot` | Current pose lantern handle pivot |
| [attachments.tres](attachments.tres) | Editable per-pose points in 512×512 canvas coordinates; imported resource dependency |

Markers have explicit draw order 10 for editor/debug use and produce no normal artwork. Read positions through `get_attachment_position(&"head")`, `&"body_center"`, `&"attack_origin"`, `&"lantern_pivot"` or `&"foot"`. Results are character-root-local; pass `true` as the second argument for global coordinates. Points change with the current full pose and follow `PoseRoot` study transforms. They are illustrative attachment metadata, not a skeleton or independently animated part rig.

## Pose and feasibility API

| Method | Behavior |
| --- | --- |
| `show_pose(&"neutral" / &"attack" / &"hit")` | Static pose, restores identity visual transform and opacity; stops local playback |
| `sample_state(state, seconds, reduced_motion=false)` | Deterministic sample; stops playback and emits no completion signal |
| `play_state(state, reduced_motion=false)` | Starts the optional local study at time zero, replacing the previous study |
| `stop_preview()` | Stops on the current image without resetting it |
| `get_state()`, `get_pose()` | Current named study and active whole pose |
| `get_visual_sample()` | Detached timing/pose/transform/opacity values for inspection |
| `warm_poses()` | Explicitly retain all three whole-pose textures; optional array chooses a subset |
| `clear_pose_cache()` | Drop optional warm references; active Sprite2D texture remains |
| `get_retained_pose_names()` | Scene-owned active/warm set; not a device-memory measurement |

Invalid state/pose names and non-finite sample times are rejected without replacing the visible frame. Use API methods after the node is ready. The exported `autoplay_preview`, `reduced_motion` and `show_contact_shadow` options are applied on startup; `autoplay_preview` defaults to false. Toggle the optional shadow node's visibility directly after startup if required.

| Named state | Study duration | Treatment and endpoint |
| --- | --- | --- |
| `idle` | 2.40 s loop | Neutral with 0.4% vertical breathing about the foot; endpoint equals start |
| `attack` | 0.90 s | Short neutral anticipation, wide attack pose between 20–80% with up to 1.2% foot-rooted vertical squash, stable neutral endpoint |
| `hit` | 0.65 s | Retained side-lean pose for first 75%, small angular motion and opacity response, stable neutral endpoint; owner notes it reads as dodging |
| `defeat` | 1.25 s | Hit pose collapses to 65% vertical height with small foot-pivot rotation and fades to zero; stable hidden endpoint forever |

Reduced motion keeps `PoseRoot` at its identity transform: idle stays still; attack/hit use the same discrete pose choices with at most a 6% hit opacity dip; defeat only fades. It does not introduce alternate gameplay timing or damage. All study timing is editable in [character.gd](character.gd). This delivered code-based timeline is a feasibility preview, not an AnimationPlayer library or completed event integration.

`preview_state_finished(state_name)` is emitted once when local non-looping playback reaches its end. Deterministic sampling never emits it. It is only a preview notification. Explicit `show_pose()` or another state request can restore the actor after defeat; defeat itself never returns to idle.

## Texture residency and import

The scene loads only the selected full pose on demand. It contains no PNG `preload`, whole-pose texture external resource, part Sprite2D, or hidden parallel rig. Resources use Godot's shared cache, allowing separate instances to share the same active texture. Loading the next pose may briefly overlap the previous texture while the assignment changes; no claim is made about immediate GPU reclamation.

At uncompressed RGBA8 with no mipmaps, one 512² pose is **1 MiB**; all three explicitly warmed poses are **3 MiB**. Each additional retained full-canvas 512² part adds **1 MiB**. The nine optional neutral parts total **9 MiB**; keeping all three poses and all nine parts simultaneously would total **12 MiB**. This scene does not load any parts. The vector shadow adds no texture. These are decoded texture estimates, excluding engine buffers, object metadata, viewport targets and device-specific allocation.

Use lossless PNG import, no mipmaps, straight alpha and edge fixing; filtering/repeat are explicit scene settings. Keep `attachments.tres` with the scene. It is a resource, so this pack requires no new raw-JSON export filter. Masters, generation records and preview projects stay under excluded source/output/tools paths.

## RC-016 / RC-017 handoff

RC-016 must map this root into the final responsive arena and bind separate live intent/name/health/damage/BOSS controls using detached snapshots. Preserve the complete visual contract and designated-map-encounter boss role; Bell Keeper remains the proposed final guardian. Main-game integration has not occurred. Preserve `shadeling`, `training_shadeling` and current fixture values; RC-025/RC-034 own encounter/node/board and boss behavior, RC-036 route/economy/rewards, and RC-024A permanent-reward eligibility.

RC-017 must decide production timing and event-to-state sequencing, distinguish zero applied damage from a real hit, respect lethal retaliation suppression, stop obsolete visual writes on cancellation, support reduced motion/settings, and invoke the controller's completion exactly once. Its adapter owns cancellation tokens and late-callback protection. The local study does not implement `present(result, completed)`, mutate damage/HP, select intent, perform cleanup or unlock input. See [combat presentation](../../../docs/combat-presentation.md) before attaching it.

Focused behavioral checks live in [test_shadeling.gd](../../../tools/test_shadeling.gd), callable as `await load("res://test_shadeling.gd").new().run(get_tree())` when staged into the isolated preview project. The [original state report](../../../output/qa/rc-014/godot-render-results.json) remains historical evidence. The [fresh boss-role follow-up](../../../output/qa/rc-014/followup-boss-dodge/godot-render-results.json) again passes all 194 checks using the delivered textures and attachment resource; [359 focused checks](../../../output/qa/rc-014/followup-boss-dodge/validation-report.json) also pass. [Boss-context previews and reproduction](../../../source-assets/characters/shadeling/delivery.md#follow-up-audit--boss-role-and-retained-hit-pose) retain the same art, anchors, scale and values with a separate live BOSS label. The later [360 framing correction](../../../source-assets/characters/shadeling/delivery.md#360-wide-framing-correction) supersedes the separately framed native360 comparison while preserving those earlier results. Current previews use one proportional arena mapping at720/450/360. Technical success and the owner's limited pose-retention choice do not establish rights clearance, broader art approval, final production animation or physical-device acceptance.
