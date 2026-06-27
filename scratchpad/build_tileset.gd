extends SceneTree

func _initialize() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)   # terrain layer 1

	var paths := [
		"res://assets/scene/floor_stone.png",
		"res://assets/scene/stone_block.png",
		"res://assets/scene/ceiling_stone.png"
	]

	for path in paths:
		var tex = load(path)
		if tex == null:
			print("[tileset] ERROR: could not load ", path)
			quit(1)
			return

		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = Vector2i(64, 64)

		var cols: int = tex.get_width() / 64
		var rows: int = tex.get_height() / 64
		print("[tileset] source ", path, " -> ", cols, "x", rows, " tiles")

		# Create tiles first (without collision — TileData doesn't know about physics layers yet)
		for y in range(rows):
			for x in range(cols):
				src.create_tile(Vector2i(x, y))

		# Add source to TileSet BEFORE setting collision data
		# so TileData inherits the physics layer info from the parent TileSet
		var src_id: int = ts.add_source(src)

		# Now set collision polygons (TileData is now connected to the TileSet)
		for y in range(rows):
			for x in range(cols):
				var coord := Vector2i(x, y)
				var td := src.get_tile_data(coord, 0)
				if td == null:
					print("[tileset] WARNING: get_tile_data returned null for ", coord)
					continue

				var pts := PackedVector2Array([
					Vector2(-32, -32),
					Vector2(32, -32),
					Vector2(32, 32),
					Vector2(-32, 32)
				])
				# Set polygon count on layer 0, then set the points
				td.set_collision_polygons_count(0, 1)
				td.set_collision_polygon_points(0, 0, pts)

		print("[tileset] source added, id=", src_id)

	var err := ResourceSaver.save(ts, "res://tilesets/dungeon_tileset.tres")
	print("[tileset] save=", err, " sources=", ts.get_source_count())
	quit(0)
