extends Node
# 跨房间持久化的队伍/进度状态（autoload 名 Game）

var unlocked: Dictionary = {}            # 角色名 -> bool
var hp: Dictionary = {}                  # 角色名 -> int
var vials: int = 2
var abilities: Dictionary = {}           # 能力名 -> bool
var unlocked_bonfires: Array[Vector2] = []
var _initialized: bool = false

## Reset all run-level state and mark this singleton as initialized.
## LAZY-INIT CONTRACT: Game is a process-lifetime singleton (never freed between
## rooms). `apply_party_state()` calls this automatically on first use so a bare
## scene-open "just works." However, any title-screen / restart flow MUST call
## `start_new_game()` explicitly before loading the first room — otherwise hp,
## unlocked flags, and vial counts from the previous run will leak into the new
## one and corrupt the fresh-boot experience (e.g. Archer would start unlocked).
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

## Apply stored run state to a PartyManager. Calls start_new_game() lazily on
## first use (so opening a room directly in the editor always works). See the
## start_new_game() comment for why explicit calls are required on restart.
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
