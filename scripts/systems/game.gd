extends Node
# 跨房间持久化的队伍/进度状态（autoload 名 Game）

var unlocked: Dictionary = {}            # 角色名 -> bool
var hp: Dictionary = {}                  # 角色名 -> int
var vials: int = 2
var abilities: Dictionary = {}           # 能力名 -> bool
var unlocked_bonfires: Array[Vector2] = []
var _initialized: bool = false

func start_new_game() -> void:
	unlocked.clear()
	hp.clear()
	abilities.clear()
	unlocked_bonfires.clear()
	vials = 2
	_initialized = true

func save_party_state(pm) -> void:
	if pm == null:
		return
	vials = pm.vials
	for c in pm.get_characters():
		var h = c.get_health()
		if h:
			hp[c.name] = h.current
		unlocked[c.name] = pm.is_unlocked(c)

func apply_party_state(pm) -> void:
	if pm == null:
		return
	if not _initialized:
		start_new_game()
	pm.vials = vials
	for c in pm.get_characters():
		if hp.has(c.name) and c.get_health():
			c.get_health().set_current(hp[c.name])
		if unlocked.has(c.name):
			pm.set_unlocked(c, unlocked[c.name])
