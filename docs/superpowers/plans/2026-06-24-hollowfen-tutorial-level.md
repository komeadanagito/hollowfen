# Hollowfen 第一关（教学引导关）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建 Hollowfen 面向真实玩家的第一关 —— 一个 5 段线性教学走廊：教会移动/跳跃/近战 → 中途解锁 Archer → 用「切换+射箭」开门（啊哈时刻）→ 组合房自主切换 → 抵达终点。

**Architecture:** 复用 Phase 0 全部资产（CharacterBase / Knight / Archer / PartyManager / 巡逻敌 / Switch / Door / Health / Hitbox / Hurtbox / 重生）。新增 4 个小部件：教程提示系统（TutorialLayer + PromptZone）、角色解锁（PartyManager 锁定标记 + ArcherPickup）、关卡出口（LevelExit）。新建 `tutorial_level.tscn` 组装全部。逻辑组件走 TDD headless 测试；场景走 Hastur 编程式构建 + 烟测；画面/手感/美术尺寸走构建 + 人工校准检查点。

**Tech Stack:** Godot 4.6.2（GL Compatibility，mono build），GDScript，Hastur Executor 插件（编辑器内建场景/跑脚本），headless `SceneTree` 测试。

## Global Constraints

- Godot 引擎：`4.6`，渲染 `GL Compatibility`（来自 `project.godot` `config/features`）。
- mono Godot 路径：`/Applications/Godot_mono.app/Contents/MacOS/Godot`。
- 输入动作名（只认动作名）：`move_left` / `move_right` / `jump` / `attack` / `switch_character`。
- 碰撞层（位值）：terrain=1, player_body=2, enemy_body=4, player_hitbox=8, enemy_hitbox=16, player_hurtbox=32, enemy_hurtbox=64, puzzle_target=128。
- 占位命名规范：`PH_<类别>_<用途>`（如 `PH_Terrain_Ground`、`PH_Switch_A`、`PH_Door_Main`）。
- 占位 Inspector 注释（`editor_description`）格式：`[物料] 类别=X | 占位=Y | 替换=Z | 备注=W`。
- 基础网格单位：**64 px**。视口：**1920×1080**，stretch `canvas_items` + aspect `keep`。
- 新脚本创建后**必须**触发编辑器 rescan（Hastur 跑 `EditorInterface.get_resource_filesystem().scan()`）并轮询 `.godot/global_script_class_cache.cfg`，否则 headless `--script` 跑测试时 `class_name` 全局不可见（Phase 0 已踩坑）。
- headless 测试模式：`extends SceneTree`，`_initialize()` 调 `_run()`；`add_child()` 后用 `await process_frame` 等 `_ready`（同步不触发）。
- 测试断言用现有 `tests/test_helper.gd`（`TestHelper`：`check/eq/summary`）。

---

## 文件结构总览

**新建脚本：**
- `scripts/ui/tutorial_layer.gd` — `TutorialLayer`（CanvasLayer）：显示/隐藏单行提示，记录已完成 id 不重复。
- `scripts/ui/prompt_zone.gd` — `PromptZone`（Area2D）：激活角色进入 → 请求显示提示；机制完成 → 关闭。
- `scripts/world/archer_pickup.gd` — `ArcherPickup`（Area2D）：触碰 → 调 `PartyManager.unlock`。
- `scripts/world/level_exit.gd` — `LevelExit`（Area2D）：激活角色进入 → 发 `reached` 信号。
- `scripts/world/tutorial_level.gd` — `TutorialLevel`（Node2D）：关卡根，接线开关→门、解锁、出口、死亡重生。

**修改脚本：**
- `scripts/party/party_manager.gd` — 加锁定/解锁支持（`set_locked` / `unlock` / 跳过锁定角色 / `character_unlocked` 信号）。

**新建场景（Hastur 构建）：**
- `scenes/ui/tutorial_layer.tscn`
- `scenes/world/prompt_zone.tscn`
- `scenes/world/archer_pickup.tscn`
- `scenes/world/level_exit.tscn`
- `scenes/tutorial_level.tscn` — 组装关卡。

**修改场景：**
- `scenes/characters/knight.tscn` / `scenes/characters/archer.tscn` — 放大 + 手感参数校准。

**配置：**
- `project.godot` — 加 `[display]` 段；主场景改为 `tutorial_level.tscn`。

**新建测试：**
- `tests/test_party_unlock.gd`、`tests/test_prompt_zone.gd`、`tests/test_archer_pickup.gd`、`tests/test_level_exit.gd`、`tests/test_tutorial_level_scene.gd`。

---

## Task 1: 显示设置 1920×1080

**Files:**
- Modify: `project.godot`（加 `[display]` 段）

**Interfaces:**
- Produces: 视口 1920×1080，stretch `canvas_items`/`keep`。后续场景按此分辨率布局。

