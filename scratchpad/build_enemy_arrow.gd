extends SceneTree

func _initialize() -> void:
	var root := Area2D.new()
	root.name = "EnemyArrow"
	root.set_script(load("res://scripts/combat/arrow.gd"))
	root.collision_layer = 16   # enemy_hitbox
	root.collision_mask = 33    # terrain(1) + player_hurtbox(32)
	root.monitorable = false
	root.set("damage", 8)

	var spr := ColorRect.new()
	spr.name = "Sprite"
	spr.color = Color(0.9, 0.25, 0.2)
	spr.offset_left = -8; spr.offset_top = -2; spr.offset_right = 8; spr.offset_bottom = 2
	root.add_child(spr); spr.owner = root

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 4)
	col.shape = shape
	root.add_child(col); col.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/combat/enemy_arrow.tscn")
	print("[enemy_arrow] pack=", perr, " save=", serr)
	quit()
