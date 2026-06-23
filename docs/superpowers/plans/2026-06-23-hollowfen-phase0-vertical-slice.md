# Hollowfen 阶段 0：垂直切片 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 做出一个能玩的测试房间：用近战角色 Knight 砍敌人，切换成远程角色 Archer 射开关开门，走到终点——验证「切换角色打怪+解谜」的核心乐趣。

**Architecture:** 方案 A（附身/管理器模型）。每个角色是独立的 `CharacterBody2D` 场景，自带移动（枚举状态机）、战斗（Health + Hitbox/Hurtbox）。`PartyManager` 持有角色、只激活其一、转发输入、交接位置。战斗与解谜统一用 `receive_hit(damage)` 接口：Hitbox 命中任何带 `receive_hit` 的 Area2D（敌人受击盒或开关）即生效。开关→门用信号松耦合连接。

**Tech Stack:** Godot 4.6.2（GL Compatibility），GDScript。自动化逻辑测试用 headless 脚本：`/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path <项目> --script res://tests/xxx.gd`。手感/整体流程用「运行游戏并观察」。

---

## 约定与命名（贯穿全程，务必一致）

**Godot 可执行文件**（环境已确认）：
```
/Applications/Godot_mono.app/Contents/MacOS/Godot
```
项目路径：`/Users/quan/MyFile/GameProject/hollowfen`

> 说明：编辑器可能正开着同一项目。headless 跑 `--script` 一般不冲突；若报导入/锁冲突，先关闭编辑器再跑测试。

**碰撞层（Project Settings → Layer Names → 2D Physics，按编号命名）：**
| 编号 | 名称 | 用途 |
|------|------|------|
| 1 | `terrain` | 地形（地板/墙/平台） |
| 2 | `player_body` | 玩家角色身体 |
| 3 | `enemy_body` | 敌人身体 |
| 4 | `player_hitbox` | 玩家攻击/箭矢的命中盒 |
| 5 | `enemy_hitbox` | 敌人攻击命中盒 |
| 6 | `player_hurtbox` | 玩家受击盒 |
| 7 | `enemy_hurtbox` | 敌人受击盒 |
| 8 | `puzzle_target` | 可被命中的机关（开关） |

**输入动作（Input Map）名：** `move_left`、`move_right`、`jump`、`attack`、`switch_character`。

**统一伤害接口：** 任何「能被打到」的 Area2D 都实现 `func receive_hit(damage: int) -> void`。`Hitbox` 命中时调用 `area.receive_hit(damage)`（先 `has_method` 检查）。`Hurtbox` 和 `Switch` 都实现它。

**关键 API 契约（后续任务必须沿用这些名字）：**
- `Health`（extends Node）：`@export max_health:int`；属性 `current:int`；`signal health_changed(current:int, maximum:int)`；`signal died`；`take_damage(amount:int)->void`；`reset()->void`；`is_dead()->bool`。
- `Hurtbox`（extends Area2D）：`@export var health: Health`；`receive_hit(damage:int)->void`（转发给 health）。
- `Hitbox`（extends Area2D）：`@export var damage:int`；`set_active(on:bool)->void`；命中带 `receive_hit` 的 area 即结算。
- `CharacterBase`（extends CharacterBody2D）：`set_active(active:bool)->void`；`get_health()->Health`；虚方法 `_do_attack()->void`；`respawn(pos:Vector2)->void`。
- `Knight extends CharacterBase` / `Archer extends CharacterBase`：各自实现 `_do_attack()`。
- `Arrow`（extends Area2D）：`launch(direction:Vector2)->void`。
- `PartyManager`（extends Node2D）：`switch_to_next()->void`；`get_active_character()->CharacterBase`；`signal character_switched(character)`。
- `Switch`（extends Area2D）：`signal activated`；`receive_hit(damage:int)->void`。
- `Door`（extends StaticBody2D）：`open()->void`。
- `PatrolEnemy`（extends CharacterBody2D）。
- `HUD`（extends CanvasLayer）。

---

## 文件结构

```
res://
  scenes/
    test_room.tscn
    characters/{knight.tscn, archer.tscn}
    combat/arrow.tscn
    enemies/patrol_enemy.tscn
    puzzle/{switch.tscn, door.tscn}
    ui/hud.tscn
  scripts/
    combat/{health.gd, hitbox.gd, hurtbox.gd, arrow.gd}
    characters/{character_base.gd, knight.gd, archer.gd}
    party/party_manager.gd
    enemies/patrol_enemy.gd
    puzzle/{switch.gd, door.gd}
    ui/hud.gd
    world/{camera_follow.gd, test_room.gd}
  tests/
    test_helper.gd
    test_health.gd
    test_damage_routing.gd
    test_party_manager.gd
    test_switch_door.gd
```

每个脚本单一职责；战斗逻辑集中在 `scripts/combat/`，角色在 `scripts/characters/`。

---

