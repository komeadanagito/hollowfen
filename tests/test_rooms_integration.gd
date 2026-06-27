extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const RoomA = preload("res://scenes/rooms/room_tutorial_a.tscn")
const RoomB = preload("res://scenes/rooms/room_tutorial_b.tscn")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	var game = get_root().get_node("Game")
	var rm = get_root().get_node("RoomManager")
	game.start_new_game()
	rm.set_change_enabled(false)
	# Enter A
	var a = RoomA.instantiate(); get_root().add_child(a); await process_frame; await process_frame
	var pmA = a.party_manager
	t.check(pmA != null, "room_a has PartyManager")
	# Unlock archer and set knight HP to sentinel 11
	var chars = pmA.get_characters()
	var knight = chars[0]
	var arc = chars[1]
	pmA.set_unlocked(arc, true)
	knight.get_health().set_current(11)
	# Depart to B (saves state)
	a.depart("res://scenes/rooms/room_tutorial_b.tscn", "from_a")
	a.free()
	# Enter B: state should carry over, party should spawn at from_a entry
	var b = RoomB.instantiate(); get_root().add_child(b); await process_frame; await process_frame
	var pmB = b.party_manager
	t.eq(pmB.get_characters()[0].get_health().current, 11, "HP carried to B")
	t.check(pmB.is_unlocked(pmB.get_characters()[1]), "unlock carried to B")
	var entry_pos = b._entry_position("from_a")
	t.eq(pmB.get_active_character().global_position, entry_pos, "spawned at from_a entry")
	quit(t.summary("test_rooms_integration"))