- [ ] **Step 1: 用 Hastur 写入 display 设置**

通过 Hastur 跑以下 full-class 脚本（写 ProjectSettings 并存盘）：

```gdscript
extends RefCounted
func execute(executeContext):
    ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
    ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
    ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
    ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
    var err := ProjectSettings.save()
    executeContext.output("save_err", str(err))
```

- [ ] **Step 2: 验证写入**

Run: `grep -A6 "\[display\]" project.godot`
Expected: 含 `viewport_width=1920`、`viewport_height=1080`、`stretch/mode="canvas_items"`、`stretch/aspect="keep"`。

- [ ] **Step 3: Commit**

```bash
git add project.godot
git commit -m "feat: set viewport to 1920x1080 (16:9)"
```

---

## Task 2: PartyManager 锁定/解锁支持

**Files:**
- Modify: `scripts/party/party_manager.gd`
- Test: `tests/test_party_unlock.gd`

**Interfaces:**
- Consumes: `CharacterBase.set_active(bool)`（已存在）。
- Produces:
  - `PartyManager.set_locked(index: int, locked: bool) -> void`
  - `PartyManager.unlock(character: CharacterBase) -> void`
  - `signal character_unlocked(character: CharacterBase)`
  - `switch_to_next()` 跳过锁定角色；`get_active_character()` 不变。
  - 新增 `var _locked: Array[bool]`（与 `_characters` 同序），`_ready` 默认全 `false`。

- [ ] **Step 1: 写失败测试 `tests/test_party_unlock.gd`**

```gdscript
extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const CharScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")
const PartyManagerScript = preload("res://scripts/party/party_manager.gd")

func _initialize() -> void:
    _run()

func _run() -> void:
    var t := TestHelper.new()
    var pm := Node2D.new()
    pm.set_script(PartyManagerScript)
    var knight := CharScene.instantiate()
    var archer := ArcherScene.instantiate()
    pm.add_child(knight)
    pm.add_child(archer)
    get_root().add_child(pm)
    await process_frame

    # 锁定 archer（index 1），切换应跳过它
    pm.set_locked(1, true)
    pm.switch_to_next()
    t.check(pm.get_active_character() == knight, "锁定 archer 后切换仍是 knight")

    # 解锁后可切到 archer
    pm.unlock(archer)
    pm.switch_to_next()
    t.check(pm.get_active_character() == archer, "解锁后能切到 archer")

    var emitted := {"hit": false}
    # 解锁信号
    var pm2 := Node2D.new()
    pm2.set_script(PartyManagerScript)
    var k2 := CharScene.instantiate()
    var a2 := ArcherScene.instantiate()
    pm2.add_child(k2)
    pm2.add_child(a2)
    get_root().add_child(pm2)
    await process_frame
    pm2.set_locked(1, true)
    pm2.character_unlocked.connect(func(c): emitted["hit"] = (c == a2))
    pm2.unlock(a2)
    t.check(emitted["hit"], "unlock 发出 character_unlocked 信号")

    quit(t.summary("test_party_unlock"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_party_unlock.gd`
Expected: FAIL —— `set_locked` / `unlock` / `character_unlocked` 不存在（报错或 FAIL）。

- [ ] **Step 3: 改 `scripts/party/party_manager.gd`**

完整新内容：

```gdscript
class_name PartyManager
extends Node2D

signal character_switched(character: CharacterBase)
signal character_unlocked(character: CharacterBase)

var _characters: Array[CharacterBase] = []
var _locked: Array[bool] = []
var _active_index: int = 0

func _ready() -> void:
    for child in get_children():
        if child is CharacterBase:
            _characters.append(child)
            _locked.append(false)
    for i in _characters.size():
        _characters[i].set_active(i == 0)
    _active_index = 0
    if not _characters.is_empty():
        character_switched.emit(_characters[0])

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("switch_character"):
        switch_to_next()

func get_active_character() -> CharacterBase:
    if _characters.is_empty():
        return null
    return _characters[_active_index]

func set_locked(index: int, locked: bool) -> void:
    if index < 0 or index >= _locked.size():
        return
    _locked[index] = locked

func unlock(character: CharacterBase) -> void:
    var idx := _characters.find(character)
    if idx == -1 or not _locked[idx]:
        return
    _locked[idx] = false
    character_unlocked.emit(character)

func switch_to_next() -> void:
    if _characters.size() < 2:
        return
    var next_index := _next_unlocked_index()
    if next_index == _active_index:
        return
    var old := _characters[_active_index]
    _active_index = next_index
    var new_char := _characters[_active_index]
    new_char.global_position = old.global_position
    new_char.velocity = old.velocity
    old.set_active(false)
    new_char.set_active(true)
    character_switched.emit(new_char)

func _next_unlocked_index() -> int:
    var n := _characters.size()
    for step in range(1, n):
        var i := (_active_index + step) % n
        if not _locked[i]:
            return i
    return _active_index
```

