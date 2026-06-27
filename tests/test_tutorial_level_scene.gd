extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const Scene = preload("res://scenes/tutorial_level.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var root := Scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	var pm = root.get_node_or_null("PartyManager")
	t.check(pm != null, "PartyManager 存在")
	t.check(root.get_node_or_null("SpawnPoint") != null, "SpawnPoint 存在")
	t.check(root.get_node_or_null("Door_A") != null, "Door_A 存在")
	t.check(root.get_node_or_null("Switch_A") != null, "Switch_A 存在")
	t.check(root.get_node_or_null("ArcherPickup") != null, "ArcherPickup 存在")
	t.check(root.get_node_or_null("LevelExit") != null, "LevelExit 存在")
	t.check(root.get_node_or_null("L_Move") is Label, "地图指导文字存在(L_Move)")
	var ally_label := root.get_node_or_null("L_Ally") as Label
	t.check(ally_label != null, "地图指导文字存在(L_Ally)")
	if ally_label:
		t.check(ally_label.text.contains("2"), "获得射手提示改为按 2")
		t.check(not ally_label.text.contains("Tab"), "获得射手提示不再写 Tab")

	# 开局 Archer 锁定：切换应保持当前角色
	var first = pm.get_active_character()
	pm.switch_to_next()
	t.check(pm.get_active_character() == first, "开局 Archer 锁定，切换无效")

	# 解锁后切换可生效
	var archer = root.get_node_or_null("PartyManager/Archer")
	pm.unlock(archer)
	t.check(pm.has_method("switch_to_index"), "PartyManager 支持数字槽位切换")
	if pm.has_method("switch_to_index"):
		pm.call("switch_to_index", 1)
		t.check(pm.get_active_character() == archer, "解锁后能用 2 切到 Archer")

		var knight := root.get_node_or_null("PartyManager/Knight") as CharacterBase
		pm.call("switch_to_index", 0)
		t.check(pm.get_active_character() == knight, "回到 Knight 准备测试死亡切换")
		if knight and archer:
			knight.global_position = Vector2(1234, 740)
			knight.get_health().take_damage(99999)
			t.check(pm.get_active_character() == archer, "Knight 死亡后自动切到 Archer")
			t.eq(archer.global_position, knight.get_last_safe_position(), "死亡切换继承最近安全位置")

			knight.respawn(Vector2(2200, 740))
			archer.respawn(Vector2(2200, 740))
			pm.revive_all()
			pm.reset_to_first()
			root._on_pit_entered(knight)
			t.check(pm.get_active_character() == archer, "Knight 掉进深坑后自动切到 Archer")

	# 开关-门接线：触发 Switch_A 后 Door_A 打开
	var pickup := root.get_node_or_null("ArcherPickup")
	if pickup and archer:
		var root2 := Scene.instantiate()
		get_root().add_child(root2)
		await process_frame
		await process_frame
		var pm2 = root2.get_node_or_null("PartyManager")
		var knight2 := root2.get_node_or_null("PartyManager/Knight") as CharacterBase
		var archer2 := root2.get_node_or_null("PartyManager/Archer") as CharacterBase
		var pickup2 := root2.get_node_or_null("ArcherPickup")
		pickup2._on_body_entered(knight2)
		knight2.get_health().take_damage(99999)
		t.check(pm2.get_active_character() == archer2, "真实拾取 Archer 后 Knight 死亡自动切到 Archer")
		root2.queue_free()

	# 开关-门接线：触发 Switch_A 后 Door_A 打开
	var sa = root.get_node_or_null("Switch_A")
	var da = root.get_node_or_null("Door_A")
	sa.receive_hit(1)
	t.check(da.is_open, "Switch_A 触发后 Door_A 打开")

	quit(t.summary("test_tutorial_level_scene"))
