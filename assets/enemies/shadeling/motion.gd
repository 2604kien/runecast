extends Resource
## Editable, presentation-only normalized curves. No gameplay callbacks.

@export_range(1.6, 2.4) var idle_seconds := 2.0
@export_range(0.25, 0.4) var attack_seconds := 0.32
@export_range(0.12, 0.22) var hit_seconds := 0.16
@export_range(0.4, 0.7) var defeat_seconds := 0.45
@export_range(0.0, 0.01) var idle_stretch := 0.004
@export var attack_contact := 0.28
@export var attack_recovery := 0.72
@export var attack_squash: Curve
@export var hit_pulse: Curve
@export var defeat_fade: Curve
