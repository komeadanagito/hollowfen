class_name Level2
extends Node2D

@export var party_manager: PartyManager

@onready var _spawn: Marker2D = $SpawnPoint

func _ready() -> void:
	if party_manager == null:
		party_manager = get_node_or_null("PartyManager") as PartyManager
	_lock_new_party_members()
	for suffix in ["A", "B"]:
		_wire_switch_door("Switch_" + suffix, "Door_" + suffix)
	_wire_deaths()
	_wire_exit()
	_wire_pit()
	_wire_bonfires()
	if party_manager and not party_manager.party_wiped.is_connected(_on_party_wiped):
		party_manager.party_wiped.connect(_on_party_wiped)

func _lock_new_party_members() -> void:
	if party_manager == null:
		return
	party_manager.set_locked(2, true)
	party_manager.set_locked(3, true)

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
	if party_manager:
		party_manager.notify_death(character)

func _on_party_wiped() -> void:
	if party_manager == null or _spawn == null:
		return
	var respawn := party_manager.get_respawn_position()
	if respawn == Vector2.ZERO:
		respawn = _spawn.global_position
	party_manager.revive_all()
	for child in party_manager.get_children():
		if child is CharacterBase:
			(child as CharacterBase).respawn(respawn)
	party_manager.reset_to_first()

func _wire_pit() -> void:
	var pit := get_node_or_null("DeathZone") as Area2D
	if pit and not pit.body_entered.is_connected(_on_pit_entered):
		pit.body_entered.connect(_on_pit_entered)

func _on_pit_entered(body: Node) -> void:
	if body is CharacterBase and (body as CharacterBase).is_active():
		var h := (body as CharacterBase).get_health()
		if h:
			h.take_damage(99999)

func _wire_bonfires() -> void:
	for child in get_children():
		if child is Bonfire:
			var bonfire := child as Bonfire
			if bonfire.party_manager == null:
				bonfire.party_manager = party_manager

func _wire_exit() -> void:
	var ex := get_node_or_null("LevelExit") as LevelExit
	if ex and not ex.reached.is_connected(_on_exit_reached):
		ex.reached.connect(_on_exit_reached)

func _on_exit_reached() -> void:
	print("[Level2] 关卡完成！")
