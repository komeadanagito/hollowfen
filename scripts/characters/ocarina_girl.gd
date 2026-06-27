class_name OcarinaGirl
extends CharacterBase

const HOMING_NOTE_SCENE := preload("res://scenes/combat/homing_note.tscn")

@export var self_heal_amount: int = 8

@onready var _muzzle: Marker2D = $Muzzle

func _do_attack() -> void:
	var health := get_health()
	if health:
		health.heal(self_heal_amount)
	var note := HOMING_NOTE_SCENE.instantiate()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(note)
	var muzzle_offset := Vector2(absf(_muzzle.position.x) * _facing, _muzzle.position.y)
	note.global_position = global_position + muzzle_offset
	note.launch(Vector2(_facing, 0.0))