- [ ] **Step 4: rescan + 跑测试确认通过**

先 Hastur rescan（`EditorInterface.get_resource_filesystem().scan()`）并轮询 cache，再：
Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_party_unlock.gd`
Expected: `[test_party_unlock] passed=3 failed=0`

- [ ] **Step 5: 跑 Phase 0 回归（PartyManager 原测试）**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_party_manager.gd`
Expected: 原 8/8 仍通过（锁定数组默认全 false，行为不变）。

- [ ] **Step 6: Commit**

```bash
git add scripts/party/party_manager.gd tests/test_party_unlock.gd
git commit -m "feat: add lock/unlock support to PartyManager"
```

---

## Task 3: 教程提示系统（TutorialLayer + PromptZone）

**Files:**
- Create: `scripts/ui/tutorial_layer.gd`, `scripts/ui/prompt_zone.gd`
- Create: `scenes/ui/tutorial_layer.tscn`, `scenes/world/prompt_zone.tscn`
- Test: `tests/test_prompt_zone.gd`

**Interfaces:**
- Produces:
  - `TutorialLayer.show_prompt(id: String, text: String) -> void` —— 若 id 未完成则显示 text。
  - `TutorialLayer.dismiss(id: String) -> void` —— 隐藏并标记 id 完成，之后再 `show_prompt` 同 id 不显示。
  - `TutorialLayer.is_done(id: String) -> bool`
  - `TutorialLayer.current_text() -> String` —— 当前面板文本（空串=隐藏），供测试。
  - `PromptZone`：导出 `prompt_id: String`、`prompt_text: String`、`tutorial_layer: TutorialLayer`；激活角色 body 进入 → `tutorial_layer.show_prompt(...)`；调用 `complete()` → `tutorial_layer.dismiss(prompt_id)`。
- Consumes: 玩家角色在 `player_body` 层（layer 2）。

- [ ] **Step 1: 写失败测试 `tests/test_prompt_zone.gd`（先测 TutorialLayer 逻辑）**

```gdscript
extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const TutorialLayerScript = preload("res://scripts/ui/tutorial_layer.gd")

func _initialize() -> void:
    _run()

func _run() -> void:
    var t := TestHelper.new()
    var layer := TutorialLayerScript.new()
    var label := Label.new()
    label.name = "Panel"
    var inner := Label.new()
    inner.name = "Text"
    label.add_child(inner)
    layer.add_child(label)
    get_root().add_child(layer)
    await process_frame

    layer.show_prompt("jump", "按 Space 跳跃")
    t.eq(layer.current_text(), "按 Space 跳跃", "show_prompt 显示文本")

    layer.dismiss("jump")
    t.eq(layer.current_text(), "", "dismiss 后隐藏")
    t.check(layer.is_done("jump"), "dismiss 标记完成")

    layer.show_prompt("jump", "按 Space 跳跃")
    t.eq(layer.current_text(), "", "已完成的 id 不再显示")

    quit(t.summary("test_prompt_zone"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_prompt_zone.gd`
Expected: FAIL —— `TutorialLayer` 未定义。

- [ ] **Step 3: 写 `scripts/ui/tutorial_layer.gd`**

```gdscript
class_name TutorialLayer
extends CanvasLayer

var _done: Dictionary = {}
var _current_id: String = ""

@onready var _panel: Control = get_node_or_null("Panel")
@onready var _text: Label = get_node_or_null("Panel/Text")

func _ready() -> void:
    _hide()

func show_prompt(id: String, text: String) -> void:
    if _done.get(id, false):
        return
    _current_id = id
    if _text:
        _text.text = text
    if _panel:
        _panel.visible = true

func dismiss(id: String) -> void:
    _done[id] = true
    if id == _current_id:
        _hide()

func is_done(id: String) -> bool:
    return _done.get(id, false)

func current_text() -> String:
    if _panel and not _panel.visible:
        return ""
    return _text.text if _text else ""

func _hide() -> void:
    _current_id = ""
    if _panel:
        _panel.visible = false
    if _text:
        _text.text = ""
```

- [ ] **Step 4: 写 `scripts/ui/prompt_zone.gd`**

```gdscript
class_name PromptZone
extends Area2D

@export var prompt_id: String = ""
@export var prompt_text: String = ""
@export var tutorial_layer: TutorialLayer

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if tutorial_layer == null:
        return
    if body is CharacterBase and (body as CharacterBase).is_active():
        tutorial_layer.show_prompt(prompt_id, prompt_text)

func complete() -> void:
    if tutorial_layer:
        tutorial_layer.dismiss(prompt_id)
```

- [ ] **Step 5: 给 CharacterBase 加 `is_active()` 查询**

