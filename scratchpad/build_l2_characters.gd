extends SceneTree

func _initialize() -> void:
	_build_ocarina()
	_build_hammer()
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

func _sprite(root: Node, sheet: String, scale: float, off_y: float) -> void:
	var spr := AnimatedSprite2D.new()
	spr.name = "Sprite"
	spr.sprite_frames = _frames(sheet)
	spr.animation = &"idle"
	spr.autoplay = "idle"
	spr.scale = Vector2(scale, scale)
	spr.position = Vector2(0, off_y)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(spr); spr.owner = root

func _body_col(root: Node, w: float, h: float) -> void:
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	root.add_child(c); c.owner = root

func _health(root: Node, max_hp: int) -> Node:
	var h := Node.new(); h.name = "Health"
	h.set_script(load("res://scripts/combat/health.gd"))
	h.set("max_health", max_hp)
	root.add_child(h); h.owner = root
	return h

func _hurtbox(root: Node, health: Node, w: float, h: float) -> void:
	var hb := Area2D.new(); hb.name = "Hurtbox"
	hb.set_script(load("res://scripts/combat/hurtbox.gd"))
	hb.collision_layer = 32; hb.collision_mask = 0; hb.monitoring = false
	root.add_child(hb); hb.owner = root
	hb.set("health", health); hb.set("invincible_time", 0.6)
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	hb.add_child(c); c.owner = root

func _save(root: Node, path: String, label: String) -> void:
	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, path)
	print("[%s] pack=%d save=%d" % [label, perr, serr])

func _build_ocarina() -> void:
	var root := CharacterBody2D.new(); root.name = "OcarinaGirl"
	root.set_script(load("res://scripts/characters/ocarina_girl.gd"))
	root.collision_layer = 2
	root.set("move_speed", 300.0); root.set("jump_velocity", -520.0); root.set("attack_duration", 0.45)
	_sprite(root, "res://assets/character/ocarina_girl/ocarina_girl_spritesheet.png", 0.55, -6.0)
	_body_col(root, 48, 112)
	var health := _health(root, 30)
	_hurtbox(root, health, 48, 112)
	var muzzle := Marker2D.new(); muzzle.name = "Muzzle"; muzzle.position = Vector2(38, -12)
	root.add_child(muzzle); muzzle.owner = root
	_save(root, "res://scenes/characters/ocarina_girl.tscn", "ocarina_girl")

func _build_hammer() -> void:
	var root := CharacterBody2D.new(); root.name = "HammerWarrior"
	root.set_script(load("res://scripts/characters/hammer_warrior.gd"))
	root.collision_layer = 2
	root.set("move_speed", 400.0); root.set("jump_velocity", -760.0); root.set("attack_duration", 0.38)
	# 用透明背景的 v2 序列图（不是绿底 chromakey）
	_sprite(root, "res://assets/character/hammer_warrior/hammer_warrior_spritesheet_regenerated_v2.png", 0.58, -3.0)
	_body_col(root, 62, 124)
	var health := _health(root, 55)
	_hurtbox(root, health, 62, 124)
	var hit := Area2D.new(); hit.name = "MeleeHitbox"
	hit.set_script(load("res://scripts/combat/hitbox.gd"))
	hit.collision_layer = 8; hit.collision_mask = 192; hit.monitorable = false; hit.set("damage", 28)
	root.add_child(hit); hit.owner = root
	var hc := CollisionShape2D.new(); hc.name = "CollisionShape2D"
	var hr := RectangleShape2D.new(); hr.size = Vector2(96, 104); hc.shape = hr; hc.position = Vector2(72, -4)
	hit.add_child(hc); hc.owner = root
	_save(root, "res://scenes/characters/hammer_warrior.tscn", "hammer_warrior")
