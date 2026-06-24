extends SceneTree

# 场景接线烟测：Knight 能实例化、_ready 接线无空引用、受重力落到地面。
# 手感(移动/跳跃)仍需人工运行观察，此测试只保证结构正确。

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()

	# 地板
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1  # terrain
	var fcol := CollisionShape2D.new()
	var fshape := RectangleShape2D.new()
	fshape.size = Vector2(400, 20)
	fcol.shape = fshape
	floor_body.add_child(fcol)
	floor_body.position = Vector2(0, 120)
	get_root().add_child(floor_body)

	# Knight
	var KnightScene: PackedScene = load("res://scenes/characters/knight.tscn")
	t.check(KnightScene != null, "knight.tscn loads")
	var knight: CharacterBase = KnightScene.instantiate()
	knight.position = Vector2(0, 0)
	get_root().add_child(knight)
	knight.set_active(true)
	await process_frame  # 让 _ready 跑

	t.check(knight.get_health() != null, "knight has Health wired")
	t.eq(knight.get_health().max_health, 40, "knight max_health == 40")
	var sprite := knight.get_node("Sprite")
	t.check(sprite is AnimatedSprite2D, "knight uses animated spritesheet asset")
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		knight._set_state(CharacterBase.State.IDLE)
		_check_animation_set(t, anim_sprite, "knight")

	# 跑约 1 秒物理，应落到地面
	for i in 60:
		await physics_frame
	t.check(knight.is_on_floor(), "knight lands on floor under gravity")
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		knight._set_state(CharacterBase.State.RUN)
		t.eq(anim_sprite.animation, &"walk", "knight run state plays walk")
		knight._set_state(CharacterBase.State.ATTACK)
		t.eq(anim_sprite.animation, &"attack", "knight attack state plays attack")
		knight.get_health().take_damage(999)
		t.eq(anim_sprite.animation, &"death", "knight death plays death")

	floor_body.free()
	knight.free()
	quit(t.summary("knight_scene"))

func _check_animation_set(t: TestHelper, sprite: AnimatedSprite2D, label: String) -> void:
	for animation in [&"idle", &"walk", &"attack", &"death"]:
		t.check(sprite.sprite_frames.has_animation(animation), "%s has %s animation" % [label, animation])
		t.check(sprite.sprite_frames.get_frame_count(animation) > 1, "%s %s uses sequence frames" % [label, animation])
		var first_texture := sprite.sprite_frames.get_frame_texture(animation, 0)
		t.eq(_texture_path(first_texture), "res://assets/knight_spritesheet_clean.png", "%s %s texture path" % [label, animation])
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
