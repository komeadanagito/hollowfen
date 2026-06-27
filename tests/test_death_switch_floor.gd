extends SceneTree

# 回归：死亡自动切角色时，新角色不应穿地板下沉
# （死亡由 DeathZone.body_entered 在物理 flush 中触发，碰撞开关必须 deferred）

const TestHelper = preload("res://tests/test_helper.gd")
const Scene = preload("res://scenes/tutorial_level.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var r := Scene.instantiate()
	get_root().add_child(r)
	await process_frame
	await process_frame
	var pm = r.get_node("PartyManager")
	var k = r.get_node("PartyManager/Knight")
	var a = r.get_node("PartyManager/Archer")
	pm.unlock(a)

	# knight 在坑左缘附近落稳
	k.global_position = Vector2(1850, 740)
	for i in 15:
		await physics_frame
	# 让 knight 自然走出坑左缘掉进坑 → DeathZone.body_entered 在物理 flush 中触发死亡切换
	Input.action_press("move_right")
	for i in 80:
		await physics_frame
	Input.action_release("move_right")
	# 留时间让接管角色落定
	for i in 60:
		await physics_frame

	var active = pm.get_active_character()
	# 修复前：新角色碰撞被 flush 阻止、永久禁用 → 无限穿地板下沉 (y 趋向极大、永不落地)
	t.check(active.is_on_floor(), "切换/复活后的角色站在地面上（未穿地板无限下沉）")
	t.check(active.global_position.y < 800.0, "角色未沉到地面以下 (y=%d)" % int(active.global_position.y))

	quit(t.summary("test_death_switch_floor"))
