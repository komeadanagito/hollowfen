extends SceneTree

func _initialize() -> void:
	_build_door()
	_build_switch()
	_build_exit()
	quit()

func _sprite2d(root: Node, tex_path: String) -> void:
	var s := Sprite2D.new()
	s.name = "Sprite"
	s.texture = load(tex_path)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(s); s.owner = root

func _rect_col(root: Node, w: float, h: float) -> void:
	var c := CollisionShape2D.new()
	c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h)
	c.shape = r
	root.add_child(c); c.owner = root

func _save(root: Node, path: String, label: String) -> void:
	var packed := PackedScene.new()
	var perr := packed.pack(root)
	var serr := ResourceSaver.save(packed, path)
	print("[%s] pack=%d save=%d" % [label, perr, serr])

func _build_door() -> void:
	var root := StaticBody2D.new()
	root.name = "Door"
	root.set_script(load("res://scripts/puzzle/door.gd"))
	root.collision_mask = 0
	_rect_col(root, 24, 80)
	_sprite2d(root, "res://assets/prop/dungeon_door.png")   # 24x80, 与碰撞同尺寸
	_save(root, "res://scenes/puzzle/door.tscn", "door")

func _build_switch() -> void:
	var root := Area2D.new()
	root.name = "Switch"
	root.collision_layer = 128
	root.collision_mask = 0
	root.monitoring = false
	root.set_script(load("res://scripts/puzzle/switch.gd"))
	_sprite2d(root, "res://assets/prop/switch_lever.png")    # 24x24
	_rect_col(root, 24, 24)
	_save(root, "res://scenes/puzzle/switch.tscn", "switch")

func _build_exit() -> void:
	var root := Area2D.new()
	root.name = "LevelExit"
	root.collision_layer = 0
	root.collision_mask = 2
	root.set_script(load("res://scripts/world/level_exit.gd"))
	_rect_col(root, 150, 192)
	_sprite2d(root, "res://assets/prop/level_exit.png")      # 205x192 传送门
	_save(root, "res://scenes/world/level_exit.tscn", "level_exit")
