class_name Archer
extends CharacterBase

const ARROW_SCENE := preload("res://scenes/combat/arrow.tscn")

@onready var _muzzle: Marker2D = $Muzzle

func _do_attack() -> void:
	var arrow: Arrow = ARROW_SCENE.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = _muzzle.global_position
	arrow.launch(Vector2(_facing, 0.0))
