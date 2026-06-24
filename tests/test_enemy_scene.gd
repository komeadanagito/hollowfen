extends SceneTree

# 敌人接线烟测：加载、Health、落地、巡逻移动、接触命中盒开启

func _initialize() -> void:
	_run()

func _run() -> void:
	var t := TestHelper.new()

	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var fcol := CollisionShape2D.new()
	var fshape := RectangleShape2D.new()
	fshape.size = Vector2(600, 20)
	fcol.shape = fshape
	floor_body.add_child(fcol)
	floor_body.position = Vector2(0, 120)
	get_root().add_child(floor_body)

	var EnemyScene: PackedScene = load("res://scenes/enemies/patrol_enemy.tscn")
	t.check(EnemyScene != null, "patrol_enemy.tscn loads")
	var enemy: Node2D = EnemyScene.instantiate()
	enemy.position = Vector2(0, 80)
	get_root().add_child(enemy)
	await process_frame

	var health: Health = enemy.get_node("Health")
	t.eq(health.max_health, 30, "enemy max_health == 30")
	var sprite := enemy.get_node("Sprite")
	t.check(sprite is AnimatedSprite2D, "enemy uses animated spritesheet asset")
	if sprite is AnimatedSprite2D:
		_check_animation_set(t, sprite as AnimatedSprite2D, "enemy")
	var contact: Hitbox = enemy.get_node("ContactHitbox")
	t.check(contact.monitoring, "contact hitbox is active after _ready")

	var x0: float = enemy.global_position.x
	for i in 30:
		await physics_frame
	t.check(enemy.is_on_floor(), "enemy stands on floor")
	t.check(absf(enemy.global_position.x - x0) > 5.0, "enemy patrols (moves horizontally)")
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		t.eq(anim_sprite.animation, &"walk", "enemy patrol plays walk")
		health.take_damage(999)
		t.eq(anim_sprite.animation, &"death", "enemy death plays death")

	floor_body.free()
	enemy.free()
	quit(t.summary("enemy_scene"))

func _check_animation_set(t: TestHelper, sprite: AnimatedSprite2D, label: String) -> void:
	for animation in [&"idle", &"walk", &"attack", &"death"]:
		t.check(sprite.sprite_frames.has_animation(animation), "%s has %s animation" % [label, animation])
		t.check(sprite.sprite_frames.get_frame_count(animation) > 1, "%s %s uses sequence frames" % [label, animation])
		var first_texture := sprite.sprite_frames.get_frame_texture(animation, 0)
		t.eq(_texture_path(first_texture), "res://assets/slime_spritesheet_clean.png", "%s %s texture path" % [label, animation])
	t.check(sprite.sprite_frames.get_animation_loop(&"idle"), "%s idle loops" % label)
	t.check(sprite.sprite_frames.get_animation_loop(&"walk"), "%s walk loops" % label)
	t.eq(sprite.sprite_frames.get_animation_loop(&"attack"), false, "%s attack does not loop" % label)
	t.eq(sprite.sprite_frames.get_animation_loop(&"death"), false, "%s death does not loop" % label)
	t.check(sprite.is_playing(), "%s animation is playing" % label)

func _texture_path(texture: Texture2D) -> String:
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		return atlas_texture.atlas.resource_path
	return texture.resource_path