## Task 0: 项目初始化（git + 目录 + 输入映射 + 测试骨架）

**Files:**
- Modify: `project.godot`（新增 input map 与 layer names；通过编辑器或 Hastur 执行器写入）
- Create: `scripts/`、`scenes/`、`tests/` 目录
- Create: `tests/test_helper.gd`

- [ ] **Step 1: 初始化 git 仓库**

Run:
```bash
cd /Users/quan/MyFile/GameProject/hollowfen && git init && git add -A && git commit -m "chore: initial Godot project snapshot"
```
Expected: 创建仓库并完成首个提交（项目已有 `.gitignore`，含 `.godot/`）。

- [ ] **Step 2: 配置碰撞层名与输入动作**

在 Godot 编辑器中（或用 Hastur 执行器运行下述脚本写入 ProjectSettings）设置：
- Layer Names → 2D Physics：按上文表把 1–8 命名为 `terrain / player_body / enemy_body / player_hitbox / enemy_hitbox / player_hurtbox / enemy_hurtbox / puzzle_target`。
- Input Map：新增动作并绑定键
  - `move_left` → A / ←
  - `move_right` → D / →
  - `jump` → Space / W
  - `attack` → J / 左键
  - `switch_character` → Shift / Q

通过 Hastur 执行器写入的等价 GDScript（一次性）：
```gdscript
# 设置输入动作示例（其余动作同理）
func _add(action: String, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    var ev := InputEventKey.new()
    ev.physical_keycode = keycode
    InputMap.action_add_event(action, ev)
# 注意：编辑器内运行只改运行时；持久化需写 ProjectSettings 或在编辑器 UI 手动设置后保存。
```
Expected: 运行项目时 `InputMap.has_action("jump")` 等返回 true；Project Settings 中可见 8 个层名。

> 推荐：在编辑器 UI 里手动设置这两项并保存 `project.godot`（最可靠、可持久化）。本步骤完成判定 = 重开项目后动作与层名仍在。

- [ ] **Step 3: 写测试辅助 `tests/test_helper.gd`**

```gdscript
class_name TestHelper
extends RefCounted

var _passed: int = 0
var _failed: int = 0

func check(condition: bool, label: String) -> void:
    if condition:
        _passed += 1
        print("  PASS: ", label)
    else:
        _failed += 1
        print("  FAIL: ", label)

func eq(actual, expected, label: String) -> void:
    check(actual == expected, "%s (expected %s, got %s)" % [label, str(expected), str(actual)])

# 返回进程退出码：0 全过，1 有失败
func summary(suite: String) -> int:
    print("[%s] passed=%d failed=%d" % [suite, _passed, _failed])
    return 0 if _failed == 0 else 1
```

- [ ] **Step 4: 验证测试骨架可运行**

先建一个临时自检脚本 `tests/test_smoke.gd`：
```gdscript
extends SceneTree

func _initialize() -> void:
    var t := TestHelper.new()
    t.eq(1 + 1, 2, "math works")
    quit(t.summary("smoke"))
```
Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_smoke.gd
```
Expected: 输出 `PASS: math works` 与 `[smoke] passed=1 failed=0`，退出码 0（`echo $?` 为 0）。然后删除 `test_smoke.gd`。

- [ ] **Step 5: 提交**

```bash
git add -A && git commit -m "chore: add input map, collision layers, test harness"
```

---

## Task 1: Health 组件

**Files:**
- Create: `scripts/combat/health.gd`
- Test: `tests/test_health.gd`

- [ ] **Step 1: 写失败测试 `tests/test_health.gd`**

```gdscript
extends SceneTree

func _initialize() -> void:
    var t := TestHelper.new()
    var h: Health = Health.new()
    h.max_health = 30
    get_root().add_child(h)  # 触发 _ready 初始化 current

    t.eq(h.current, 30, "initial current == max")
    t.eq(h.is_dead(), false, "alive at start")

    var changed := [0, 0]
    h.health_changed.connect(func(c, m): changed[0] = c; changed[1] = m)
    var died := [false]
    h.died.connect(func(): died[0] = true)

    h.take_damage(10)
    t.eq(h.current, 20, "current after 10 dmg")
    t.eq(changed[0], 20, "health_changed emitted current")

    h.take_damage(100)
    t.eq(h.current, 0, "current clamps at 0")
    t.eq(h.is_dead(), true, "dead after lethal")
    t.eq(died[0], true, "died signal emitted")

    h.reset()
    t.eq(h.current, 30, "reset restores max")
    t.eq(h.is_dead(), false, "alive after reset")

    h.free()
    quit(t.summary("health"))
```

- [ ] **Step 2: 跑测试确认失败**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_health.gd
```
Expected: 报错 `Could not find type "Health"` 或类似（类未定义）。

- [ ] **Step 3: 实现 `scripts/combat/health.gd`**