修改 `scripts/characters/character_base.gd`，在 `set_active` 下方加：

```gdscript
func is_active() -> bool:
    return _active
```

- [ ] **Step 6: rescan + 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_prompt_zone.gd`
Expected: `[test_prompt_zone] passed=5 failed=0`

- [ ] **Step 7: Hastur 构建 `scenes/ui/tutorial_layer.tscn`**

节点树：`TutorialLayer`(CanvasLayer, script=tutorial_layer.gd) → `Panel`(PanelContainer, anchor 底部居中, visible=false) → `Text`(Label, 居中, 字号大)。用 Hastur full-class 脚本创建节点、`set owner`、`PackedScene.pack` + `ResourceSaver.save("res://scenes/ui/tutorial_layer.tscn")`，输出 `pack_err`/`save_err` 应为 0。

- [ ] **Step 8: Hastur 构建 `scenes/world/prompt_zone.tscn`**

节点树：`PromptZone`(Area2D, script, collision_mask=2 只测玩家 body) → `CollisionShape2D`(RectangleShape2D, 如 200×400)。pack+save 到 `res://scenes/world/prompt_zone.tscn`，err=0。

- [ ] **Step 9: Commit**

```bash
git add scripts/ui/tutorial_layer.gd scripts/ui/prompt_zone.gd scripts/characters/character_base.gd scenes/ui/tutorial_layer.tscn scenes/world/prompt_zone.tscn tests/test_prompt_zone.gd
git commit -m "feat: add tutorial prompt system (TutorialLayer + PromptZone)"
```

---

## Task 4: ArcherPickup（解锁点）

**Files:**
- Create: `scripts/world/archer_pickup.gd`, `scenes/world/archer_pickup.tscn`
- Test: `tests/test_archer_pickup.gd`

**Interfaces:**
- Produces: `ArcherPickup`（Area2D）：导出 `party_manager: PartyManager`、`target_character: CharacterBase`、`signal picked_up`；任意玩家 body 进入且未触发 → 调 `party_manager.unlock(target_character)`、发 `picked_up`、`queue_free` 视觉（或隐藏 Sprite）、自身只触发一次。
- Consumes: `PartyManager.unlock(CharacterBase)`（Task 2）。

- [ ] **Step 1: 写失败测试 `tests/test_archer_pickup.gd`**

```gdscript
extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const PickupScript = preload("res://scripts/world/archer_pickup.gd")
const PartyManagerScript = preload("res://scripts/party/party_manager.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")
const ArcherScene = preload("res://scenes/characters/archer.tscn")

func _initialize() -> void:
    _run()

func _run() -> void:
    var t := TestHelper.new()
    var pm := Node2D.new()
    pm.set_script(PartyManagerScript)
    var knight := KnightScene.instantiate()
    var archer := ArcherScene.instantiate()
    pm.add_child(knight)
    pm.add_child(archer)
    get_root().add_child(pm)
    await process_frame
    pm.set_locked(1, true)

    var pickup := Area2D.new()
    pickup.set_script(PickupScript)
    pickup.party_manager = pm
    pickup.target_character = archer
    var picked := {"hit": false}
    pickup.picked_up.connect(func(): picked["hit"] = true)
    get_root().add_child(pickup)
    await process_frame

    # 直接调用进入逻辑（模拟 body_entered）
    pickup._on_body_entered(knight)
    pm.switch_to_next()
    t.check(pm.get_active_character() == archer, "触碰后 archer 解锁可切")
    t.check(picked["hit"], "发出 picked_up 信号")

    quit(t.summary("test_archer_pickup"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_archer_pickup.gd`
Expected: FAIL —— 脚本/方法不存在。

- [ ] **Step 3: 写 `scripts/world/archer_pickup.gd`**

```gdscript
class_name ArcherPickup
extends Area2D

signal picked_up

@export var party_manager: PartyManager
@export var target_character: CharacterBase

var _used: bool = false

@onready var _sprite: Node = get_node_or_null("Sprite")

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if _used or party_manager == null or target_character == null:
        return
    if not (body is CharacterBase):
        return
    _used = true
    party_manager.unlock(target_character)
    picked_up.emit()
    if _sprite and _sprite is CanvasItem:
        (_sprite as CanvasItem).visible = false
```

