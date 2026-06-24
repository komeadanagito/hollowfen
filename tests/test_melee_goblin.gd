extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const GoblinScene = preload("res://scenes/enemies/melee_goblin.tscn")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()

	# 1) 无玩家时巡逻（找不到目标）
	var g1 := GoblinScene.instantiate()
	get_root().add_child(g1)
	await process_frame
	t.check(g1._find_player() == null, "无激活玩家时 _find_player 为空")

	# 2) 有激活玩家在视野内 → 进入 CHASE
	var knight := KnightScene.instantiate()
	get_root().add_child(knight)
	await process_frame
	knight.set_active(true)
	knight.global_position = Vector2(300, 0)   # detect_range 内, 竖直差 0
	var g2 := GoblinScene.instantiate()
	get_root().add_child(g2)
	g2.global_position = Vector2(0, 0)
	await physics_frame
	await physics_frame
	t.check(g2._find_player() == knight, "找到激活的 knight")
	t.eq(g2.state, g2.State.CHASE, "视野内进入 CHASE")

	# 3) 玩家进入攻击范围 → 触发攻击（cooldown 被设置）
	knight.global_position = Vector2(60, 0)     # attack_range(95) 内
	for i in 4:
		await physics_frame
	t.check(g2._cooldown > 0.0, "攻击范围内触发挥砍（cooldown>0）")

	# 4) 玩家远离视野 → 回到 PATROL（等当前挥砍动作结束, ATTACK 约 0.45s）
	knight.global_position = Vector2(5000, 0)
	for i in 45:
		await physics_frame
	t.eq(g2.state, g2.State.PATROL, "玩家离开视野回到 PATROL")

	quit(t.summary("test_melee_goblin"))
