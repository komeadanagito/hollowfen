extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")

func _initialize() -> void: _run()

func _run() -> void:
	var t := TestHelper.new()
	var ts = load("res://tilesets/dungeon_tileset.tres")
	t.check(ts != null, "tileset 加载成功")
	t.check(ts.get_source_count() >= 3, "至少 3 个图集 source")
	t.eq(ts.get_physics_layers_count(), 1, "有 1 个物理层")
	quit(t.summary("test_tileset"))
