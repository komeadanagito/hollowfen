extends SceneTree

func _initialize() -> void:
	_build_melee()
	_build_ranged()
	quit()

func _frames(sheet_path: String) -> SpriteFrames:
	var tex := load(sheet_path)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var rows := {"idle": 0, "walk": 1, "attack": 2, "death": 3}
	var speeds := {"idle": 6.0, "walk": 8.0, "attack": 12.0, "death": 6.0}
	var loops := {"idle": true, "walk": true, "attack": false, "death": false}
	for anim in rows:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, speeds[anim])
		sf.set_animation_loop(anim, loops[anim])
		for col in range(6):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * 256, int(rows[anim]) * 256, 256, 256)
			sf.add_frame(anim, at)
	return sf

func _sprite(root: Node, sheet: String, scale: float, offset_y: float) -> void:
	var spr := AnimatedSprite2D.new()
	spr.name = "Sprite"
	spr.sprite_frames = _frames(sheet)
	spr.animation = &"idle"
	spr.autoplay = "idle"
	spr.scale = Vector2(scale, scale)   # 按各 sheet 内角色实际像素高度校准, 使屏上≈骑士124px
	spr.position = Vector2(0, offset_y) # 让贴图脚部对齐碰撞盒底(站地面)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(spr); spr.owner = root

func _body_health_hurt(root: Node, max_hp: int) -> void:
	var body_col := CollisionShape2D.new()
	body_col.name = "CollisionShape2D"
	var bshape := RectangleShape2D.new(); bshape.size = Vector2(56, 120)
	body_col.shape = bshape
	root.add_child(body_col); body_col.owner = root

	var health := Node.new()
	health.name = "Health"
	health.set_script(load("res://scripts/combat/health.gd"))
	health.set("max_health", max_hp)
	root.add_child(health); health.owner = root

	var hurt := Area2D.new()
	hurt.name = "Hurtbox"
	hurt.set_script(load("res://scripts/combat/hurtbox.gd"))
	hurt.collision_layer = 64
	hurt.collision_mask = 0
	root.add_child(hurt); hurt.owner = root
	hurt.set("health", health)
	hurt.set("invincible_time", 0.0)
	var hurt_col := CollisionShape2D.new()
	hurt_col.name = "CollisionShape2D"
	var hshape := RectangleShape2D.new(); hshape.size = Vector2(56, 120)
	hurt_col.shape = hshape
	hurt.add_child(hurt_col); hurt_col.owner = root

func _save(root: Node, path: String, label: String) -> void:
	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, path)
	print("[%s] pack=%d save=%d" % [label, perr, serr])

func _build_melee() -> void:
	var root := CharacterBody2D.new()
	root.name = "MeleeGoblin"
	root.set_script(load("res://scripts/enemies/melee_goblin.gd"))
	root.collision_layer = 4
	root.collision_mask = 1
	_sprite(root, "res://assets/enemy/goblin/goblin_spritesheet_clean.png", 0.68, -16.0)  # idle角色184px -> ~125px
	_body_health_hurt(root, 45)

	var hit := Area2D.new()
	hit.name = "MeleeHitbox"
	hit.set_script(load("res://scripts/combat/hitbox.gd"))
	hit.collision_layer = 16
	hit.collision_mask = 32
	hit.monitorable = false
	hit.set("damage", 12)
	root.add_child(hit); hit.owner = root
	var hit_col := CollisionShape2D.new()
	hit_col.name = "CollisionShape2D"
	var hitshape := RectangleShape2D.new(); hitshape.size = Vector2(70, 80)
	hit_col.shape = hitshape
	hit_col.position = Vector2(50, 0)
	hit.add_child(hit_col); hit_col.owner = root

	_save(root, "res://scenes/enemies/melee_goblin.tscn", "melee_goblin")

func _build_ranged() -> void:
	var root := CharacterBody2D.new()
	root.name = "RangedGoblin"
	root.set_script(load("res://scripts/enemies/ranged_goblin.gd"))
	root.collision_layer = 4
	root.collision_mask = 1
	_sprite(root, "res://assets/enemy/goblin_archer/goblin_archer_spritesheet_clean.png", 0.53, 1.0)  # idle角色234px -> ~124px
	_body_health_hurt(root, 30)

	var muzzle := Marker2D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(0, -10)
	root.add_child(muzzle); muzzle.owner = root

	_save(root, "res://scenes/enemies/ranged_goblin.tscn", "ranged_goblin")
