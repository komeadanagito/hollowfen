extends SceneTree

# Arrow 飞行/命中路由 + Archer 场景接线烟测

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()

	# --- Arrow ---
	var ArrowScene: PackedScene = load("res://scenes/combat/arrow.tscn")
	t.check(ArrowScene != null, "arrow.tscn loads")
	var arrow: Arrow = ArrowScene.instantiate()
	arrow.lifetime = 0.01
	get_root().add_child(arrow)
	await process_frame
	arrow.launch(Vector2(1, 0))
	var x0: float = arrow.global_position.x
	arrow._physics_process(0.1)
	t.check(arrow.global_position.x > x0, "arrow moves along launch direction")

	var got := [0]
	var dummy := ArrowDummy.new()
	dummy.on_hit = func(d): got[0] = d
	arrow._on_area_entered(dummy)
	t.eq(got[0], arrow.damage, "arrow routes damage on hit")
	t.check(arrow.is_queued_for_deletion(), "arrow frees after hitting target")
	dummy.free()
	await create_timer(0.02).timeout

	# --- Archer ---
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var fcol := CollisionShape2D.new()
	var fshape := RectangleShape2D.new()
	fshape.size = Vector2(400, 20)
	fcol.shape = fshape
	floor_body.add_child(fcol)
	floor_body.position = Vector2(0, 120)
	get_root().add_child(floor_body)

	var ArcherScene: PackedScene = load("res://scenes/characters/archer.tscn")
	t.check(ArcherScene != null, "archer.tscn loads")
	var archer: CharacterBase = ArcherScene.instantiate()
	archer.position = Vector2(0, 0)
	get_root().add_child(archer)
	archer.set_active(true)
	await process_frame
	t.eq(archer.get_health().max_health, 25, "archer max_health == 25")
	var sprite := archer.get_node("Sprite")
	t.check(sprite is AnimatedSprite2D, "archer uses animated spritesheet asset")
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		archer._set_state(CharacterBase.State.IDLE)
		_check_animation_set(t, anim_sprite, "archer")
	for i in 60:
		await physics_frame
	t.check(archer.is_on_floor(), "archer lands on floor under gravity")
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		archer._set_state(CharacterBase.State.RUN)
		t.eq(anim_sprite.animation, &"walk", "archer run state plays walk")
		archer._set_state(CharacterBase.State.ATTACK)
		t.eq(anim_sprite.animation, &"attack", "archer attack state plays attack")
		archer.get_health().take_damage(999)
		t.eq(anim_sprite.animation, &"death", "archer death plays death")

	floor_body.free()
	archer.free()
	quit(t.summary("ranged"))

class ArrowDummy extends Area2D:
	var on_hit: Callable
	func receive_hit(damage: int) -> void:
		on_hit.call(damage)

func _check_animation_set(t: TestHelper, sprite: AnimatedSprite2D, label: String) -> void:
	for animation in [&"idle", &"walk", &"attack", &"death"]:
		t.check(sprite.sprite_frames.has_animation(animation), "%s has %s animation" % [label, animation])
		t.check(sprite.sprite_frames.get_frame_count(animation) > 1, "%s %s uses sequence frames" % [label, animation])
		var first_texture := sprite.sprite_frames.get_frame_texture(animation, 0)
		t.eq(_texture_path(first_texture), "res://assets/character/archer/archer_spritesheet_clean.png", "%s %s texture path" % [label, animation])
	t.check(sprite.sprite_frames.get_animation_loop(&"idle"), "%s idle loops" % label)
	t.check(sprite.sprite_frames.get_animation_loop(&"walk"), "%s walk loops" % label)
	t.eq(sprite.sprite_frames.get_animation_loop(&"attack"), false, "%s attack does not loop" % label)
	t.eq(sprite.sprite_frames.get_animation_loop(&"death"), false, "%s death does not loop" % label)
	t.eq(sprite.animation, &"idle", "%s plays idle animation" % label)
	t.check(sprite.is_playing(), "%s animation is playing" % label)

func _texture_path(texture: Texture2D) -> String:
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		return atlas_texture.atlas.resource_path
	return texture.resource_path
