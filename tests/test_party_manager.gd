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
	t.eq(_body_shape_disabled(a), false, "active body collision enabled")
	t.eq(_hurtbox_shape_disabled(a), false, "active hurtbox collision enabled")
	t.eq(_body_shape_disabled(b), true, "inactive body collision disabled")
	t.eq(_hurtbox_shape_disabled(b), true, "inactive hurtbox collision disabled")

	a.global_position = Vector2(100, 50)
	var switched := [null]
	mgr.character_switched.connect(func(c): switched[0] = c)
	mgr.switch_to_next()

	t.eq(mgr.get_active_character(), b, "switched to second")
	t.eq(b.global_position, Vector2(100, 50), "position handed off")
	t.eq(b.visible, true, "new active visible")
	t.eq(a.visible, false, "old active hidden")
	await process_frame   # 碰撞开关用 set_deferred（防 flush 中改），等一帧落定
	t.eq(_body_shape_disabled(b), false, "new active body collision enabled")
	t.eq(_hurtbox_shape_disabled(b), false, "new active hurtbox collision enabled")
	t.eq(_body_shape_disabled(a), true, "old active body collision disabled")
	t.eq(_hurtbox_shape_disabled(a), true, "old active hurtbox collision disabled")
	t.eq(switched[0], b, "character_switched emitted new active")
	t.check(InputMap.has_action("select_character_1"), "input action exists for number 1")
	t.check(InputMap.has_action("select_character_2"), "input action exists for number 2")
	t.check(not InputMap.has_action("switch_character"), "legacy Tab switch input action removed")
	t.eq(mgr.max_vials, 2, "party starts with two max blood vials")
	t.eq(mgr.vials, 2, "party starts with two blood vials")
	b.get_health().take_damage(20)
	t.check(mgr.use_vial(), "using a vial succeeds when one is available")
	t.eq(mgr.vials, 1, "using a vial consumes one vial")
	t.eq(b.get_health().current, 25, "vial heals active character by half max health and clamps")
	mgr.use_vial()
	t.eq(mgr.vials, 0, "second vial can be consumed")
	t.eq(mgr.use_vial(), false, "using a vial fails when empty")
	mgr.refill_vials()
	t.eq(mgr.vials, 2, "refill restores vial count")
	t.check(mgr.has_method("switch_to_index"), "party manager can switch by numbered slot")
	if mgr.has_method("switch_to_index"):
		mgr.call("switch_to_index", 0)
		t.eq(mgr.get_active_character(), a, "numbered slot 1 switches to first character")
		mgr.call("switch_to_index", 1)
		t.eq(mgr.get_active_character(), b, "numbered slot 2 switches to second character")
		var tab_event := InputEventKey.new()
		tab_event.keycode = KEY_TAB
		tab_event.physical_keycode = KEY_TAB
		tab_event.pressed = true
		mgr._unhandled_input(tab_event)
		t.eq(mgr.get_active_character(), b, "Tab no longer switches characters")

	var death_mgr: PartyManager = PartyManager.new()
	var short_char := _make_char(Vector2(40, 80))
	var tall_char := _make_char(Vector2(40, 120))
	short_char.global_position = Vector2(300, 500)
	tall_char.global_position = Vector2(300, 500)
	death_mgr.add_child(short_char)
	death_mgr.add_child(tall_char)
	get_root().add_child(death_mgr)
	await process_frame
	var old_feet_y := short_char.get_feet_global_y_at(short_char.get_last_safe_position())
	death_mgr.notify_death(short_char)
	t.eq(death_mgr.get_active_character(), tall_char, "death switches to living character")
	t.eq(_feet_y(tall_char), old_feet_y, "death switch preserves foot height")
	death_mgr.free()

	mgr.free()
	quit(t.summary("party_manager"))

func _make_char(shape_size: Vector2 = Vector2(20, 20)) -> CharacterBase:
	var c := CharacterBase.new()
	var body_shape := CollisionShape2D.new()
	body_shape.name = "CollisionShape2D"
	body_shape.shape = RectangleShape2D.new()
	(body_shape.shape as RectangleShape2D).size = shape_size
	c.add_child(body_shape)
	var h := Health.new()
	h.name = "Health"
	c.add_child(h)
	var hb := Hurtbox.new()
	hb.name = "Hurtbox"
	c.add_child(hb)
	var hurt_shape := CollisionShape2D.new()
	hurt_shape.name = "CollisionShape2D"
	hurt_shape.shape = RectangleShape2D.new()
	(hurt_shape.shape as RectangleShape2D).size = shape_size
	hb.add_child(hurt_shape)
	return c

func _feet_y(character: CharacterBase) -> float:
	var shape := character.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	return character.global_position.y + shape.position.y + rect.size.y * 0.5

func _body_shape_disabled(character: CharacterBase) -> bool:
	return (character.get_node("CollisionShape2D") as CollisionShape2D).disabled

func _hurtbox_shape_disabled(character: CharacterBase) -> bool:
	return (character.get_node("Hurtbox/CollisionShape2D") as CollisionShape2D).disabled