```gdscript
class_name Health
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 30

var current: int = 0

func _ready() -> void:
    current = max_health

func take_damage(amount: int) -> void:
    if current <= 0:
        return
    current = clampi(current - amount, 0, max_health)
    health_changed.emit(current, max_health)
    if current <= 0:
        died.emit()

func reset() -> void:
    current = max_health
    health_changed.emit(current, max_health)

func is_dead() -> bool:
    return current <= 0
```

- [ ] **Step 4: 跑测试确认通过**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_health.gd
```
Expected: 全部 PASS，`[health] passed=7 failed=0`，退出码 0。

- [ ] **Step 5: 提交**

```bash
git add -A && git commit -m "feat: add Health component with tests"
```

---

## Task 2: Hitbox / Hurtbox 与伤害结算

**Files:**
- Create: `scripts/combat/hurtbox.gd`、`scripts/combat/hitbox.gd`
- Test: `tests/test_damage_routing.gd`

> 说明：Area2D 的物理重叠检测需要运行帧，自动化测试只验证**逻辑路由**（`hurtbox.receive_hit` → `health.take_damage`）。物理重叠由后续「运行游戏并观察」验证。

- [ ] **Step 1: 写失败测试 `tests/test_damage_routing.gd`**

```gdscript
extends SceneTree

func _initialize() -> void:
    var t := TestHelper.new()
    var h: Health = Health.new()
    h.max_health = 50
    var hurt: Hurtbox = Hurtbox.new()
    hurt.health = h
    get_root().add_child(h)
    get_root().add_child(hurt)

    hurt.receive_hit(15)
    t.eq(h.current, 35, "hurtbox routes damage to health")

    # Hitbox 命中带 receive_hit 的对象
    var hit: Hitbox = Hitbox.new()
    hit.damage = 5
    var got := [0]
    var dummy := DummyTarget.new()
    dummy.on_hit = func(d): got[0] = d
    get_root().add_child(hit)
    get_root().add_child(dummy)
    hit._on_area_entered(dummy)  # 直接调用碰撞回调验证路由
    t.eq(got[0], 5, "hitbox calls receive_hit with damage")

    h.free(); hurt.free(); hit.free(); dummy.free()
    quit(t.summary("damage_routing"))

class DummyTarget extends Area2D:
    var on_hit: Callable
    func receive_hit(damage: int) -> void:
        on_hit.call(damage)
```

- [ ] **Step 2: 跑测试确认失败**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_damage_routing.gd
```
Expected: 类 `Hurtbox`/`Hitbox` 未定义而报错。

- [ ] **Step 3: 实现 `scripts/combat/hurtbox.gd`**

```gdscript
class_name Hurtbox
extends Area2D

signal hit_taken(damage: int)

@export var health: Health

func receive_hit(damage: int) -> void:
    hit_taken.emit(damage)
    if health != null:
        health.take_damage(damage)
```

- [ ] **Step 4: 实现 `scripts/combat/hitbox.gd`**

```gdscript
class_name Hitbox
extends Area2D

@export var damage: int = 10

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    monitoring = false  # 默认关闭，攻击时再开

func set_active(on: bool) -> void:
    monitoring = on

func _on_area_entered(area: Area2D) -> void:
    if area.has_method("receive_hit"):
        area.receive_hit(damage)
```

- [ ] **Step 5: 跑测试确认通过**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_damage_routing.gd
```
Expected: 全部 PASS，`[damage_routing] passed=2 failed=0`。

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add Hitbox/Hurtbox damage routing with tests"
```

---

## Task 3: CharacterBase（移动 + 枚举状态机）

> 实现决策：阶段 0 用**单脚本枚举状态机**（对新手最易懂），而非节点式 FSM。后续阶段如需可再重构。

**Files:**
- Create: `scripts/characters/character_base.gd`

> 移动手感属「运行观察」类，本任务不写自动化测试；在 Task 5（组装 Knight 场景）后做手感验证。

- [ ] **Step 1: 实现 `scripts/characters/character_base.gd`**

