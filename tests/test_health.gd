extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var h: Health = Health.new()
	h.max_health = 30
	get_root().add_child(h)
	await process_frame  # 等一帧让 _ready 执行(初始化 current)

	t.eq(h.current, 30, "initial current == max")
	t.eq(h.is_dead(), false, "alive at start")

	var changed := [0, 0]
	h.health_changed.connect(func(c, m): changed[0] = c; changed[1] = m)
	var died := [false]
	h.died.connect(func(): died[0] = true)

	h.take_damage(10)
	t.eq(h.current, 20, "current after 10 dmg")
	t.eq(changed[0], 20, "health_changed emitted current")

	h.take_damage(100)
	t.eq(h.current, 0, "current clamps at 0")
	t.eq(h.is_dead(), true, "dead after lethal")
	t.eq(died[0], true, "died signal emitted")

	h.reset()
	t.eq(h.current, 30, "reset restores max")
	t.eq(h.is_dead(), false, "alive after reset")

	h.free()
	quit(t.summary("health"))
