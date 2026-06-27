class_name Bonfire
extends Area2D

@export var party_manager: PartyManager

signal activated

var is_activated: bool = false

func activate() -> void:
	if party_manager == null:
		return
	is_activated = true
	party_manager.activate_bonfire(global_position)
	activated.emit()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBase and (body as CharacterBase).is_active():
		activate()
