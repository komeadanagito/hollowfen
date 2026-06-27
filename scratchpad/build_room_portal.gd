extends SceneTree

func _initialize() -> void:
	var root := Area2D.new()
	root.name = "RoomPortal"
	root.set_script(load("res://scripts/systems/room_portal.gd"))
	root.collision_layer = 0
	root.collision_mask = 2

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(96, 192)
	col.shape = shape
	root.add_child(col); col.owner = root

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load("res://assets/prop/level_exit.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sprite); sprite.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/entities/props/room_portal.tscn")
	print("[room_portal] pack=", perr, " save=", serr)
	quit()