- [ ] **Step 4: rescan + 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_archer_pickup.gd`
Expected: `[test_archer_pickup] passed=2 failed=0`

- [ ] **Step 5: Hastur 构建 `scenes/world/archer_pickup.tscn`**

节点树：`ArcherPickup`(Area2D, script, collision_mask=2) → `CollisionShape2D`(RectangleShape2D 64×128) → `Sprite`(ColorRect 64×128 绿色微光，`editor_description`=`[物料] 类别=解锁点 | 占位=绿块64×128 | 替换=沉睡同伴/祭坛 | 备注=触碰解锁Archer`，命名 `PH_Pickup_Archer`)。pack+save，err=0。

- [ ] **Step 6: Commit**

```bash
git add scripts/world/archer_pickup.gd scenes/world/archer_pickup.tscn tests/test_archer_pickup.gd
git commit -m "feat: add ArcherPickup unlock point"
```

---

## Task 5: LevelExit（关卡出口）

**Files:**
- Create: `scripts/world/level_exit.gd`, `scenes/world/level_exit.tscn`
- Test: `tests/test_level_exit.gd`

**Interfaces:**
- Produces: `LevelExit`（Area2D）：`signal reached`；激活玩家 body 进入 → 发 `reached`（只一次）。
- Consumes: `CharacterBase.is_active()`（Task 3 Step 5）。

- [ ] **Step 1: 写失败测试 `tests/test_level_exit.gd`**

```gdscript
extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const ExitScript = preload("res://scripts/world/level_exit.gd")
const KnightScene = preload("res://scenes/characters/knight.tscn")

func _initialize() -> void:
    _run()

func _run() -> void:
    var t := TestHelper.new()
    var knight := KnightScene.instantiate()
    get_root().add_child(knight)
    await process_frame
    knight.set_active(true)

    var exit := Area2D.new()
    exit.set_script(ExitScript)
    var reached := {"count": 0}
    exit.reached.connect(func(): reached["count"] += 1)
    get_root().add_child(exit)
    await process_frame

    exit._on_body_entered(knight)
    exit._on_body_entered(knight)
    t.eq(reached["count"], 1, "出口只触发一次")

    quit(t.summary("test_level_exit"))
```

- [ ] **Step 2: 跑测试确认失败**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_level_exit.gd`
Expected: FAIL —— 脚本不存在。

- [ ] **Step 3: 写 `scripts/world/level_exit.gd`**

```gdscript
class_name LevelExit
extends Area2D

signal reached

var _reached: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if _reached:
        return
    if body is CharacterBase and (body as CharacterBase).is_active():
        _reached = true
        reached.emit()
```