```gdscript
class_name CharacterBase
extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT }

@export_group("Movement")
@export var move_speed: float = 220.0
@export var acceleration: float = 1800.0
@export var friction: float = 2000.0
@export var jump_velocity: float = -430.0
@export var gravity: float = 1200.0
@export_group("Feel")
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1
@export_group("Combat")
@export var attack_duration: float = 0.25
@export var hurt_duration: float = 0.25
@export var invincible_time: float = 0.6
@export var knockback_force: float = 250.0

var state: int = State.IDLE
var _active: bool = false
var _facing: int = 1                 # 1 右, -1 左
var _coyote: float = 0.0
var _jump_buffer: float = 0.0
var _state_timer: float = 0.0
var _invincible_timer: float = 0.0

@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sprite: Node = get_node_or_null("Sprite")

func _ready() -> void:
    if _hurtbox:
        _hurtbox.hit_taken.connect(_on_hit_taken)

func set_active(active: bool) -> void:
    _active = active
    visible = active
    set_physics_process(active)

func get_health() -> Health:
    return _health

func get_facing() -> int:
    return _facing

func respawn(pos: Vector2) -> void:
    global_position = pos
    velocity = Vector2.ZERO
    _set_state(State.IDLE)
    if _health:
        _health.reset()

func _physics_process(delta: float) -> void:
    _invincible_timer = maxf(_invincible_timer - delta, 0.0)
    _coyote = maxf(_coyote - delta, 0.0)
    _jump_buffer = maxf(_jump_buffer - delta, 0.0)
    if is_on_floor():
        _coyote = coyote_time

    if not is_on_floor():
        velocity.y += gravity * delta

    match state:
        State.IDLE, State.RUN, State.JUMP, State.FALL:
            _process_locomotion(delta)
        State.ATTACK:
            _process_attack(delta)
        State.HURT:
            _process_hurt(delta)

    move_and_slide()

func _process_locomotion(delta: float) -> void:
    var dir := 0.0
    if _active:
        dir = Input.get_axis("move_left", "move_right")
        if Input.is_action_just_pressed("jump"):
            _jump_buffer = jump_buffer_time
        if Input.is_action_just_pressed("attack"):
            _enter_attack()
            return
    if dir != 0.0:
        velocity.x = move_toward(velocity.x, dir * move_speed, acceleration * delta)
        _facing = 1 if dir > 0.0 else -1
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)

    if _jump_buffer > 0.0 and _coyote > 0.0:
        velocity.y = jump_velocity
        _jump_buffer = 0.0
        _coyote = 0.0

    # 状态判定
    if not is_on_floor():
        _set_state(State.JUMP if velocity.y < 0.0 else State.FALL)
    elif absf(velocity.x) > 5.0:
        _set_state(State.RUN)
    else:
        _set_state(State.IDLE)

func _enter_attack() -> void:
    _set_state(State.ATTACK)
    _state_timer = attack_duration
    velocity.x = 0.0
    _do_attack()

func _process_attack(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, friction * delta)
    _state_timer -= delta
    if _state_timer <= 0.0:
        _set_state(State.IDLE)

func _process_hurt(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, friction * 0.5 * delta)
    _state_timer -= delta
    if _state_timer <= 0.0:
        _set_state(State.IDLE)

func _on_hit_taken(_damage: int) -> void:
    if _invincible_timer > 0.0:
        return
    _invincible_timer = invincible_time
    _set_state(State.HURT)
    _state_timer = hurt_duration
    velocity = Vector2(-_facing * knockback_force, -120.0)

func _set_state(new_state: int) -> void:
    state = new_state

# 由子类覆盖
func _do_attack() -> void:
    pass
```

- [ ] **Step 2: 静态检查脚本能解析（无语法错误）**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --check-only --script res://scripts/characters/character_base.gd
```
Expected: 无解析错误输出，退出码 0。

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add CharacterBase movement + enum state machine"
```

---

## Task 4: Knight 场景（近战）

**Files:**
- Create: `scripts/characters/knight.gd`
- Create: `scenes/characters/knight.tscn`

- [ ] **Step 1: 实现 `scripts/characters/knight.gd`**

```gdscript
class_name Knight
extends CharacterBase

@onready var _melee_hitbox: Hitbox = $MeleeHitbox
@onready var _melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D

func _do_attack() -> void:
    # 把命中盒移到面朝方向并短暂开启
    _melee_shape.position.x = absf(_melee_shape.position.x) * _facing
    _melee_hitbox.scale.x = _facing
    _melee_hitbox.set_active(true)
    await get_tree().create_timer(attack_duration * 0.6).timeout
    if is_instance_valid(_melee_hitbox):
        _melee_hitbox.set_active(false)
```

- [ ] **Step 2: 在编辑器中搭建 `scenes/characters/knight.tscn`**

节点结构（根脚本挂 `knight.gd`）：
```
Knight (CharacterBody2D, script=knight.gd, collision_layer=player_body, collision_mask=terrain)
 ├─ Sprite (ColorRect 或 Sprite2D)   ← 蓝色方块 ~28x40，name 必须为 "Sprite"
 ├─ CollisionShape2D                 ← 与地形碰撞的矩形
 ├─ Health (Node, script=health.gd)  ← max_health=40
 ├─ Hurtbox (Area2D, script=hurtbox.gd, layer=player_hurtbox, mask=0)
 │   ├─ CollisionShape2D
 │   └─ (Inspector) health = ../Health
 └─ MeleeHitbox (Area2D, script=hitbox.gd, layer=player_hitbox, mask=enemy_hurtbox|puzzle_target)
     └─ CollisionShape2D (放在角色右前方一小段，damage=15)
```
要点：
- Knight 数值：`move_speed=180`、`max_health=40`（血厚移动慢）。
- Hurtbox 的 `health` 在 Inspector 指向同级 `Health` 节点。
- MeleeHitbox 的 `damage=15`，碰撞形状偏右放置（攻击距离短）。

