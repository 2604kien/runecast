extends Resource
## Editable timings and palette shared by the production sequence and overlay.
@export var traversal_seconds := 0.90
@export var hit_seconds := 1.50
@export var shield_seconds := 0.35
@export var attack_seconds := 1.50
## Each cleared slot/hand card gets this interval; never shared by a batch.
@export var cleanup_seconds := 0.18
## Reshuffles and encounter transitions retain their own ordered interval.
@export var cards_seconds := 0.24
## Each arriving card fades fully in before the next arrival begins.
@export var draw_seconds := 0.40
@export var technique_seconds := 1.00
@export_range(0.0, 0.25) var technique_shrink := 0.12
@export_range(0.0, 1.0) var technique_brightness := 0.45
@export var terminal_seconds := 0.75
@export var reduced_seconds := 0.06
@export var spell_color := Color("79f4dc")
@export var damage_color := Color("ffc58a")
@export var shield_color := Color("8cddff")
@export var expiry_color := Color("cbb4eb")
