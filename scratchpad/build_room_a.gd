extends SceneTree

const KNIGHT  := "res://scenes/characters/knight.tscn"
const ARCHER  := "res://scenes/characters/archer.tscn"
const SLIME   := "res://scenes/enemies/patrol_enemy.tscn"
const SWITCH  := "res://scenes/puzzle/switch.tscn"
const DOOR    := "res://scenes/puzzle/door.tscn"
const PICKUP  := "res://scenes/world/archer_pickup.tscn"
const HUD     := "res://scenes/ui/hud.tscn"
const PORTAL  := "res://scenes/entities/props/room_portal.tscn"

var _root: Node2D
var _font: Font

func _initialize() -> void:
	_root = Node2D.new()
	_root.name = "RoomTutorialA"
	_root.set_script(load("res://scripts/systems/room_base.gd"))
	_font = _tutorial_font()

	# === Background ===
	_tiled("Background", -500, -120, 4000, 1120, "res://assets/scene/background_far.png", -100)

	# === Ceiling ===
	_tiled("Ceiling", -500, 60, 4000, 230, "res://assets/scene/ceiling_stone.png", -40, 2.0)
	for cx in [600, 2400]:
		_deco("Chandelier_%d" % cx, cx, 360, "res://assets/scene/chandelier.png", -38)

	# === Ground: left side with pit in middle ===
	# Left ground: x=-500 to x=2100 (width=2600)
	_solid("PH_Terrain_GroundL", 800, 1000, 2600, 400, "res://assets/scene/floor_stone.png", "Left ground -500~2100", 2.0)
	# Right ground: x=2580 to x=3800 (width=1220)
	_solid("PH_Terrain_GroundR", 3190, 1000, 1220, 400, "res://assets/scene/floor_stone.png", "Right ground 2580~3800", 2.0)
	# Jump platform
	_plat("PH_Terrain_JumpBlock", 1000, 720, 160, 160, "Jump tutorial block")

	# === Death pit (x=2100~2580, width=480) ===
	_death_zone(2340, 1080, 480, 360)

	# === SpawnPoint (default fresh-start spawn) ===
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"; spawn.position = Vector2(200, 740)
	_add(spawn)

	# === PartyManager + Knight + Archer ===
	var pm := Node2D.new()
	pm.name = "PartyManager"
	pm.set_script(load("res://scripts/party/party_manager.gd"))
	_add(pm)
	var knight := _inst(KNIGHT); knight.name = "Knight"; knight.position = Vector2(200, 740)
	pm.add_child(knight); knight.owner = _root
	var archer := _inst(ARCHER); archer.name = "Archer"; archer.position = Vector2(200, 740)
	pm.add_child(archer); archer.owner = _root

	# === Enemy ===
	_enemy(SLIME, "Enemy1", 1500)

	# === Archer pickup (just past the pit) ===
	var pickup := _inst(PICKUP)
	pickup.name = "ArcherPickup"; pickup.position = Vector2(2700, 723)
	pickup.party_manager = pm; pickup.target_character = archer
	_add(pickup)

	# === Switch+Door wall A ===
	_switch("Switch_A", 3500, 460)
	_door("Door_A", 3560)

	# === Portal: "from_b" — where we arrive when coming from room B ===
	# This also serves as the right-end transition trigger to room B
	var portal_right := _inst(PORTAL)
	portal_right.name = "Portal_ToB"
	portal_right.position = Vector2(3700, 700)
	portal_right.entry_id = "from_b"
	portal_right.target_room = "res://scenes/rooms/room_tutorial_b.tscn"
	portal_right.target_entry = "from_a"
	_add(portal_right)

	# === Camera + HUD ===
	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.set_script(load("res://scripts/world/camera_follow.gd"))
	cam.position = Vector2(200, 740); cam.party_manager = pm
	cam.zoom = Vector2(1.5, 1.5)
	cam.limit_left = -500
	cam.limit_right = 3800
	cam.limit_top = 120
	cam.limit_bottom = 1000
	_add(cam)
	var hud := _inst(HUD); hud.name = "HUD"; hud.party_manager = pm; _add(hud)

	# === Labels ===
	_label("L_Move",   240,  600, "A / D  move left/right")
	_label("L_Jump",   900,  560, "Space  jump")
	_label("L_Attack", 1300, 560, "Mouse to attack")
	_label("L_Pit",    2000, 540, "Pit! Knight double-jump crosses")
	_label("L_Ally",   2470, 430, "Ally! Tab to switch")
	_label("L_Switch", 3020, 520, "Aim and shoot arrow")
	_label("L_Wall",   3120, 380, "Wall blocks! Shoot the switch\nit will lower")
	_label("L_ToB",    3550, 540, "Room B ->")

	# === Root exports ===
	_root.party_manager = pm
	_root.default_entry = ""   # falls back to SpawnPoint node

	var packed := PackedScene.new()
	var perr := packed.pack(_root)
	var serr := ResourceSaver.save(packed, "res://scenes/rooms/room_tutorial_a.tscn")
	print("[room_tutorial_a] pack=", perr, " save=", serr, " children=", _root.get_child_count())
	quit()

