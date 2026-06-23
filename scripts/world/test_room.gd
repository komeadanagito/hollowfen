class_name TestRoom
extends Node2D

@export var party_manager: PartyManager

@onready var _spawn: Marker2D = $SpawnPoint

func _ready() -> void:
	_wire_switch_to_door()
	_wire_character_deaths()

func _wire_switch_to_door() -> void:
	var switch := get_node_or_null("Switch") as Switch
	var door := get_node_or_null("Door") as Door
	if switch == null or door == null:
		return
	var callback := Callable(door, "open")
	if not switch.activated.is_connected(callback):
		switch.activated.connect(callback)

func _wire_character_deaths() -> void:
	if party_manager == null:
		party_manager = get_node_or_null("PartyManager") as PartyManager
	if party_manager == null:
		return
	for child in party_manager.get_children():
		if child is CharacterBase:
			var character := child as CharacterBase
			var health := character.get_health()
			if health:
				var callback := _on_character_died.bind(character)
				if not health.died.is_connected(callback):
					health.died.connect(callback)

func _on_character_died(character: CharacterBase) -> void:
	if _spawn == null or not is_instance_valid(character):
		return
	character.respawn(_spawn.global_position)
