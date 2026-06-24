class_name TutorialLevel
extends Node2D

@export var party_manager: PartyManager
@export var tutorial_layer: TutorialLayer

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
	if _spawn and is_instance_valid(character):
		character.respawn(_spawn.global_position)

func _wire_exit() -> void:
	var ex := get_node_or_null("LevelExit") as LevelExit
	if ex and not ex.reached.is_connected(_on_exit_reached):
		ex.reached.connect(_on_exit_reached)

func _on_exit_reached() -> void:
	print("[TutorialLevel] 关卡完成！")

func _process(_delta: float) -> void:
	_check_prompt_progress()

func _check_prompt_progress() -> void:
	if tutorial_layer == null:
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		tutorial_layer.dismiss("move")
	if Input.is_action_just_pressed("jump"):
		tutorial_layer.dismiss("jump")
	if Input.is_action_just_pressed("switch_character"):
		tutorial_layer.dismiss("switch")
	if Input.is_action_just_pressed("attack"):
		var active := party_manager.get_active_character() if party_manager else null
		if active and active.get_node_or_null("Muzzle") != null:
			tutorial_layer.dismiss("shoot")   # Archer 在射箭
		else:
			tutorial_layer.dismiss("attack")  # Knight 在近战
