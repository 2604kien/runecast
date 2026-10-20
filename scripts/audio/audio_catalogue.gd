extends RefCounted
## Shipped RC-018 r003 / RC-019 resource catalogue. Documentation JSON is
## intentionally excluded from exports. All-resources export presets package
## these imported runtime assets; the scene owner loads and releases its cache.
## Pending music has no loadable path and is never passed to ResourceLoader.

const SFX := {
	"ui_confirm": {"runtime_path": "res://assets/audio/sfx/sfx_ui_confirm/ui_confirm.wav", "gain_db": -8.0, "priority": 20, "future_only": false, "manifest_id": "sfx_ui_confirm"},
	"ui_back": {"runtime_path": "res://assets/audio/sfx/sfx_ui_back/ui_back.wav", "gain_db": -8.0, "priority": 20, "future_only": false, "manifest_id": "sfx_ui_back"},
	"edit_place": {"runtime_path": "res://assets/audio/sfx/sfx_place/edit_place.wav", "gain_db": -6.0, "priority": 25, "future_only": false, "manifest_id": "sfx_place"},
	"edit_orient": {"runtime_path": "res://assets/audio/sfx/sfx_rotate/edit_orient.wav", "gain_db": -6.0, "priority": 25, "future_only": false, "manifest_id": "sfx_rotate"},
	"edit_restore": {"runtime_path": "res://assets/audio/sfx/sfx_undo/edit_restore.wav", "gain_db": -6.0, "priority": 25, "future_only": false, "manifest_id": "sfx_undo"},
	"action_rejected": {"runtime_path": "res://assets/audio/sfx/sfx_invalid/action_rejected.wav", "gain_db": -10.0, "priority": 15, "future_only": false, "manifest_id": "sfx_invalid"},
	"technique_draw": {"runtime_path": "res://assets/audio/sfx/sfx_technique/technique_draw.wav", "gain_db": -5.0, "priority": 60, "future_only": false, "manifest_id": "sfx_technique"},
	"technique_conjure": {"runtime_path": "res://assets/audio/sfx/sfx_technique/technique_conjure.wav", "gain_db": -5.0, "priority": 60, "future_only": false, "manifest_id": "sfx_technique"},
	"cast": {"runtime_path": "res://assets/audio/sfx/sfx_cast/cast.wav", "gain_db": -3.0, "priority": 70, "future_only": false, "manifest_id": "sfx_cast"},
	"damage": {"runtime_path": "res://assets/audio/sfx/sfx_impact/damage.wav", "gain_db": -2.0, "priority": 80, "future_only": false, "manifest_id": "sfx_impact"},
	"shield": {"runtime_path": "res://assets/audio/sfx/sfx_shield/shield.wav", "gain_db": -4.0, "priority": 75, "future_only": false, "manifest_id": "sfx_shield"},
	"spectral": {"runtime_path": "res://assets/audio/sfx/sfx_enemy_attack/spectral.wav", "gain_db": -3.0, "priority": 70, "future_only": false, "manifest_id": "sfx_enemy_attack"},
	"flame": {"runtime_path": "res://assets/audio/sfx/sfx_enemy_attack/flame.wav", "gain_db": -3.0, "priority": 70, "future_only": true, "manifest_id": "sfx_enemy_attack"},
	"stone": {"runtime_path": "res://assets/audio/sfx/sfx_enemy_attack/stone.wav", "gain_db": -3.0, "priority": 70, "future_only": true, "manifest_id": "sfx_enemy_attack"},
	"chain": {"runtime_path": "res://assets/audio/sfx/sfx_enemy_attack/chain.wav", "gain_db": -3.0, "priority": 70, "future_only": true, "manifest_id": "sfx_enemy_attack"},
	"bell": {"runtime_path": "res://assets/audio/sfx/sfx_enemy_attack/bell.wav", "gain_db": -3.0, "priority": 70, "future_only": true, "manifest_id": "sfx_enemy_attack"},
	"temporary_expired": {"runtime_path": "res://assets/audio/sfx/sfx_expiry/temporary_expired.wav", "gain_db": -9.0, "priority": 20, "future_only": false, "manifest_id": "sfx_expiry"},
	"reward": {"runtime_path": "res://assets/audio/sfx/sfx_reward/reward.wav", "gain_db": -5.0, "priority": 75, "future_only": true, "manifest_id": "sfx_reward"},
	"victory": {"runtime_path": "res://assets/audio/sfx/sfx_victory/victory.wav", "gain_db": -3.0, "priority": 100, "future_only": false, "manifest_id": "sfx_victory"},
	"defeat": {"runtime_path": "res://assets/audio/sfx/sfx_defeat/defeat.wav", "gain_db": -4.0, "priority": 100, "future_only": false, "manifest_id": "sfx_defeat"},
	"guardian_phase_changed": {"runtime_path": "res://assets/audio/sfx/sfx_phase/guardian_phase_changed.wav", "gain_db": -3.0, "priority": 90, "future_only": true, "manifest_id": "sfx_phase"},
}

const ACTORS := {
	"shadeling": "spectral",
	"wickling": "flame",
	"stone_sentinel": "stone",
	"chain_warden": "chain",
	"bell_keeper": "bell",
}

const LOOPS := {
	"home_exploration": {
		"runtime_path": "", "status": "pending_source", "gain_db": 0.0,
		"contexts": ["screen_home", "screen_map", "screen_shop", "screen_recovery", "screen_events", "screen_rewards", "screen_collection"],
		"loop_offset_seconds": 0.0,
	},
	"combat": {
		"runtime_path": "", "status": "pending_source", "gain_db": 0.0,
		"contexts": ["screen_combat"], "loop_offset_seconds": 0.0,
	},
	"crypt": {
		"runtime_path": "res://assets/audio/ambience/crypt.ogg",
		"status": "delivered", "gain_db": 0.0,
		"contexts": ["screen_combat", "screen_map", "screen_shop", "screen_recovery", "screen_events"],
		"loop_offset_seconds": 0.0,
	},
}
