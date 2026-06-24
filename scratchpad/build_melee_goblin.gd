extends SceneTree

func _initialize() -> void:
	var root := CharacterBody2D.new()
	root.name = "MeleeGoblin"
	root.set_script(load("res://scripts/enemies/melee_goblin.gd"))
	root.collision_layer = 4   # enemy_body
	root.collision_mask = 1    # terrain

	var body_col := CollisionShape2D.new()
	body_col.name = "CollisionShape2D"
	var bshape := RectangleShape2D.new(); bshape.size = Vector2(56, 100)
	body_col.shape = bshape
	root.add_child(body_col); body_col.owner = root

	var spr := ColorRect.new()
	spr.name = "Sprite"
	spr.color = Color(0.85, 0.45, 0.15)  # 橙：剑哥布林占位
	spr.size = Vector2(80, 110)
	spr.position = Vector2(-40, -60)
	spr.editor_description = "[物料] 类别=敌人 | 占位=橙块80x110 PH_Enemy_MeleeGoblin | 替换=持剑哥布林 | 备注=追击+挥砍"
	root.add_child(spr); spr.owner = root

	var health := Node.new()
	health.name = "Health"
	health.set_script(load("res://scripts/combat/health.gd"))
	health.set("max_health", 45)
	root.add_child(health); health.owner = root

	var hurt := Area2D.new()
	hurt.name = "Hurtbox"
	hurt.set_script(load("res://scripts/combat/hurtbox.gd"))
	hurt.collision_layer = 64  # enemy_hurtbox
	hurt.collision_mask = 0
	root.add_child(hurt); hurt.owner = root
	hurt.set("health", health)
	hurt.set("invincible_time", 0.0)
	var hurt_col := CollisionShape2D.new()
	hurt_col.name = "CollisionShape2D"
	var hshape := RectangleShape2D.new(); hshape.size = Vector2(56, 100)
	hurt_col.shape = hshape
	hurt.add_child(hurt_col); hurt_col.owner = root

	var hit := Area2D.new()
	hit.name = "MeleeHitbox"
	hit.set_script(load("res://scripts/combat/hitbox.gd"))
	hit.collision_layer = 16   # enemy_hitbox
	hit.collision_mask = 32    # player_hurtbox
	hit.monitorable = false
	hit.set("damage", 12)
	root.add_child(hit); hit.owner = root
	var hit_col := CollisionShape2D.new()
	hit_col.name = "CollisionShape2D"
	var hitshape := RectangleShape2D.new(); hitshape.size = Vector2(70, 80)
	hit_col.shape = hitshape
	hit_col.position = Vector2(50, 0)
	hit.add_child(hit_col); hit_col.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/enemies/melee_goblin.tscn")
	print("[melee_goblin] pack=", perr, " save=", serr)
	quit()
