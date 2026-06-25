class_name TutorialLevel
extends Node2D

@export var party_manager: PartyManager

@onready var _spawn: Marker2D = $SpawnPoint

func _ready() -> void:
	if party_manager == null:
		party_manager = get_node_or_null("PartyManager") as PartyManager
	_lock_archer()
	for suffix in ["A", "B", "C"]:
		_wire_switch_door("Switch_" + suffix, "Door_" + suffix)
	_wire_deaths()
	_wire_exit()

func _lock_archer() -> void:
	if party_manager:
		party_manager.set_locked(1, true)  # index 1 = Archer

func _wire_switch_door(switch_name: String, door_name: String) -> void:
	var sw := get_node_or_null(switch_name) as Switch
	var dr := get_node_or_null(door_name) as Door
	if sw and dr and not sw.activated.is_connected(Callable(dr, "open")):
		sw.activated.connect(Callable(dr, "open"))

func _wire_deaths() -> void:
	if party_manager == null:
		return
	for child in party_manager.get_children():
		if child is CharacterBase:
			var h := (child as CharacterBase).get_health()
			var cb := _on_died.bind(child as CharacterBase)
			if h and not h.died.is_connected(cb):
				h.died.connect(cb)

func _on_died(character: CharacterBase) -> void:
	if _spawn == null or not is_instance_valid(character):
		return
	await _wait_for_death_animation(character)
	if _spawn and is_instance_valid(character):
		character.respawn(_spawn.global_position)

func _wait_for_death_animation(character: CharacterBase) -> void:
	var sprite := character.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"death"):
		await get_tree().create_timer(0.2).timeout
		return
	if sprite.animation != &"death":
		sprite.play(&"death")
	if sprite.sprite_frames.get_animation_loop(&"death"):
		await get_tree().create_timer(0.6).timeout
	elif sprite.is_playing():
		await sprite.animation_finished

func _wire_exit() -> void:
	var ex := get_node_or_null("LevelExit") as LevelExit
	if ex and not ex.reached.is_connected(_on_exit_reached):
		ex.reached.connect(_on_exit_reached)

func _on_exit_reached() -> void:
	print("[TutorialLevel] 关卡完成！")