- [ ] **Step 4: rescan + 跑测试确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_level_exit.gd`
Expected: `[test_level_exit] passed=1 failed=0`

- [ ] **Step 5: Hastur 构建 `scenes/world/level_exit.tscn`**

节点树：`LevelExit`(Area2D, script, collision_mask=2) → `CollisionShape2D`(RectangleShape2D 96×192) → `Sprite`(ColorRect 96×192 蓝光，命名 `PH_Exit_Gate`，`editor_description`=`[物料] 类别=出口 | 占位=蓝块96×192 | 替换=关卡门/传送 | 备注=关卡终点`)。pack+save，err=0。

- [ ] **Step 6: Commit**

```bash
git add scripts/world/level_exit.gd scenes/world/level_exit.tscn tests/test_level_exit.gd
git commit -m "feat: add LevelExit"
```

---

## Task 6: 角色放大 + 手感校准

**Files:**
- Modify: `scenes/characters/knight.tscn`, `scenes/characters/archer.tscn`（Hastur 改属性后重存）

**Interfaces:**
- Produces: 放大后的 Knight/Archer，碰撞盒与视觉匹配，移动/跳跃手感按新尺度重调。下游 `tutorial_level.tscn` 按此尺寸布局。
- 说明：源精灵帧 256×256（方形，角色居中）。当前 Knight Sprite `scale=0.22`→视觉约 56px。目标视觉高度约 **140px**。

**起始数值（校准用，可在检查点微调）：**
- Knight：Sprite `scale=0.55`（256×0.55≈141px）；`CollisionShape2D` 与 `Hurtbox/CollisionShape2D` size `Vector2(56, 120)`；`MeleeHitbox/CollisionShape2D` position `Vector2(54, 0)`、size `Vector2(60, 90)`。
- Archer：Sprite `scale=0.58`；碰撞 size `Vector2(48, 120)`；`Muzzle` position 按比例放大到 `Vector2(45, -10)`。
- CharacterBase 手感（`character_base.gd` 默认值，按尺度 ×2.5）：`move_speed=550`、`acceleration=4500`、`friction=5000`、`jump_velocity=-1075`、`gravity=3000`、`knockback_force=625`。Knight 场景覆盖 `move_speed=450`，Archer 覆盖 `move_speed=650`。
- 巡逻敌 `patrol_enemy.gd`/场景 `gravity` 同步调到 3000，`speed` ×2.5≈175，碰撞与 Sprite 放大到约 80×80。

- [ ] **Step 1: 改 `scripts/characters/character_base.gd` 手感默认值**

把 `@export` 默认值改为上面的新尺度值（`move_speed=550`、`acceleration=4500`、`friction=5000`、`jump_velocity=-1075`、`gravity=3000`、`knockback_force=625`）。其余逻辑不变。

- [ ] **Step 2: 跑全部逻辑回归测试确认未破坏**

Run:
```
for s in test_health test_damage_routing test_party_manager test_party_unlock test_switch_door test_ranged test_prompt_zone test_archer_pickup test_level_exit; do /Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/$s.gd; done
```
Expected: 每个 suite `failed=0`（手感数值不影响逻辑断言）。

- [ ] **Step 3: Hastur 改 Knight/Archer 场景尺寸**

用 Hastur full-class 脚本：`load` 各 `.tscn` → `instantiate()` → 改 Sprite `scale`、各 `CollisionShape2D.shape.size`、`MeleeHitbox`/`Muzzle` position、敌人 speed/gravity/尺寸 → `PackedScene.pack` 重存。输出各 `save_err` 应为 0。同时给 Knight/Archer 的 Sprite 加 `editor_description` 物料注释。

- [ ] **Step 4: Hastur 改巡逻敌场景与脚本默认 gravity/speed/尺寸**，重存，`save_err=0`。

- [ ] **Step 5: 跑场景烟测回归**

Run:
```
for s in test_knight_scene test_enemy_scene; do /Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/$s.gd; done
```
Expected: 各 `failed=0`（节点路径/接线未变）。

- [ ] **Step 6: 人工校准检查点（CHECKPOINT —— 暂停等开发者确认）**

把主场景临时设为 `test_room.tscn`，开发者在编辑器里跑一次，观察：角色大小是否合适、跳跃高度/横向速度手感是否顺、碰撞盒是否贴合。记录要调的数值。**这是人工验证点，不通过不进入 Task 7。** 如需微调，回到 Step 1/Step 3 改值重测。

- [ ] **Step 7: Commit**

```bash
git add scripts/characters/character_base.gd scripts/enemies/patrol_enemy.gd scenes/characters/knight.tscn scenes/characters/archer.tscn scenes/enemies/patrol_enemy.tscn
git commit -m "feat: scale up characters and recalibrate movement feel"
```

---

## Task 7: 组装教学关 `tutorial_level.tscn`

**Files:**
- Create: `scripts/world/tutorial_level.gd`
- Create: `scenes/tutorial_level.tscn`（Hastur 构建）
- Modify: `project.godot`（主场景）
- Test: `tests/test_tutorial_level_scene.gd`

**Interfaces:**
- Consumes: PartyManager(含锁定)、Knight/Archer、PatrolEnemy、Switch、Door、CameraFollow、HUD、TutorialLayer、PromptZone、ArcherPickup、LevelExit。
- Produces: 可玩教学关；`TutorialLevel` 接线：开局锁定 Archer、Switch→Door、Pickup→（信号驱动提示/解锁已在部件内）、各角色死亡→就近重生、LevelExit→打印完成。

**关卡坐标（64px 网格，地面顶面 y=800）：**

| 段 | 元素 | 坐标 (x, y) |
|----|------|------------|
| 全局 | SpawnPoint | (200, 700) |
| 1 | PromptZone 移动 (id=`move`) | (350, 650) |
| 1 | 台阶/矮平台 | (1000, 760) |
| 1 | PromptZone 跳跃 (id=`jump`) | (950, 650) |
| 2 | Respawn #2（SpawnPoint 复用或第二点） | (1800, 700) |
| 2 | PatrolEnemy `e` | (2400, 720) |
| 2 | PromptZone 攻击 (id=`attack`) | (2200, 650) |
| 解锁 | Door `PH_Door_Main` | (3600, 700) |
| 解锁 | Switch `PH_Switch_A`（高处） | (3650, 360) |
| 解锁 | ArcherPickup | (3300, 720) |
| 3 | PromptZone 切换 (id=`switch`) | (3350, 600) |
| 3 | PromptZone 射箭 (id=`shoot`) | (3450, 600) |
| 4 | PatrolEnemy `E2` | (4600, 720) |
| 4 | Switch `PH_Switch_B`（高处） | (5200, 360) |
| 4 | Door 第二道 | (5400, 700) |
| 5 | LevelExit | (6300, 700) |
| 地形 | Ground 长条 | x 0→6600, 顶面 y=800 |

> 提示完成的接线（实现时在 `tutorial_level.gd` 里连）：跳跃 PromptZone 在玩家首次 `jump` 后 `complete()`；攻击在首次 `attack` 后；切换监听 `PartyManager.character_switched`；射箭监听 Archer 攻击。最简做法：用 `Input.is_action_just_pressed` 在 `_process` 里检测并对未完成的提示调用 `complete()`（见 Step 3 代码）。

- [ ] **Step 1: 写 `scripts/world/tutorial_level.gd`**

```gdscript
class_name TutorialLevel
extends Node2D

@export var party_manager: PartyManager
@export var tutorial_layer: TutorialLayer

@onready var _spawn: Marker2D = $SpawnPoint

