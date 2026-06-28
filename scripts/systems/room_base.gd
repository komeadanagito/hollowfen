class_name Room
extends Node2D

@export var party_manager: PartyManager
@export var default_entry: String = ""
## Characters listed here are locked at room entry on a fresh boot.
## On a revisit, Game.apply_party_state() will override with the persisted
## unlocked state, so this only affects the very first time the room loads.
@export var locked_characters: Array[String] = []
## Y below which the active character is killed (fallback for falling past
## all ground / pits). Robust against Area2D tunneling on fast falls.
@export var kill_plane_y: float = 1300.0

func _ready() -> void:
	add_to_group("room")
	if party_manager == null:
		party_manager = get_node_or_null("PartyManager") as PartyManager
	_apply_initial_locks()
	if has_node("/root/Game") and party_manager:
		get_node("/root/Game").apply_party_state(party_manager)
	_place_party_at_entry()
	_wire_room()

func _physics_process(_delta: float) -> void:
	if party_manager == null:
		return
	var active := party_manager.get_active_character()
	if active == null:
		return
	if active.global_position.y > kill_plane_y:
		var h := active.get_health()
		if h and not h.is_dead():
			h.take_damage(99999)

## Lock characters listed in `locked_characters` before Game state is applied.
## Order matters: this runs BEFORE apply_party_state so that a persisted
## unlocked state (from a revisit) correctly overrides the initial lock.
func _apply_initial_locks() -> void:
	if party_manager == null or locked_characters.is_empty():
		return
	for c in party_manager.get_characters():
		if c.name in locked_characters:
			party_manager.set_unlocked(c, false)

func depart(room_path: String, entry_id: String) -> void:
	if has_node("/root/Game") and party_manager:
		get_node("/root/Game").save_party_state(party_manager)
	if has_node("/root/RoomManager"):
		get_node("/root/RoomManager").go_to(room_path, entry_id)

func _place_party_at_entry() -> void:
	if party_manager == null:
		return
	var entry := ""
	if has_node("/root/RoomManager"):
		entry = get_node("/root/RoomManager").consume_entry()
	if entry == "":
		entry = default_entry
	var pos := _entry_position(entry)
	var active = party_manager.get_active_character()
	if active:
		active.global_position = pos

func _entry_position(entry_id: String) -> Vector2:
	for portal in _find_portals():
		if portal.get_entry_id() == entry_id:
			return portal.global_position
	var spawn := get_node_or_null("SpawnPoint") as Marker2D
	if spawn:
		return spawn.global_position
	push_warning("Room: no entry '%s' and no SpawnPoint; spawning at origin" % entry_id)
	return global_position

func _find_portals() -> Array:
	var out := []
	for child in get_children():
		if child is RoomPortal:
			out.append(child)
	return out

func _wire_room() -> void:
	# Auto-wire switch/door pairs by naming convention:
	# Switch_A / Door_A, Switch_B / Door_B, Switch_C / Door_C (max 3 pairs).
	# Each Switch.activated signal is connected to the matching Door.open method.
	for suffix in ["A", "B", "C"]:
		var sw := get_node_or_null("Switch_" + suffix) as Switch
		var dr := get_node_or_null("Door_" + suffix) as Door
		if sw and dr and not sw.activated.is_connected(Callable(dr, "open")):
			sw.activated.connect(Callable(dr, "open"))
	if party_manager:
		for child in party_manager.get_children():
			if child is CharacterBase:
				var h := (child as CharacterBase).get_health()
				var cb := _on_died.bind(child as CharacterBase)
				if h and not h.died.is_connected(cb):
					h.died.connect(cb)
		if not party_manager.party_wiped.is_connected(_on_party_wiped):
			party_manager.party_wiped.connect(_on_party_wiped)
	var pit := get_node_or_null("DeathZone") as Area2D
	if pit and not pit.body_entered.is_connected(_on_pit_entered):
		pit.body_entered.connect(_on_pit_entered)

func _on_died(character: CharacterBase) -> void:
	if party_manager:
		party_manager.notify_death(character)

func _on_party_wiped() -> void:
	if party_manager == null:
		return
	party_manager.revive_all()
	var pos := _entry_position(default_entry)
	for child in party_manager.get_children():
		if child is CharacterBase:
			(child as CharacterBase).respawn(pos)
	party_manager.reset_to_first()

func _on_pit_entered(body: Node) -> void:
	if body is CharacterBase and (body as CharacterBase).is_active():
		var h := (body as CharacterBase).get_health()
		if h:
			h.take_damage(99999)
