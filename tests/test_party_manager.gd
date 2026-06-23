extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()
	var mgr: PartyManager = PartyManager.new()
	var a := _make_char()
	var b := _make_char()
	mgr.add_child(a)
	mgr.add_child(b)
	get_root().add_child(mgr)  # 触发 _ready
	await process_frame

	t.eq(mgr.get_active_character(), a, "first child active initially")
	t.eq(a.visible, true, "active visible")
	t.eq(b.visible, false, "inactive hidden")

	a.global_position = Vector2(100, 50)
	var switched := [null]
	mgr.character_switched.connect(func(c): switched[0] = c)
	mgr.switch_to_next()

	t.eq(mgr.get_active_character(), b, "switched to second")
	t.eq(b.global_position, Vector2(100, 50), "position handed off")
	t.eq(b.visible, true, "new active visible")
	t.eq(a.visible, false, "old active hidden")
	t.eq(switched[0], b, "character_switched emitted new active")

	mgr.free()
	quit(t.summary("party_manager"))

func _make_char() -> CharacterBase:
	var c := CharacterBase.new()
	var h := Health.new()
	h.name = "Health"
	c.add_child(h)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	c.add_child(hb)
	return c
