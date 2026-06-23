extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var sw: Switch = Switch.new()
	var door: Door = Door.new()
	get_root().add_child(sw)
	get_root().add_child(door)
	await process_frame
	sw.activated.connect(door.open)

	t.eq(door.is_open, false, "door closed initially")
	t.eq(sw.is_activated, false, "switch off initially")

	sw.receive_hit(1)
	t.eq(sw.is_activated, true, "switch activates on hit")
	t.eq(door.is_open, true, "door opens via signal")

	# 永久：再次命中不改变
	sw.receive_hit(1)
	t.eq(sw.is_activated, true, "switch stays activated")

	sw.free(); door.free()
	quit(t.summary("switch_door"))
