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
	shape.size = Vector2(160, 230)
	col.shape = shape
	root.add_child(col); col.owner = root

	# 伙伴立绘（透明全身）作为拾取视觉
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = load("res://assets/archer_portrait.png")
	sprite.scale = Vector2(0.224, 0.224)   # 1024px -> ~230px 高
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.editor_description = "[物料] 类别=解锁点 | 占位/素材=Archer立绘 | 备注=触碰获得Archer"
	root.add_child(sprite); sprite.owner = root

	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, "res://scenes/world/archer_pickup.tscn")
	print("[archer_pickup] pack=", perr, " save=", serr)
	quit()
