class_name LevelExit
extends Area2D

signal reached

var _reached: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _reached:
		return
	if body is CharacterBase and (body as CharacterBase).is_active():
		_reached = true
		reached.emit()