- [ ] **Step 3: 运行单场景观察（手感验证）**

在编辑器中以 Knight 为当前场景运行（F6），临时在 `_ready` 里 `set_active(true)` 或在房间里测。
Expected：能左右移动、有加减速、能跳；跳跃有土狼时间/缓冲手感；按攻击键进入短暂攻击状态、面前命中盒短暂出现（可在 Debug → Visible Collision Shapes 下观察）。

> 注：若 Knight 单独运行不动，是因为默认 `set_physics_process` 由 `set_active` 控制。临时在 `knight.gd` 的 `_ready` 末尾加 `set_active(true)` 测试，验证完移除（由 PartyManager 接管）。

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "feat: add Knight melee character scene"
```

---

## Task 5: Arrow + Archer 场景（远程）

**Files:**
- Create: `scripts/combat/arrow.gd`、`scripts/characters/archer.gd`
- Create: `scenes/combat/arrow.tscn`、`scenes/characters/archer.tscn`

- [ ] **Step 1: 实现 `scripts/combat/arrow.gd`**

```gdscript
class_name Arrow
extends Area2D

@export var speed: float = 520.0
@export var damage: int = 10
@export var lifetime: float = 2.0

var _dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)  # 撞墙(StaticBody)消失
    await get_tree().create_timer(lifetime).timeout
    if is_instance_valid(self):
        queue_free()

func launch(direction: Vector2) -> void:
    _dir = direction.normalized()
    rotation = _dir.angle()

func _physics_process(delta: float) -> void:
    global_position += _dir * speed * delta

func _on_area_entered(area: Area2D) -> void:
    if area.has_method("receive_hit"):
        area.receive_hit(damage)
        queue_free()

func _on_body_entered(_body: Node) -> void:
    queue_free()
```

- [ ] **Step 2: 搭建 `scenes/combat/arrow.tscn`**

```
Arrow (Area2D, script=arrow.gd, layer=player_hitbox, mask=enemy_hurtbox|puzzle_target|terrain)
 ├─ Sprite (ColorRect 小长条 ~16x4)
 └─ CollisionShape2D (小矩形)
```
要点：mask 含 `terrain`，使箭撞墙触发 `body_entered` 消失；含 `puzzle_target` 才能射中开关。

- [ ] **Step 3: 实现 `scripts/characters/archer.gd`**

```gdscript
class_name Archer
extends CharacterBase

const ARROW_SCENE := preload("res://scenes/combat/arrow.tscn")

@onready var _muzzle: Marker2D = $Muzzle

func _do_attack() -> void:
    var arrow: Arrow = ARROW_SCENE.instantiate()
    get_tree().current_scene.add_child(arrow)
    arrow.global_position = _muzzle.global_position
    arrow.launch(Vector2(_facing, 0.0))
```

- [ ] **Step 4: 搭建 `scenes/characters/archer.tscn`**

结构同 Knight，但：
- 根脚本 `archer.gd`，`Sprite` 为绿色方块。
- 数值：`move_speed=260`、`Health.max_health=25`（血薄移动快）。
- 无 MeleeHitbox；改为子节点 `Muzzle (Marker2D)` 放在角色前方（箭的发射点）。
- 保留 `Health`、`Hurtbox`（Hurtbox.health 指向 Health）。

- [ ] **Step 5: 校验脚本解析**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --check-only --script res://scripts/characters/archer.gd
```
Expected: 无解析错误。

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: add Archer ranged character and Arrow projectile"
```

---

## Task 6: PartyManager（切换脊柱）

**Files:**
- Create: `scripts/party/party_manager.gd`
- Test: `tests/test_party_manager.gd`

- [ ] **Step 1: 写失败测试 `tests/test_party_manager.gd`**

```gdscript
extends SceneTree

func _initialize() -> void:
    var t := TestHelper.new()
    var mgr: PartyManager = PartyManager.new()
    var a := _make_char()
    var b := _make_char()
    mgr.add_child(a)
    mgr.add_child(b)
    get_root().add_child(mgr)  # 触发 _ready

    t.eq(mgr.get_active_character(), a, "first child active initially")
    t.eq(a.visible, true, "active visible")
    t.eq(b.visible, false, "inactive hidden")

    a.global_position = Vector2(100, 50)
    var switched := [null]
    mgr.character_switched.connect(func(c): switched[0] = c)
    mgr.switch_to_next()

    t.eq(mgr.get_active_character(), b, "switched to second")
    t.eq(b.global_position, Vector2(100, 50), "position handed off")
    t.eq(b.visible, true, "new active visible")
    t.eq(a.visible, false, "old active hidden")
    t.eq(switched[0], b, "character_switched emitted new active")

    mgr.free()
    quit(t.summary("party_manager"))