func _ready() -> void:
    _lock_archer()
    _wire_switch_door("Switch_A", "Door_Main")
    _wire_switch_door("Switch_B", "Door_B")
    _wire_deaths()
    _wire_exit()

func _lock_archer() -> void:
    if party_manager == null:
        party_manager = get_node_or_null("PartyManager") as PartyManager
    if party_manager:
        party_manager.set_locked(1, true)  # index 1 = Archer

func _wire_switch_door(switch_name: String, door_name: String) -> void:
    var sw := get_node_or_null(switch_name) as Switch
    var dr := get_node_or_null(door_name) as Door
    if sw and dr and not sw.activated.is_connected(Callable(dr, "open")):
        sw.activated.connect(Callable(dr, "open"))

func _wire_deaths() -> void:
    if party_manager == null:
        return
    for child in party_manager.get_children():
        if child is CharacterBase:
            var h := (child as CharacterBase).get_health()
            if h and not h.died.is_connected(_on_died.bind(child as CharacterBase)):
                h.died.connect(_on_died.bind(child as CharacterBase))

func _on_died(character: CharacterBase) -> void:
    if _spawn and is_instance_valid(character):
        character.respawn(_spawn.global_position)

func _wire_exit() -> void:
    var ex := get_node_or_null("LevelExit") as LevelExit
    if ex:
        ex.reached.connect(_on_exit_reached)

func _on_exit_reached() -> void:
    print("[TutorialLevel] 关卡完成！")

func _process(_delta: float) -> void:
    _check_prompt_progress()

func _check_prompt_progress() -> void:
    if tutorial_layer == null:
        return
    if Input.is_action_just_pressed("jump"):
        _complete_zone("jump")
    if Input.is_action_just_pressed("attack"):
        _complete_zone("attack")
        _complete_zone("shoot")
    if Input.is_action_just_pressed("switch_character"):
        _complete_zone("switch")
    if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
        _complete_zone("move")

func _complete_zone(id: String) -> void:
    tutorial_layer.dismiss(id)
```

- [ ] **Step 2: rescan**（让 `TutorialLevel` class 全局可见）。

- [ ] **Step 3: Hastur 构建 `scenes/tutorial_level.tscn`**

用 Hastur full-class builder（参考 Phase 0 test_room 构建方式）。根 `TutorialLevel`(Node2D, script)。按上表实例化/创建：
- `Ground`(StaticBody2D + CollisionShape2D，长 6600×64，顶面 y=800，命名 `PH_Terrain_Ground` + 物料注释) + 台阶平台。
- `SpawnPoint`(Marker2D, (200,700))。
- `PartyManager`(实例化逻辑：内含 `Knight`+`Archer` 两个实例，按位置放 (200,700))。
- `PatrolEnemy` ×2（实例化 `patrol_enemy.tscn`，位置 e/E2）。
- `Switch_A`/`Switch_B`（实例化 `switch.tscn`，命名加 `PH_Switch_A/B` + 物料注释，高处）。
- `Door_Main`/`Door_B`（实例化 `door.tscn`，命名 `PH_Door_Main`/`Door_B`）。
- `ArcherPickup`(实例化)、`LevelExit`(实例化)。
- `PromptZone` ×5（实例化 `prompt_zone.tscn`，设 `prompt_id`/`prompt_text`/`tutorial_layer` NodePath）。
- `CameraFollow`(设 `party_manager`)、`HUD`(实例化，设 `party_manager`)、`TutorialLayer`(实例化)。
- 设根 `TutorialLevel.party_manager` 与 `tutorial_layer` 导出引用（NodePath）。

提示文本：`move`=「← → 移动」，`jump`=「Space 跳跃」，`attack`=「J 攻击」，`switch`=「Shift/Tab 切换角色」，`shoot`=「J 射箭」。

`PackedScene.pack(root)` + `ResourceSaver.save("res://scenes/tutorial_level.tscn")`，输出 `pack_err`/`save_err` 应为 0。

- [ ] **Step 4: 写场景烟测 `tests/test_tutorial_level_scene.gd`**

```gdscript
extends SceneTree

const TestHelper = preload("res://tests/test_helper.gd")
const Scene = preload("res://scenes/tutorial_level.tscn")

func _initialize() -> void:
    _run()

