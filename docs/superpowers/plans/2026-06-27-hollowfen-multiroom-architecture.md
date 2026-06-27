# Hollowfen 多房间架构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把单关教学场景升级为可扩展的互联房间架构：Game/RoomManager 持久化并切换房间，RoomBase/RoomPortal 实现双向门，TileSet 支持编辑器刷地形，并把教学关迁成 room_a ⇄ room_b 两个相连房间。

**Architecture:** 两个 autoload —— `Game`（跨房间持久化队伍状态）+ `RoomManager`（记录入口、切场景）。每个房间根用 `Room`(RoomBase) 脚本：加载时从 Game 恢复队伍、按 `RoomManager.pending_entry` 选入口出生、接线机关/死亡/Portal；`RoomPortal` 既是出口也是入口锚点。地形用 TileMapLayer + 共享 TileSet。

**Tech Stack:** Godot 4.6.2（GL Compatibility, mono build），GDScript，headless `SceneTree` 测试，无 Hastur 时用 `--headless --script` 跑 build 脚本生成 .tscn（见 memory [[headless-class-cache-refresh]]）。

## Global Constraints
- mono Godot：`/Applications/Godot_mono.app/Contents/MacOS/Godot`。
- 碰撞层位值：terrain=1, player_body=2, enemy_body=4, player_hitbox=8, enemy_hitbox=16, player_hurtbox=32, enemy_hurtbox=64, puzzle_target=128。
- 新 class_name 后跑 `Godot --headless --editor --quit-after 200 --path .` 刷新类缓存。
- headless 测试：`extends SceneTree`，`_initialize()`→`_run()`，`add_child` 后 `await process_frame` 等 `_ready`；断言用 `tests/test_helper.gd`。
- 移动文件后立即跑全套 17+ 测试当回归网。
- 渐进式整理：只新增 systems/、rooms/、tilesets/，scripts 主体不挪（仅 camera_follow 移入 systems）。
- autoload 已有 `HasturGameExecutor`；新增 `Game`、`RoomManager` 追加到 `[autoload]`，不要删现有项。

---

## Task 1: PartyManager / Health 公共访问器（为 Game 持久化铺路）

**Files:**
- Modify: `scripts/party/party_manager.gd`
- Modify: `scripts/combat/health.gd`
- Test: `tests/test_party_accessors.gd`

**Interfaces:**
- Produces:
  - `PartyManager.get_characters() -> Array[CharacterBase]`（返回内部角色数组副本）
  - `PartyManager.is_unlocked(c: CharacterBase) -> bool`
  - `PartyManager.set_unlocked(c: CharacterBase, unlocked: bool) -> void`（仅改锁定状态，不发解锁信号）
  - `Health.set_current(value: int) -> void`（clamp 0..max_health 并发 `health_changed`）

- [ ] **Step 1: 写失败测试 `tests/test_party_accessors.gd`**

```gdscript
extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const PM = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	var pm := Node2D.new(); pm.set_script(PM)
	var k := KnightScene.instantiate(); var a := ArcherScene.instantiate()
	pm.add_child(k); pm.add_child(a)
	get_root().add_child(pm)
	await process_frame
	t.eq(pm.get_characters().size(), 2, "get_characters 返回 2")
	pm.set_unlocked(a, false)
	t.check(not pm.is_unlocked(a), "set_unlocked false 生效")
	pm.set_unlocked(a, true)
	t.check(pm.is_unlocked(a), "set_unlocked true 生效")
	var h = k.get_health()
	h.set_current(7)
	t.eq(h.current, 7, "set_current 设置血量")
	h.set_current(9999)
	t.eq(h.current, h.max_health, "set_current clamp 到 max")
	quit(t.summary("test_party_accessors"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_party_accessors.gd`
Expected: FAIL —— `get_characters`/`set_unlocked`/`set_current` 不存在。

- [ ] **Step 3: 给 `health.gd` 加 `set_current`**

在 `health.gd` 任意方法后追加：

```gdscript
func set_current(value: int) -> void:
	current = clampi(value, 0, max_health)
	health_changed.emit(current, max_health)
```

- [ ] **Step 4: 给 `party_manager.gd` 加访问器**

在文件末尾追加：

```gdscript
func get_characters() -> Array[CharacterBase]:
	return _characters.duplicate()

func is_unlocked(character: CharacterBase) -> bool:
	var idx := _characters.find(character)
	return idx != -1 and not _locked[idx]

func set_unlocked(character: CharacterBase, unlocked: bool) -> void:
	var idx := _characters.find(character)
	if idx != -1:
		_locked[idx] = not unlocked
```

