class_name CameraFollow
extends Camera2D

@export var party_manager: PartyManager
@export var smooth: float = 8.0

func _physics_process(delta: float) -> void:
	if party_manager == null:
		return
	var target := party_manager.get_active_character()
	if target == null:
		return
	global_position = global_position.lerp(target.global_position, clampf(smooth * delta, 0.0, 1.0))
