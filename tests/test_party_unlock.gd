extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const CharScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")
const PartyManagerScript = preload("res://scripts/party/party_manager.gd")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var pm := Node2D.new()
	pm.set_script(PartyManagerScript)
	var knight := CharScene.instantiate()
	var archer := ArcherScene.instantiate()
	pm.add_child(knight)
	pm.add_child(archer)
	get_root().add_child(pm)
	await process_frame

	# 锁定 archer（index 1），切换应跳过它
	pm.set_locked(1, true)
	pm.switch_to_next()
	t.check(pm.get_active_character() == knight, "锁定 archer 后切换仍是 knight")

	# 解锁后可切到 archer
	pm.unlock(archer)
	pm.switch_to_next()
	t.check(pm.get_active_character() == archer, "解锁后能切到 archer")

	# 解锁信号
	var emitted := {"hit": false}
	var pm2 := Node2D.new()
	pm2.set_script(PartyManagerScript)
	var k2 := CharScene.instantiate()
	var a2 := ArcherScene.instantiate()
	pm2.add_child(k2)
	pm2.add_child(a2)
	get_root().add_child(pm2)
	await process_frame
	pm2.set_locked(1, true)
	pm2.character_unlocked.connect(func(c): emitted["hit"] = (c == a2))
	pm2.unlock(a2)
	t.check(emitted["hit"], "unlock 发出 character_unlocked 信号")

	quit(t.summary("test_party_unlock"))
