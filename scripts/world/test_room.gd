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
	await _wait_for_death_animation(character)
	if _spawn == null or not is_instance_valid(character):
		return
	character.respawn(_spawn.global_position)

func _wait_for_death_animation(character: CharacterBase) -> void:
	var sprite := character.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"death"):
		await get_tree().create_timer(0.2).timeout
		return
	if sprite.animation != &"death":
		sprite.play(&"death")
	if sprite.sprite_frames.get_animation_loop(&"death"):
		await get_tree().create_timer(0.2).timeout
	elif sprite.is_playing():
		await sprite.animation_finished
