extends SceneTree

func _initialize() -> void:
	var root := CharacterBody2D.new()
	root.name = "RangedGoblin"
	root.set_script(load("res://scripts/enemies/ranged_goblin.gd"))
	root.collision_layer = 4
	root.collision_mask = 1

	var body_col := CollisionShape2D.new()
	body_col.name = "CollisionShape2D"
	var bshape := RectangleShape2D.new(); bshape.size = Vector2(56, 100)
	body_col.shape = bshape
	root.add_child(body_col); body_col.owner = root

	var spr := ColorRect.new()
	spr.name = "Sprite"
	spr.color = Color(0.55, 0.3, 0.7)  # 紫：弓哥布林占位
	spr.size = Vector2(80, 110)
	spr.position = Vector2(-40, -60)
	spr.editor_description = "[物料] 类别=敌人 | 占位=紫块80x110 PH_Enemy_RangedGoblin | 替换=持弓哥布林 | 备注=保持距离+射箭"
	root.add_child(spr); spr.owner = root

	var muzzle := Marker2D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(0, -10)
	root.add_child(muzzle); muzzle.owner = root

	var health := Node.new()
	health.name = "Health"
	health.set_script(load("res://scripts/combat/health.gd"))
	health.set("max_health", 30)
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
	var hshape := RectangleShape2D.new(); hshape.size = Vector2(56, 100)
	hurt_col.shape = hshape
	hurt.add_child(hurt_col); hurt_col.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/enemies/ranged_goblin.tscn")
	print("[ranged_goblin] pack=", perr, " save=", serr)
	quit()