func _make_char() -> CharacterBase:
    var c := CharacterBase.new()
    var h := Health.new()
    h.name = "Health"
    c.add_child(h)
    var hb := Hurtbox.new()
    hb.name = "Hurtbox"
    c.add_child(hb)
    return c
```

- [ ] **Step 2: 跑测试确认失败**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_party_manager.gd
```
Expected: `PartyManager` 未定义报错。

- [ ] **Step 3: 实现 `scripts/party/party_manager.gd`**

```gdscript
class_name PartyManager
extends Node2D

signal character_switched(character: CharacterBase)

var _characters: Array[CharacterBase] = []
var _active_index: int = 0

func _ready() -> void:
    for child in get_children():
        if child is CharacterBase:
            _characters.append(child)
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

func switch_to_next() -> void:
    if _characters.size() < 2:
        return
    var old := _characters[_active_index]
    _active_index = (_active_index + 1) % _characters.size()
    var new_char := _characters[_active_index]
    new_char.global_position = old.global_position
    new_char.velocity = old.velocity
    old.set_active(false)
    new_char.set_active(true)
    character_switched.emit(new_char)
```

- [ ] **Step 4: 跑测试确认通过**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_party_manager.gd
```
Expected: 全部 PASS，`[party_manager] passed=8 failed=0`。

- [ ] **Step 5: 提交**

```bash
git add -A && git commit -m "feat: add PartyManager character switching with tests"
```

---

## Task 7: 相机跟随

**Files:**
- Create: `scripts/world/camera_follow.gd`

- [ ] **Step 1: 实现 `scripts/world/camera_follow.gd`**

```gdscript
class_name CameraFollow
extends Camera2D

@export var party_manager: PartyManager
@export var smooth: float = 8.0

func _physics_process(delta: float) -> void:
    if party_manager == null:
        return
    var target := party_manager.get_active_character()
    if target == null:
        return
    global_position = global_position.lerp(target.global_position, clampf(smooth * delta, 0.0, 1.0))
```

- [ ] **Step 2: 校验脚本解析**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --check-only --script res://scripts/world/camera_follow.gd
```
Expected: 无解析错误。

- [ ] **Step 3: 提交**

```bash
git add -A && git commit -m "feat: add camera follow for active character"
```

---

## Task 8: 巡逻敌人

**Files:**
- Create: `scripts/enemies/patrol_enemy.gd`
- Create: `scenes/enemies/patrol_enemy.tscn`

- [ ] **Step 1: 实现 `scripts/enemies/patrol_enemy.gd`**

```gdscript
class_name PatrolEnemy
extends CharacterBody2D

@export var speed: float = 70.0
@export var patrol_distance: float = 120.0
@export var gravity: float = 1200.0

@onready var _health: Health = $Health

var _start_x: float = 0.0
var _dir: int = 1

func _ready() -> void:
    _start_x = global_position.x
    if _health:
        _health.died.connect(queue_free)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta
    velocity.x = _dir * speed
    if absf(global_position.x - _start_x) > patrol_distance:
        _dir = -_dir
    move_and_slide()
```

- [ ] **Step 2: 搭建 `scenes/enemies/patrol_enemy.tscn`**

```
PatrolEnemy (CharacterBody2D, script, layer=enemy_body, mask=terrain)
 ├─ Sprite (ColorRect 红方块)
 ├─ CollisionShape2D
 ├─ Health (script=health.gd, max_health=30)
 ├─ Hurtbox (Area2D, script=hurtbox.gd, layer=enemy_hurtbox, mask=0, health=../Health)
 │   └─ CollisionShape2D
 └─ ContactHitbox (Area2D, script=hitbox.gd, layer=enemy_hitbox, mask=player_hurtbox, damage=10)
     └─ CollisionShape2D (覆盖身体，monitoring 需常开)
```
要点：ContactHitbox 需常开监测——在该实例的 Inspector 不调用 `set_active`，或在场景里给它单独逻辑。最简：把 ContactHitbox 的 `monitoring` 在 `_ready` 后设 true（敌人接触即伤害）。可在 patrol_enemy.gd 的 `_ready` 末尾加 `$ContactHitbox.set_active(true)`。

- [ ] **Step 3: 验证（运行观察）**

把敌人放进测试房间临时运行：Expected——敌人在平台上来回巡逻；玩家攻击命中其 Hurtbox 两次（15×2≥30）后消失；玩家碰到敌人会受伤（闪/击退/掉血）。

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "feat: add patrol enemy with contact damage"
```

---

## Task 9: 开关 + 门（解谜）

**Files:**
- Create: `scripts/puzzle/switch.gd`、`scripts/puzzle/door.gd`
- Create: `scenes/puzzle/switch.tscn`、`scenes/puzzle/door.tscn`
- Test: `tests/test_switch_door.gd`

- [ ] **Step 1: 写失败测试 `tests/test_switch_door.gd`**

```gdscript
extends SceneTree