func _tutorial_font() -> Font:
	for ext in ["ttf", "otf", "ttc"]:
		var p := "res://assets/handdrawn." + str(ext)
		if ResourceLoader.exists(p):
			return load(p)
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Chalkduster", "Hiragino Sans GB", "PingFang SC", "Heiti SC"])
	return sf

func _label(nm: String, x: float, y: float, text: String) -> void:
	var lbl := Label.new()
	lbl.name = nm
	lbl.text = text
	lbl.position = Vector2(x, y)
	lbl.z_index = 10
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	lbl.add_theme_constant_override("outline_size", 10)
	lbl.add_theme_constant_override("line_spacing", 4)
	_add(lbl)

func _enemy(scene: String, nm: String, x: float) -> void:
	var e := _inst(scene); e.name = nm; e.position = Vector2(x, 700); _add(e)

func _death_zone(cx: float, cy: float, w: float, h: float) -> void:
	var a := Area2D.new(); a.name = "DeathZone"
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = Vector2(cx, cy)
	_add(a)
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	a.add_child(c); c.owner = _root

func _add(node: Node) -> void:
	_root.add_child(node); node.owner = _root

func _inst(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()

func _switch(nm: String, x: float, y: float) -> void:
	var s := _inst(SWITCH); s.name = nm; s.position = Vector2(x, y); s.scale = Vector2(2, 2); _add(s)

func _door(nm: String, x: float) -> void:
	var d := _inst(DOOR); d.name = nm; d.position = Vector2(x, 580); d.scale = Vector2(2.5, 6); _add(d)

func _plat(nm: String, cx: float, top: float, w: float, h: float, note: String) -> void:
	_solid(nm, cx, top + h / 2.0, w, h, "res://assets/scene/stone_block.png", note)

func _solid(nm: String, cx: float, cy: float, w: float, h: float, tex: String, note: String, tile_scale: float = 1.0) -> void:
	var body := StaticBody2D.new()
	body.name = nm; body.position = Vector2(cx, cy)
	body.editor_description = "[Terrain] tex=" + tex + " note=" + note
	_add(body)
	var c := CollisionShape2D.new(); c.name = "CollisionShape2D"
	var r := RectangleShape2D.new(); r.size = Vector2(w, h); c.shape = r
	body.add_child(c); c.owner = _root
	var s := Sprite2D.new(); s.name = "Sprite"
	s.texture = load(tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.centered = false
	s.scale = Vector2(tile_scale, tile_scale)
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, w / tile_scale, h / tile_scale)
	s.position = Vector2(-w / 2.0, -h / 2.0)
	body.add_child(s); s.owner = _root

func _tiled(nm: String, x: float, y: float, w: float, h: float, tex: String, z: int, tile_scale: float = 1.0) -> void:
	var s := Sprite2D.new(); s.name = nm
	s.texture = load(tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.centered = false
	s.scale = Vector2(tile_scale, tile_scale)
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, w / tile_scale, h / tile_scale)
	s.position = Vector2(x, y)
	s.z_index = z
	_add(s)

func _deco(nm: String, cx: float, cy: float, tex: String, z: int) -> void:
	var s := Sprite2D.new(); s.name = nm
	s.texture = load(tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = Vector2(cx, cy)
	s.z_index = z
	_add(s)