func _run() -> void:
    var t := TestHelper.new()
    var root := Scene.instantiate()
    get_root().add_child(root)
    await process_frame
    await process_frame

    var pm := root.get_node_or_null("PartyManager")
    t.check(pm != null, "PartyManager 存在")
    t.check(root.get_node_or_null("SpawnPoint") != null, "SpawnPoint 存在")
    t.check(root.get_node_or_null("Door_Main") != null, "Door_Main 存在")
    t.check(root.get_node_or_null("Switch_A") != null, "Switch_A 存在")
    t.check(root.get_node_or_null("ArcherPickup") != null, "ArcherPickup 存在")
    t.check(root.get_node_or_null("LevelExit") != null, "LevelExit 存在")
    t.check(root.get_node_or_null("TutorialLayer") != null, "TutorialLayer 存在")
    # 开局 Archer 锁定：连续切换应回到 Knight（仅 1 个解锁角色）
    var first := pm.get_active_character()
    pm.switch_to_next()
    t.check(pm.get_active_character() == first, "开局 Archer 锁定，切换无效")

    quit(t.summary("test_tutorial_level_scene"))
```

- [ ] **Step 5: rescan + 跑烟测确认通过**

Run: `/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/test_tutorial_level_scene.gd`
Expected: `[test_tutorial_level_scene] passed=8 failed=0`

- [ ] **Step 6: 设主场景为 tutorial_level**

Hastur：`ProjectSettings.set_setting("application/run/main_scene", "res://scenes/tutorial_level.tscn")` + `ProjectSettings.save()`，`save_err=0`。

- [ ] **Step 7: Commit**

```bash
git add scripts/world/tutorial_level.gd scenes/tutorial_level.tscn tests/test_tutorial_level_scene.gd project.godot
git commit -m "feat: assemble tutorial level scene"
```

---

## Task 8: 整体集成验证（人工）

**Files:** 无（验证 only）

- [ ] **Step 1: 跑全部回归测试**

Run:
```
for s in test_health test_damage_routing test_party_manager test_party_unlock test_switch_door test_ranged test_prompt_zone test_archer_pickup test_level_exit test_knight_scene test_enemy_scene test_tutorial_level_scene; do /Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path . --script tests/$s.gd; done
```
Expected: 全部 suite `failed=0`。

- [ ] **Step 2: 人工游玩检查清单（开发者在编辑器跑 `tutorial_level.tscn`）**

逐项确认：
1. 出生后「移动」提示出现，移动后消失。
2. 跳跃提示出现，跳过台阶后消失；跳跃手感顺（土狼/缓冲生效）。
3. 走到敌人，「攻击」提示出现，Knight 砍死敌人；碰敌人会掉血。
4. 死亡后在就近 SpawnPoint 满血重生。
5. 走到门前过不去；开关在高处，Knight 跳不到/砍不到。
6. 触碰 ArcherPickup → Archer 解锁；「切换」提示出现。
7. 切到 Archer → 「射箭」提示 → 射中高处开关 → 门开。
8. 组合房（段4）无提示，能自主来回切换通过第二道门。
9. 抵达 LevelExit → 控制台打印「关卡完成！」。
10. HUD 正确显示当前角色与各自独立 HP（切换后 HP 各自保留）。

- [ ] **Step 3: 记录手感/数值微调项**，如需调整回 Task 6 相应步骤；否则完成。

---

## Self-Review

**Spec coverage（对照 spec 各节）：**
- §1 目标/4 项核心决策 → Task 2（解锁）、Task 3（提示）、Task 7（低风险重生接线）、全局纸面→已转为实现。✅
- §2 教学弧线 5 段 + 可选残血点 → Task 7 坐标表覆盖 5 段；可选残血点列为 Task 8 观察项（非强制）。✅
- §3 画面 1920×1080/64网格/角色放大 → Task 1 + Task 6。✅
- §4 占位+物料注释规范 → Task 4/5/6/7 各 Hastur 步骤含 `PH_` 命名 + `editor_description`。✅
- §5 空间布局 → Task 7 坐标表。✅
- §6 新部件（提示/解锁/出口/显示） → Task 1/2/3/4/5。✅
- §7 物料清单 → 占位注释贯穿；总账在 spec。✅
- §9 完成判定 → Task 8 检查清单 1–10。✅

**Placeholder scan：** 各脚本步骤含完整代码；Hastur 构建步骤描述了节点树/属性/坐标（与 Phase 0 同等粒度，构建脚本按既定 Hastur 模式编写）。无 TBD/TODO。

**Type consistency：**
- `PartyManager`：`set_locked(int,bool)`、`unlock(CharacterBase)`、`character_unlocked` —— Task 2 定义，Task 4/7 一致引用。✅
- `TutorialLayer`：`show_prompt(id,text)`/`dismiss(id)`/`is_done(id)`/`current_text()` —— Task 3 定义，Task 7 `_complete_zone` 调 `dismiss`。✅
- `CharacterBase.is_active()` —— Task 3 Step 5 加，Task 5/3 引用。✅
- `LevelExit.reached`、`ArcherPickup.picked_up`/`party_manager`/`target_character` —— 定义与引用一致。✅
- 锁定索引约定：Archer = index 1（PartyManager 按子节点顺序，Knight 先 Archer 后）—— Task 2 测试、Task 7 `_lock_archer` 一致。✅