func _initialize() -> void:
    var t := TestHelper.new()
    var sw: Switch = Switch.new()
    var door: Door = Door.new()
    get_root().add_child(sw)
    get_root().add_child(door)
    sw.activated.connect(door.open)

    t.eq(door.is_open, false, "door closed initially")
    t.eq(sw.is_activated, false, "switch off initially")

    sw.receive_hit(1)
    t.eq(sw.is_activated, true, "switch activates on hit")
    t.eq(door.is_open, true, "door opens via signal")

    # 永久：再次命中不改变
    sw.receive_hit(1)
    t.eq(sw.is_activated, true, "switch stays activated")

    sw.free(); door.free()
    quit(t.summary("switch_door"))
```

- [ ] **Step 2: 跑测试确认失败**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_switch_door.gd
```
Expected: `Switch`/`Door` 未定义报错。

- [ ] **Step 3: 实现 `scripts/puzzle/switch.gd`**

```gdscript
class_name Switch
extends Area2D

signal activated

var is_activated: bool = false

@onready var _sprite: Node = get_node_or_null("Sprite")

func receive_hit(_damage: int) -> void:
    if is_activated:
        return
    is_activated = true
    if _sprite and _sprite is CanvasItem:
        (_sprite as CanvasItem).modulate = Color.LIME_GREEN  # 触发后变色
    activated.emit()
```

- [ ] **Step 4: 实现 `scripts/puzzle/door.gd`**

```gdscript
class_name Door
extends StaticBody2D

var is_open: bool = false

@onready var _collision: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var _sprite: Node = get_node_or_null("Sprite")

func open() -> void:
    if is_open:
        return
    is_open = true
    if _collision:
        _collision.set_deferred("disabled", true)
    if _sprite:
        _sprite.visible = false
```

- [ ] **Step 5: 跑测试确认通过**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --script res://tests/test_switch_door.gd
```
Expected: 全部 PASS，`[switch_door] passed=5 failed=0`。

- [ ] **Step 6: 搭建场景**

`scenes/puzzle/switch.tscn`：
```
Switch (Area2D, script, layer=puzzle_target, mask=0)
 ├─ Sprite (ColorRect 黄方块)
 └─ CollisionShape2D
```
`scenes/puzzle/door.tscn`：
```
Door (StaticBody2D, script, layer=terrain, mask=0)
 ├─ Sprite (ColorRect 灰长条)
 └─ CollisionShape2D
```

- [ ] **Step 7: 提交**

```bash
git add -A && git commit -m "feat: add switch+door puzzle with tests"
```

---

## Task 10: HUD

**Files:**
- Create: `scripts/ui/hud.gd`
- Create: `scenes/ui/hud.tscn`

- [ ] **Step 1: 实现 `scripts/ui/hud.gd`**

```gdscript
class_name HUD
extends CanvasLayer

@export var party_manager: PartyManager

@onready var _active_label: Label = $Root/ActiveLabel
@onready var _hp_label: Label = $Root/HpLabel

func _ready() -> void:
    if party_manager:
        party_manager.character_switched.connect(_on_switched)
        _on_switched(party_manager.get_active_character())

func _on_switched(character: CharacterBase) -> void:
    if character == null:
        return
    _active_label.text = "当前: " + character.name
    _refresh_hp()
    var h := character.get_health()
    if h and not h.health_changed.is_connected(_on_hp_changed):
        h.health_changed.connect(_on_hp_changed)

func _on_hp_changed(_c: int, _m: int) -> void:
    _refresh_hp()

func _refresh_hp() -> void:
    if party_manager == null:
        return
    var c := party_manager.get_active_character()
    if c and c.get_health():
        var h := c.get_health()
        _hp_label.text = "HP: %d/%d" % [h.current, h.max_health]
```

- [ ] **Step 2: 搭建 `scenes/ui/hud.tscn`**

```
HUD (CanvasLayer, script)
 └─ Root (Control / MarginContainer)
     ├─ ActiveLabel (Label)
     └─ HpLabel (Label)
```

- [ ] **Step 3: 校验脚本解析**

Run:
```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path /Users/quan/MyFile/GameProject/hollowfen --check-only --script res://scripts/ui/hud.gd
```
Expected: 无解析错误。

- [ ] **Step 4: 提交**

```bash
git add -A && git commit -m "feat: add HUD showing active character and HP"
```

---

## Task 11: 组装测试房间 + 死亡重生 + 整体验证

**Files:**
- Create: `scripts/world/test_room.gd`
- Create: `scenes/test_room.tscn`
- Modify: `project.godot`（设为主场景）

- [ ] **Step 1: 实现 `scripts/world/test_room.gd`（死亡重生）**

```gdscript
class_name TestRoom
extends Node2D

@export var party_manager: PartyManager
@onready var _spawn: Marker2D = $SpawnPoint

