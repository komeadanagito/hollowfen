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
	t.check(root.get_node_or_null("Door_Main") != null, "Door_Main 存在")
	t.check(root.get_node_or_null("Switch_A") != null, "Switch_A 存在")
	t.check(root.get_node_or_null("ArcherPickup") != null, "ArcherPickup 存在")
	t.check(root.get_node_or_null("LevelExit") != null, "LevelExit 存在")
	t.check(root.get_node_or_null("TutorialLayer") != null, "TutorialLayer 存在")

	# 开局 Archer 锁定：切换应保持当前角色
	var first = pm.get_active_character()
	pm.switch_to_next()
	t.check(pm.get_active_character() == first, "开局 Archer 锁定，切换无效")

	# 解锁后切换可生效
	var archer = root.get_node_or_null("PartyManager/Archer")
	pm.unlock(archer)
	pm.switch_to_next()
	t.check(pm.get_active_character() == archer, "解锁后能切到 Archer")

	# 开关-门接线：触发 Switch_A 后 Door_Main 打开
	var sa = root.get_node_or_null("Switch_A")
	var da = root.get_node_or_null("Door_Main")
	sa.receive_hit(1)
	t.check(da.is_open, "Switch_A 触发后 Door_Main 打开")

	quit(t.summary("test_tutorial_level_scene"))
