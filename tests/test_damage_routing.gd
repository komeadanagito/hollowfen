extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var h: Health = Health.new()
	h.max_health = 50
	var hurt: Hurtbox = Hurtbox.new()
	hurt.health = h
	get_root().add_child(h)
	get_root().add_child(hurt)
	await process_frame  # 等 _ready

	hurt.receive_hit(15)
	t.eq(h.current, 35, "hurtbox routes damage to health")

	# Hitbox 命中带 receive_hit 的对象
	var hit: Hitbox = Hitbox.new()
	hit.damage = 5
	var got := [0]
	var dummy := DummyTarget.new()
	dummy.on_hit = func(d): got[0] = d
	get_root().add_child(hit)
	get_root().add_child(dummy)
	await process_frame
	hit._on_area_entered(dummy)  # 直接调用碰撞回调验证路由
	t.eq(got[0], 5, "hitbox calls receive_hit with damage")

	h.free(); hurt.free(); hit.free(); dummy.free()
	quit(t.summary("damage_routing"))

class DummyTarget extends Area2D:
	var on_hit: Callable
	func receive_hit(damage: int) -> void:
		on_hit.call(damage)
