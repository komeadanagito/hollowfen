extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const EnemyArrowScene = preload("res://scenes/combat/enemy_arrow.tscn")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()

	# 碰撞层正确：敌人箭只打玩家 hurtbox + 墙
	var arrow := EnemyArrowScene.instantiate()
	t.eq(arrow.collision_layer, 16, "敌人箭 layer=enemy_hitbox")
	t.eq(arrow.collision_mask, 33, "敌人箭 mask=terrain+player_hurtbox")

	# 命中玩家 Hurtbox → 玩家扣血（arrow 不入树，直接调用处理器，避免自动命中提前 free）
	var knight := KnightScene.instantiate()
	get_root().add_child(knight)
	await process_frame
	var hp = knight.get_health()
	var before = hp.current
	var hurtbox := knight.get_node("Hurtbox") as Area2D
	arrow._on_area_entered(hurtbox)
	t.check(hp.current < before, "敌人箭命中后玩家扣血 (%d -> %d)" % [before, hp.current])

	quit(t.summary("test_enemy_arrow"))
