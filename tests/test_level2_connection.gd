extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const RoomB = preload("res://scenes/rooms/room_tutorial_b.tscn")
const Level2 = preload("res://scenes/level_2.tscn")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	# room_b 出口 portal 指向 level_2
	var b = RoomB.instantiate(); get_root().add_child(b)
	await process_frame; await process_frame
	var portal = b.get_node_or_null("Portal_ToLevel2")
	t.check(portal != null, "room_b 有通往 Level 2 的 Portal")
	if portal:
		t.eq(portal.target_room, "res://scenes/level_2.tscn", "Portal 指向 level_2.tscn")
	b.free()
	# level_2 进入时套用 Game 队伍状态（剑士残血/血瓶带过去）
	var game = get_root().get_node("Game"); game.start_new_game()
	game.hp["Knight"] = 9
	game.unlocked["Knight"] = true; game.unlocked["Archer"] = true
	game.vials = 1
	var l2 = Level2.instantiate(); get_root().add_child(l2)
	await process_frame; await process_frame
	var pm = l2.get_node("PartyManager")
	t.eq(pm.get_node("Knight").get_health().current, 9, "剑士残血带进 Level 2")
	t.eq(pm.vials, 1, "血瓶带进 Level 2")
	quit(t.summary("test_level2_connection"))