func _ready() -> void:
    if party_manager == null:
        return
    for c in party_manager.get_children():
        if c is CharacterBase:
            var h := (c as CharacterBase).get_health()
            if h:
                h.died.connect(_on_character_died.bind(c as CharacterBase))

func _on_character_died(character: CharacterBase) -> void:
    # 简单重生：回到起点、回满血
    character.respawn(_spawn.global_position)
```

- [ ] **Step 2: 搭建 `scenes/test_room.tscn`**

```
TestRoom (Node2D, script=test_room.gd)
 ├─ Terrain (StaticBody2D, layer=terrain) ── 用多个 CollisionShape2D + ColorRect 拼出:
 │     地板、一道阻挡的门位、一处高台(放开关，近战够不到)、通往终点的路
 ├─ SpawnPoint (Marker2D)              ← 玩家起点
 ├─ PartyManager (Node2D, script)
 │   ├─ Knight (instance of knight.tscn) ← 放在 SpawnPoint 处
 │   └─ Archer (instance of archer.tscn)
 ├─ PatrolEnemy (instance)             ← 挡在前进路上
 ├─ Switch (instance)                  ← 高台上, 近战挥砍够不到, 只能射
 ├─ Door (instance)                    ← 挡住通往终点
 ├─ Goal (Area2D + Label "终点")        ← 走到即过关(可只放视觉标记)
 ├─ Camera (CameraFollow)              ← party_manager 指向 PartyManager
 └─ HUD (instance of hud.tscn)         ← party_manager 指向 PartyManager
```
连接：
- `TestRoom.party_manager` = PartyManager
- `Camera.party_manager` = PartyManager
- `HUD.party_manager` = PartyManager
- Switch.`activated` 信号 → Door.`open()`（编辑器里连接，或在 test_room.gd `_ready` 用 `$Switch.activated.connect($Door.open)`）

- [ ] **Step 3: 设为主场景**

Project Settings → Application → Run → Main Scene = `res://scenes/test_room.tscn`。
（移除 Task 4 临时加的 `set_active(true)`，由 PartyManager 接管激活。）

- [ ] **Step 4: 跑全部自动化测试（回归）**

Run:
```bash
cd /Users/quan/MyFile/GameProject/hollowfen
B=/Applications/Godot_mono.app/Contents/MacOS/Godot
for s in test_health test_damage_routing test_party_manager test_switch_door; do
  echo "== $s =="; $B --headless --path . --script res://tests/$s.gd || echo "SUITE FAILED: $s"
done
```
Expected: 四个套件全部 `failed=0`。

- [ ] **Step 5: 整体流程验证（运行游戏并观察）**

运行游戏（F5）。按完成判定标准逐条确认：
1. Knight 开局，能跑/跳，手感顺（土狼时间/跳跃缓冲生效）。
2. 遇到巡逻敌人，攻击命中两次后敌人消失；被敌人碰到会受伤（闪白/击退/掉血/无敌帧）。
3. 前进遇锁门；开关在高台，Knight 挥砍够不到。
4. 按切换键变成 Archer（相机平滑跟随，HUD 显示「当前: Archer」与其血量）。
5. Archer 射箭命中开关 → 开关变色 → 门打开。
6. 走到终点。
7. 切回 Knight，血量仍是切走时的值（各自独立）。
8. 让某角色血量归零 → 回到起点并满血重生。

逐条记录是否通过；不通过的项回到对应 Task 修复。

- [ ] **Step 6: 提交**

```bash
git add -A && git commit -m "feat: assemble test room, death/respawn, wire vertical slice"
```

---

## 完成定义（Definition of Done）

- 四个 headless 测试套件全部通过（Health / 伤害路由 / 切换 / 开关门）。
- Step 5 的 8 条整体流程全部观察通过。
- 全程占位美术；逻辑与美术解耦。
- 满足 spec 第 10 节完成判定：起点→砍敌→切角射开关开门→终点，切换/战斗/解谜均正常，且手感「有意思」。

---

## 自检记录（写计划时已核对）

- **Spec 覆盖**：结构(T11)、角色系统/切换(T3/T6)、移动(T3)、战斗 Hitbox/Hurtbox/血量(T1/T2/T4/T5/T8)、谜题(T9)、占位美术(各场景搭建步)、死亡重生(T11)、HUD(T10) —— 均有对应任务。
- **占位符**：无 TBD/TODO；逻辑步骤均含完整代码，场景搭建步给出明确节点树与属性。
- **类型/命名一致**：`take_damage`/`reset`/`is_dead`/`current`、`receive_hit`、`set_active`、`get_health`、`get_active_character`/`switch_to_next`(注：实现为 `switch_to_next`)/`character_switched`、`launch`、`activated`/`is_activated`、`open`/`is_open` 在各任务中一致使用。
- **手感类**无法自动测试，统一在 Task 11 Step 5「运行观察」覆盖。