- [ ] **Step 5: 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_party_accessors.gd`
Expected: `[test_party_accessors] passed=5 failed=0`

- [ ] **Step 6: 跑 party 回归**

Run: `for s in test_party_manager test_party_unlock; do /Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/$s.gd; done`
Expected: 各 `failed=0`。

- [ ] **Step 7: Commit**

```bash
git add scripts/party/party_manager.gd scripts/combat/health.gd tests/test_party_accessors.gd
git commit -m "feat: add PartyManager/Health accessors for cross-room persistence"
```

---

## Task 2: `Game` autoload（跨房间持久化）

**Files:**
- Create: `scripts/systems/game.gd`
- Modify: `project.godot`（`[autoload]` 追加 `Game`）
- Test: `tests/test_game_state.gd`

**Interfaces:**
- Consumes: `PartyManager.get_characters/is_unlocked/set_unlocked`、`Health.set_current`、`PartyManager.vials`（已有 public var）。
- Produces（autoload 单例 `Game`）：
  - `var unlocked: Dictionary`、`var hp: Dictionary`、`var vials: int`、`var abilities: Dictionary`、`var unlocked_bonfires: Array`
  - `start_new_game() -> void`
  - `save_party_state(pm: PartyManager) -> void`
  - `apply_party_state(pm: PartyManager) -> void`

- [ ] **Step 1: 写失败测试 `tests/test_game_state.gd`**

```gdscript
extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const GameScript = preload("res://scripts/systems/game.gd")
const PM = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")

func _initialize() -> void: _run()

func _make_party():
	var pm := Node2D.new(); pm.set_script(PM)
	pm.add_child(KnightScene.instantiate()); pm.add_child(ArcherScene.instantiate())
	get_root().add_child(pm)
	return pm

