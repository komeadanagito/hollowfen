extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const GameScript = preload("res://scripts/systems/game.gd")
const PM = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")

func _initialize() -> void: _run()

func _make_party():
	var pm := Node2D.new(); pm.set_script(PM)
	pm.add_child(KnightScene.instantiate()); pm.add_child(ArcherScene.instantiate())
	get_root().add_child(pm)
	return pm

func _run() -> void:
	var t := TestHelper.new()
	var game = GameScript.new(); get_root().add_child(game)
	game.start_new_game()
	var pmA = _make_party(); await process_frame
	# A 房间：解锁 archer、knight 残血、用掉一个血瓶
	var kA = pmA.get_characters()[0]; var aA = pmA.get_characters()[1]
	pmA.set_unlocked(aA, true)
	kA.get_health().set_current(13)
	pmA.vials = 1
	game.save_party_state(pmA)
	# B 房间：新队伍，apply 后状态应一致
	var pmB = _make_party(); await process_frame
	game.apply_party_state(pmB)
	var kB = pmB.get_characters()[0]; var aB = pmB.get_characters()[1]
	t.eq(kB.get_health().current, 13, "血量跨房间带过去")
	t.check(pmB.is_unlocked(aB), "解锁状态跨房间带过去")
	t.eq(pmB.vials, 1, "血瓶跨房间带过去")
	quit(t.summary("test_game_state"))
