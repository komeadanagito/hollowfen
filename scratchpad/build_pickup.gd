extends SceneTree

func _initialize() -> void:
	var root := Area2D.new()
	root.name = "ArcherPickup"
	root.set_script(load("res://scripts/world/archer_pickup.gd"))
	root.collision_layer = 0
	root.collision_mask = 2

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 128)
	col.shape = shape
	root.add_child(col)
	col.owner = root

	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = Color(0.4, 1.0, 0.5)
	sprite.size = Vector2(64, 128)
	sprite.position = Vector2(-32, -64)
	sprite.editor_description = "[物料] 类别=解锁点 | 占位=绿块64x128 PH_Pickup_Archer | 替换=沉睡同伴/祭坛 | 备注=触碰解锁Archer"
	root.add_child(sprite)
	sprite.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/world/archer_pickup.tscn")
	print("[archer_pickup] pack=", perr, " save=", serr)
	quit()
