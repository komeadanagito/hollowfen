extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const GoblinScene = preload("res://scenes/enemies/ranged_goblin.tscn")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void:
	_run()

func _count_arrows() -> int:
	var n := 0
	for c in get_root().get_children():
		if c is Area2D and c.has_method("launch"):
			n += 1
	return n

func _run() -> void:
	var t := TestHelper.new()

	var knight := KnightScene.instantiate()
	get_root().add_child(knight)
	await process_frame
	knight.set_active(true)
	knight.global_position = Vector2(400, 0)   # fire_range 内, > min_distance

	# 1) 射程内 + 距离合适 → 发射 enemy_arrow（先记基线再放哥布林）
	var before := _count_arrows()
	var g := GoblinScene.instantiate()
	get_root().add_child(g)
	g.global_position = Vector2(0, 0)
	for i in 4:
		await physics_frame
	t.check(_count_arrows() > before, "射程内发射敌人箭")

	# 2) 玩家太近 → 后退（velocity.x 背离玩家）
	knight.global_position = Vector2(100, 0)    # < min_distance(220), 玩家在右
	await physics_frame
	t.check(g.velocity.x < 0.0, "玩家太近时向左后退")

	# 3) 射程判定：远处不在射程、竖直差过大不在射程
	knight.global_position = Vector2(5000, 0)
	t.check(not g._in_range(knight), "超出水平射程 → 不在射程")
	knight.global_position = Vector2(400, 400)   # 水平内但竖直差>tolerance
	t.check(not g._in_range(knight), "竖直差过大 → 不在射程")
	knight.global_position = Vector2(400, 0)
	t.check(g._in_range(knight), "射程内 → 在射程")

	quit(t.summary("test_ranged_goblin"))