func _run() -> void:
	var t := TestHelper.new()
	var game = GameScript.new(); get_root().add_child(game)
	game.start_new_game()
	var pmA = _make_party(); await process_frame
	# A 房间：解锁 archer、knight 残血、用掉一个血瓶
	var kA = pmA.get_characters()[0]; var aA = pmA.get_characters()[1]
	pmA.set_unlocked(aA, true)
	kA.get_health().set_current(13)
	pmA.vials = 1
	game.save_party_state(pmA)
	# B 房间：新队伍，apply 后状态应一致
	var pmB = _make_party(); await process_frame
	game.apply_party_state(pmB)
	var kB = pmB.get_characters()[0]; var aB = pmB.get_characters()[1]
	t.eq(kB.get_health().current, 13, "血量跨房间带过去")
	t.check(pmB.is_unlocked(aB), "解锁状态跨房间带过去")
	t.eq(pmB.vials, 1, "血瓶跨房间带过去")
	quit(t.summary("test_game_state"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_game_state.gd`
Expected: FAIL —— `game.gd` 不存在 / 方法缺失。

- [ ] **Step 3: 写 `scripts/systems/game.gd`**

```gdscript
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
```

- [ ] **Step 4: 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_game_state.gd`
Expected: `[test_game_state] passed=3 failed=0`

- [ ] **Step 5: 注册 autoload**

编辑 `project.godot` 的 `[autoload]` 段，在 `HasturGameExecutor` 行**之后**追加：

```
Game="*res://scripts/systems/game.gd"
```

- [ ] **Step 6: 验证 autoload 加载无错**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_game_state.gd`
Expected: 仍 `passed=3 failed=0`，无 autoload 报错。

- [ ] **Step 7: Commit**

```bash
git add scripts/systems/game.gd project.godot tests/test_game_state.gd
git commit -m "feat: add Game autoload for cross-room party persistence"
```

---

## Task 3: `RoomManager` autoload（入口记录 + 切场景）

**Files:**
- Create: `scripts/systems/room_manager.gd`
- Modify: `project.godot`（`[autoload]` 追加 `RoomManager`）
- Test: `tests/test_room_manager.gd`

**Interfaces:**
- Produces（autoload `RoomManager`）：
  - `var pending_entry: String`
  - `var pending_room: String`
  - `go_to(room_path: String, entry_id: String) -> void`（记录后 `change_scene_to_file`）
  - `consume_entry() -> String`（取出 pending_entry 并清空，供 Room 用）

- [ ] **Step 1: 写失败测试 `tests/test_room_manager.gd`**

```gdscript
extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const RM = preload("res://scripts/systems/room_manager.gd")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	var rm = RM.new(); get_root().add_child(rm)
	# go_to 记录入口与房间（不真正切场景：用 _defer_change=false 直接记录）
	rm.set_change_enabled(false)
	rm.go_to("res://scenes/rooms/room_tutorial_b.tscn", "from_a")
	t.eq(rm.pending_room, "res://scenes/rooms/room_tutorial_b.tscn", "记录目标房间")
	t.eq(rm.consume_entry(), "from_a", "consume_entry 取出入口")
	t.eq(rm.consume_entry(), "", "再次取出为空")
	quit(t.summary("test_room_manager"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_manager.gd`
Expected: FAIL。

- [ ] **Step 3: 写 `scripts/systems/room_manager.gd`**

```gdscript
extends Node
# 房间切换：记录"从哪个入口出生"，再换场景（autoload 名 RoomManager）

var pending_entry: String = ""
var pending_room: String = ""
var _change_enabled: bool = true   # 测试时可关掉，避免真正 change_scene

func set_change_enabled(enabled: bool) -> void:
	_change_enabled = enabled

func go_to(room_path: String, entry_id: String) -> void:
	pending_room = room_path
	pending_entry = entry_id
	if _change_enabled:
		get_tree().change_scene_to_file(room_path)

func consume_entry() -> String:
	var e := pending_entry
	pending_entry = ""
	return e
```

- [ ] **Step 4: 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_manager.gd`
Expected: `[test_room_manager] passed=3 failed=0`

- [ ] **Step 5: 注册 autoload**

`project.godot` `[autoload]` 追加（在 `Game` 之后）：

```
RoomManager="*res://scripts/systems/room_manager.gd"
```

- [ ] **Step 6: 验证**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_manager.gd`
Expected: `passed=3 failed=0`。

- [ ] **Step 7: Commit**

```bash
git add scripts/systems/room_manager.gd project.godot tests/test_room_manager.gd
git commit -m "feat: add RoomManager autoload for room transitions"
```

---

## Task 4: `RoomPortal` 预制体（双向门 + 入口锚点）

**Files:**
- Create: `scripts/systems/room_portal.gd`
- Create: `scenes/entities/props/room_portal.tscn`（build 脚本生成）
- Test: `tests/test_room_portal.gd`

**Interfaces:**
- Consumes: `RoomManager.go_to`、`Game.save_party_state`（通过 Room）、`CharacterBase.is_active()`。
- Produces（`class_name RoomPortal extends Area2D`）：
  - `@export var entry_id: String`、`@export var target_room: String`、`@export var target_entry: String`、`@export var required_ability: String`
  - 激活玩家 body 进入且未触发过 → 调用组 `"room"` 第一个节点的 `depart(target_room, target_entry)`
  - `func get_entry_id() -> String`

- [ ] **Step 1: 写失败测试 `tests/test_room_portal.gd`**

```gdscript
extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const PortalScript = preload("res://scripts/systems/room_portal.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	# 假 Room：记录 depart 调用
	var fake_room := Node.new()
	fake_room.set_script(GDScript.new())
	# 用一个带 depart 的脚本
	var rs := GDScript.new()
	rs.source_code = "extends Node\nvar called := []\nfunc depart(rp, te):\n\tcalled = [rp, te]\n"
	rs.reload()
	fake_room.set_script(rs)
	fake_room.add_to_group("room")
	get_root().add_child(fake_room)

	var portal := Area2D.new(); portal.set_script(PortalScript)
	portal.entry_id = "from_b"; portal.target_room = "res://scenes/rooms/room_tutorial_b.tscn"; portal.target_entry = "from_a"
	get_root().add_child(portal)
	await process_frame
	var knight := KnightScene.instantiate(); get_root().add_child(knight); await process_frame
	knight.set_active(true)
	portal._on_body_entered(knight)
	t.eq(fake_room.called, ["res://scenes/rooms/room_tutorial_b.tscn", "from_a"], "进入 portal 调用 room.depart(目标房,目标入口)")
	t.eq(portal.get_entry_id(), "from_b", "get_entry_id 返回本入口")
	quit(t.summary("test_room_portal"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_portal.gd`
Expected: FAIL。

- [ ] **Step 3: 写 `scripts/systems/room_portal.gd`**

```gdscript
class_name RoomPortal
extends Area2D

@export var entry_id: String = ""
@export var target_room: String = ""
@export var target_entry: String = ""
@export var required_ability: String = ""   # 能力门禁（本期不判定，仅占位）

var _used: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func get_entry_id() -> String:
	return entry_id

func _on_body_entered(body: Node) -> void:
	if _used or target_room == "":
		return
	if not (body is CharacterBase and (body as CharacterBase).is_active()):
		return
	var room := get_tree().get_first_node_in_group("room")
	if room and room.has_method("depart"):
		_used = true
		room.depart(target_room, target_entry)
```

- [ ] **Step 4: 跑测试确认通过（先刷类缓存）**

先 `Godot --headless --editor --quit-after 200 --path .`，再
Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_portal.gd`
Expected: `[test_room_portal] passed=2 failed=0`

- [ ] **Step 5: build 脚本生成 `scenes/entities/props/room_portal.tscn`**

写 `scratchpad/build_room_portal.gd`（`extends SceneTree`）：根 `RoomPortal`(Area2D, script, collision_layer=0, collision_mask=2) → `CollisionShape2D`(RectangleShape2D 96×192) → `Sprite`(Sprite2D, texture `res://assets/prop/level_exit.png`, texture_filter nearest)。`pack`+`ResourceSaver.save("res://scenes/entities/props/room_portal.tscn")`，输出 `pack/save` 应为 0。Run 它生成场景。

- [ ] **Step 6: Commit**

```bash
git add scripts/systems/room_portal.gd scenes/entities/props/room_portal.tscn tests/test_room_portal.gd
git commit -m "feat: add RoomPortal (bidirectional door + entry anchor)"
```

---

## Task 5: `RoomBase`（Room）—— 通用化关卡根

**Files:**
- Create: `scripts/systems/room_base.gd`
- Test: `tests/test_room_base.gd`

**Interfaces:**
- Consumes: `Game.apply_party_state`、`RoomManager.consume_entry`、`RoomManager.go_to`、`Game.save_party_state`、`RoomPortal.get_entry_id`、`PartyManager`、`Switch`/`Door`、`LevelExit`(深坑/DeathZone)。
- Produces（`class_name Room extends Node2D`，在组 `"room"`）：
  - `@export var party_manager: PartyManager`、`@export var default_entry: String`
  - `_ready()`：apply 队伍状态 → 按 `RoomManager.consume_entry()` 找匹配 `RoomPortal` 把队伍放那（找不到用名为 `SpawnPoint` 的 Marker2D 或 default_entry）→ 接线 开关→门/死亡→切角色/全灭→回入口/DeathZone。
  - `func depart(room_path: String, entry_id: String) -> void`：`Game.save_party_state(party_manager)` → `RoomManager.go_to(room_path, entry_id)`
  - `func _entry_position(entry_id: String) -> Vector2`：遍历组内/子节点找 `RoomPortal.get_entry_id()==entry_id` 的位置；无则 SpawnPoint。

- [ ] **Step 1: 写失败测试 `tests/test_room_base.gd`**

```gdscript
extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const RoomScript = preload("res://scripts/systems/room_base.gd")
const PortalScript = preload("res://scripts/systems/room_portal.gd")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	var room := Node2D.new(); room.set_script(RoomScript)
	# 两个入口锚点
	var p1 := Area2D.new(); p1.set_script(PortalScript); p1.entry_id = "from_a"; p1.position = Vector2(300, 700); p1.name = "PortalA"
	var p2 := Area2D.new(); p2.set_script(PortalScript); p2.entry_id = "from_c"; p2.position = Vector2(5000, 700); p2.name = "PortalC"
	room.add_child(p1); room.add_child(p2)
	get_root().add_child(room)
	await process_frame
	t.eq(room._entry_position("from_a"), Vector2(300, 700), "按 entry_id 找到入口位置")
	t.eq(room._entry_position("from_c"), Vector2(5000, 700), "找到另一个入口")
	# depart 会保存状态并请求切换（关掉真正 change）
	RoomManager.set_change_enabled(false)
	room.depart("res://scenes/rooms/room_tutorial_b.tscn", "from_a")
	t.eq(RoomManager.pending_room, "res://scenes/rooms/room_tutorial_b.tscn", "depart 触发 RoomManager.go_to")
	quit(t.summary("test_room_base"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_base.gd`
Expected: FAIL。

- [ ] **Step 3: 写 `scripts/systems/room_base.gd`**

```gdscript
class_name Room
extends Node2D

@export var party_manager: PartyManager
@export var default_entry: String = ""

func _ready() -> void:
	add_to_group("room")
	if party_manager == null:
		party_manager = get_node_or_null("PartyManager") as PartyManager
	if has_node("/root/Game") and party_manager:
		get_node("/root/Game").apply_party_state(party_manager)
	_place_party_at_entry()
	_wire_room()

func depart(room_path: String, entry_id: String) -> void:
	if has_node("/root/Game") and party_manager:
		get_node("/root/Game").save_party_state(party_manager)
	if has_node("/root/RoomManager"):
		get_node("/root/RoomManager").go_to(room_path, entry_id)

func _place_party_at_entry() -> void:
	if party_manager == null:
		return
	var entry := ""
	if has_node("/root/RoomManager"):
		entry = get_node("/root/RoomManager").consume_entry()
	if entry == "":
		entry = default_entry
	var pos := _entry_position(entry)
	var active = party_manager.get_active_character()
	if active:
		active.global_position = pos

func _entry_position(entry_id: String) -> Vector2:
	for portal in _find_portals():
		if portal.get_entry_id() == entry_id:
			return portal.global_position
	var spawn := get_node_or_null("SpawnPoint") as Marker2D
	if spawn:
		return spawn.global_position
	return global_position

func _find_portals() -> Array:
	var out := []
	for child in get_children():
		if child is RoomPortal:
			out.append(child)
	return out

func _wire_room() -> void:
	for suffix in ["A", "B", "C"]:
		var sw := get_node_or_null("Switch_" + suffix) as Switch
		var dr := get_node_or_null("Door_" + suffix) as Door
		if sw and dr and not sw.activated.is_connected(Callable(dr, "open")):
			sw.activated.connect(Callable(dr, "open"))
	if party_manager:
		for child in party_manager.get_children():
			if child is CharacterBase:
				var h := (child as CharacterBase).get_health()
				var cb := _on_died.bind(child as CharacterBase)
				if h and not h.died.is_connected(cb):
					h.died.connect(cb)
		if not party_manager.party_wiped.is_connected(_on_party_wiped):
			party_manager.party_wiped.connect(_on_party_wiped)
	var pit := get_node_or_null("DeathZone") as Area2D
	if pit and not pit.body_entered.is_connected(_on_pit_entered):
		pit.body_entered.connect(_on_pit_entered)

func _on_died(character: CharacterBase) -> void:
	if party_manager:
		party_manager.notify_death(character)

func _on_party_wiped() -> void:
	if party_manager == null:
		return
	party_manager.revive_all()
	var pos := _entry_position(default_entry)
	for child in party_manager.get_children():
		if child is CharacterBase:
			(child as CharacterBase).respawn(pos)
	party_manager.reset_to_first()

func _on_pit_entered(body: Node) -> void:
	if body is CharacterBase and (body as CharacterBase).is_active():
		var h := (body as CharacterBase).get_health()
		if h:
			h.take_damage(99999)
```

- [ ] **Step 4: 刷类缓存 + 跑测试确认通过**

先刷缓存（`--editor --quit-after 200`），再
Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_room_base.gd`
Expected: `[test_room_base] passed=3 failed=0`

- [ ] **Step 5: Commit**

```bash
git add scripts/systems/room_base.gd tests/test_room_base.gd
git commit -m "feat: add Room base (entry spawn + room wiring + depart)"
```

---

## Task 6: 地形 TileSet（编辑器刷地形）

**Files:**
- Create: `tilesets/dungeon_tileset.tres`（build 脚本生成）
- Test: `tests/test_tileset.gd`

**Interfaces:**
- Produces: 一个 `TileSet`，含 3 个 source（floor_stone / stone_block / ceiling_stone），每个 tile 带矩形物理碰撞（terrain 层 1），tile_size 64。供 `TileMapLayer` 用。

- [ ] **Step 1: 写 build 脚本 `scratchpad/build_tileset.gd`**

`extends SceneTree`，`_initialize()`：
```gdscript
func _initialize():
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)   # terrain
	for path in ["res://assets/scene/floor_stone.png", "res://assets/scene/stone_block.png", "res://assets/scene/ceiling_stone.png"]:
		var src := TileSetAtlasSource.new()
		src.texture = load(path)
		src.texture_region_size = Vector2i(64, 64)
		# 256x256 贴图 → 4x4 个 64 tile，全部创建并加碰撞
		for y in range(0, src.texture.get_height() / 64):
			for x in range(0, src.texture.get_width() / 64):
				src.create_tile(Vector2i(x, y))
				var td := src.get_tile_data(Vector2i(x, y), 0)
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-32,-32),Vector2(32,-32),Vector2(32,32),Vector2(-32,32)]))
		ts.add_source(src)
	var err := ResourceSaver.save(ts, "res://tilesets/dungeon_tileset.tres")
	print("[tileset] save=", err, " sources=", ts.get_source_count())
	quit()
```
（API 名以 Godot 4.6 为准；若 `set_collision_polygon_points` 签名不符，改用 `td.set_collision_polygons_count(0,1)` + `td.set_collision_polygon_points(0,0,pts)`。）Run 它生成。

- [ ] **Step 2: 写测试 `tests/test_tileset.gd`**

```gdscript
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
```

- [ ] **Step 3: 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_tileset.gd`
Expected: `[test_tileset] passed=3 failed=0`

- [ ] **Step 4: Commit**

```bash
git add tilesets/dungeon_tileset.tres tests/test_tileset.gd
git commit -m "feat: add dungeon TileSet with collision for editor terrain"
```

---

## Task 7: 迁移 —— room_tutorial_a ⇄ room_tutorial_b

**Files:**
- Create: `scenes/rooms/room_tutorial_a.tscn`、`scenes/rooms/room_tutorial_b.tscn`（build 脚本生成，根用 `Room` 脚本）
- Modify: `project.godot`（主场景设为 room_tutorial_a）
- Test: `tests/test_rooms_integration.gd`

**Interfaces:**
- Consumes: 全部前置（Game/RoomManager/Room/RoomPortal/TileSet/现有预制体）。
- Produces: 两个相连房间；A 末端 `Portal`(entry_id=`from_b`, target=room_b, target_entry=`from_a`)；B 开头 `Portal`(entry_id=`from_a`, target=room_a, target_entry=`from_b`)。

- [ ] **Step 1: 复制并改造现有 level builder 成两个房间 builder**

基于 `scratchpad/build_tutorial_level.gd` 写 `scratchpad/build_room_a.gd` 和 `scratchpad/build_room_b.gd`：根节点改用 `Room` 脚本（`set_script(load("res://scripts/systems/room_base.gd"))`），各含：地面/平台、PartyManager(Knight+Archer)、CameraFollow、HUD、SpawnPoint、敌人/机关、DeathZone、地图文字、各自 `RoomPortal` 实例（A 放右端去 B；B 放左端回 A，并设 `default_entry`）。A 含段1~第一道开关墙；B 含哥布林+第二道开关墙+终点 Portal/LevelExit。`pack`+`save` 到 `scenes/rooms/`。Run 两个 builder，输出 err=0。

- [ ] **Step 2: 写集成测试 `tests/test_rooms_integration.gd`**

```gdscript
extends SceneTree
const TestHelper = preload("res://tests/test_helper.gd")
const RoomA = preload("res://scenes/rooms/room_tutorial_a.tscn")
const RoomB = preload("res://scenes/rooms/room_tutorial_b.tscn")

func _initialize() -> void: _run()
func _run() -> void:
	var t := TestHelper.new()
	Game.start_new_game()
	RoomManager.set_change_enabled(false)
	# 进入 A
	var a = RoomA.instantiate(); get_root().add_child(a); await process_frame; await process_frame
	var pmA = a.party_manager
	t.check(pmA != null, "room_a 有 PartyManager")
	# 在 A 里解锁 archer、knight 残血
	var arc = pmA.get_characters()[1]
	pmA.set_unlocked(arc, true)
	pmA.get_characters()[0].get_health().set_current(11)
	# depart 去 B（保存状态）
	a.depart("res://scenes/rooms/room_tutorial_b.tscn", "from_a")
	a.free()
	# 进入 B：状态应被带过去，且出生在 entry_id=from_a 的 Portal
	var b = RoomB.instantiate(); get_root().add_child(b); await process_frame; await process_frame
	var pmB = b.party_manager
	t.eq(pmB.get_characters()[0].get_health().current, 11, "血量带到 B")
	t.check(pmB.is_unlocked(pmB.get_characters()[1]), "解锁带到 B")
	var entry_pos = b._entry_position("from_a")
	t.eq(pmB.get_active_character().global_position, entry_pos, "在 from_a 入口出生")
	quit(t.summary("test_rooms_integration"))
```

- [ ] **Step 3: 刷类缓存 + 跑集成测试**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_rooms_integration.gd`
Expected: `[test_rooms_integration] passed=4 failed=0`

- [ ] **Step 4: 设主场景**

`project.godot` `application/run/main_scene` 改为 `res://scenes/rooms/room_tutorial_a.tscn`。

- [ ] **Step 5: 房间 3s 运行无错**

写临时脚本加载 room_a 跑 120 物理帧，grep 无 `SCRIPT ERROR`。

- [ ] **Step 6: Commit**

```bash
git add scenes/rooms/ project.godot tests/test_rooms_integration.gd
git commit -m "feat: migrate tutorial into room_a <-> room_b on the room framework"
```

---

## Task 8: 渐进整理 + 全量回归

**Files:**
- Move: `scripts/world/camera_follow.gd` → `scripts/systems/camera_follow.gd`（+ .uid）
- Modify: 引用 camera_follow 的 build 脚本/场景路径

**Interfaces:** 无新接口。

- [ ] **Step 1: 移动 camera_follow 到 systems/**

`git mv scripts/world/camera_follow.gd scripts/systems/camera_follow.gd`（连同 `.uid`）。`class_name CameraFollow` 不变，靠 uid 解析；但 build 脚本里的 `load("res://scripts/world/camera_follow.gd")` 要改成新路径。grep 全仓替换。

- [ ] **Step 2: 刷类缓存 + 跑全套回归**

Run:
```
for s in test_health test_damage_routing test_party_manager test_party_unlock test_party_accessors test_switch_door test_ranged test_prompt_zone test_archer_pickup test_level_exit test_knight_scene test_enemy_scene test_enemy_arrow test_melee_goblin test_ranged_goblin test_hud test_death_switch_floor test_game_state test_room_manager test_room_portal test_room_base test_tileset test_rooms_integration; do /Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/$s.gd; done
```
Expected: 每个 suite `failed=0`。

- [ ] **Step 3: 人工验证（编辑器）**

打开 room_tutorial_a 跑：移动/战斗/切角色/二段跳过坑/射开关开门 → 走到右端 Portal → 进入 room_b，队伍血量/解锁带过去、出生在左端入口；从 B 左端 Portal 走回 A 对应入口。确认在编辑器里能把一个 RoomPortal 预制体拖进房间、刷 TileMap 地形。

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: move camera_follow into systems/; finalize room framework"
```

---

## Self-Review

**Spec coverage：**
- §3 目录结构 → Task 2/3/5(systems/) + Task 7(rooms/) + Task 6(tilesets/) + Task 8(camera 移入)。✅
- §4.1 Game → Task 2（依赖 Task 1 访问器）。✅
- §4.2 RoomManager → Task 3。✅
- §4.3 RoomBase → Task 5。✅
- §4.4 RoomPortal（含 required_ability 占位）→ Task 4。✅
- §5 数据流 → Task 7 集成测试断言往返一致 + 入口出生。✅
- §6 编辑器/TileSet → Task 6 + Task 4/7 预制体。✅
- §7 迁移 2 房间 → Task 7。✅
- §8 测试策略 → 各任务 TDD + Task 7 集成 + Task 8 全回归。✅
- §9 范围（存档/能力门禁判定/地图 UI 不做）→ 未列任务，required_ability 仅占位。✅

**Placeholder scan：** 各 .gd/测试给了完整代码；TileSet/房间 builder 给了节点树+属性+pack/save 模式（与项目既有 build 流程一致，注明 API 以 4.6 为准的回退）。无 TBD。

**Type consistency：**
- `PartyManager.get_characters/is_unlocked/set_unlocked`（Task1）→ Game(Task2)/Room(Task5)/集成(Task7) 一致引用。✅
- `Health.set_current`（Task1）→ Game.apply（Task2）一致。✅
- `RoomManager.go_to/consume_entry/pending_room/set_change_enabled`（Task3）→ Room(Task5)/集成(Task7) 一致。✅
- `RoomPortal.entry_id/get_entry_id/target_room/target_entry`（Task4）→ Room._entry_position(Task5)/集成(Task7) 一致。✅
- `Room.depart`（Task5）→ RoomPortal(Task4 通过组调用) 一致。✅
