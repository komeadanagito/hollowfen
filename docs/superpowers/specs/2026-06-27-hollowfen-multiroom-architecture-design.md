# Hollowfen 多房间架构（互联地图）设计文档

- **日期**：2026-06-27
- **项目**：Hollowfen（Godot 4.6.2，GL Compatibility）
- **状态**：设计待评审
- **范围**：子项目 1 —— 房间框架地基（结构梳理 + 房间切换 + TileSet + 迁移成 2 个相连房间）。存档/能力门禁/地图 UI 留作子项目 2。

---

## 1. 目标

把目前"单个脚本生成的教学关"升级为**可扩展的互联房间架构**：房间之间用门双向连接、可回头，新房间能在 **Godot 编辑器里拖预制体摆出来**。本子项目交付一个能跑通"房间 A ⇄ 房间 B 切换、队伍状态跨房间保留"的地基，并把现有教学关迁移上去作为样板。

## 2. 已确认决策
| 维度 | 决策 |
|------|------|
| 房间组织 | **互联地图（类魂）**：门双向连接、可回头；门预留能力门禁字段 |
| 关卡作者方式 | **Godot 编辑器里摆场景**（拖预制体 + 刷 TileMap 地形） |
| 目录重构幅度 | **渐进式清理**：加 systems/ + rooms/ + TileSet，scenes 轻整理成预制体库；scripts 基本不挪 |

## 3. 目标目录结构（渐进式）
只**新增**和**轻整理**，不打散现有 scripts：
```
scenes/
  entities/            ← 由现有 scenes/{characters,enemies,combat,puzzle,world} 轻归并
    characters/  enemies/  projectiles/  props/   (door, switch, pickup, room_portal*)
  ui/                  hud, tutorial_layer
  rooms/               room_*.tscn        ← 编辑器里摆的房间（新）
scripts/
  systems/             game.gd*, room_manager.gd*, room_base.gd*, camera_follow.gd(移入)
  (characters/ combat/ enemies/ party/ puzzle/ ui/ world/ 基本保持)
assets/  (已整理: character/ enemy/ prop/ scene/)
tilesets/  dungeon_tileset.tres*          ← 地形 TileSet（新）
docs/ tests/
```
*=新增。`scenes/` 的归并用 Godot `uid://` 保证引用不断；移动后立即跑全套测试验证。

## 4. 房间框架（核心）

### 4.1 `Game`（autoload 单例，scripts/systems/game.gd）
跨房间持久化进度（`change_scene` 会销毁房间，所以状态必须存这里）：
- `unlocked: Dictionary` — {角色名: bool}
- `hp: Dictionary` — {角色名: 当前血量}（跨房间带走）
- `vials: int`、`abilities: Dictionary`（如 {"dash": true}）、`unlocked_bonfires: Array`
- `func start_new_game()` — 初始化默认进度
- `func save_party_state(pm: PartyManager)` — 把房间 PartyManager 当前状态写回 Game
- `func apply_party_state(pm: PartyManager)` — 把 Game 状态套用到房间 PartyManager（解锁、血量、血瓶）

### 4.2 `RoomManager`（autoload，scripts/systems/room_manager.gd）
- `var pending_entry: String` — 进入新房间时在哪个入口出生
- `func go_to(room_path: String, entry_id: String)` — 记录 pending_entry 后 `change_scene_to_file(room_path)`

### 4.3 `RoomBase`（class_name Room，每个房间根脚本）
通用化现在的 `tutorial_level.gd`：
- `_ready()`：`Game.apply_party_state(party_manager)` → 按 `RoomManager.pending_entry` 找到对应 `RoomPortal` 把队伍放到其位置（找不到则用默认 `SpawnPoint`）→ 接线 开关→门 / 死亡→切角色 / 全灭→回本房入口 / DeathZone / Portal。
- `func depart(room_path, entry_id)`：`Game.save_party_state(party_manager)` → `RoomManager.go_to(...)`
- 在组 `"room"`，供 Portal 查找。

### 4.4 `RoomPortal`（预制体，scripts/systems/room_portal.gd + scenes/entities/props/room_portal.tscn）
**既是出口也是入口锚点**（双向门）：
- `@export entry_id: String` — 本入口锚点 id（到达时若 `pending_entry==entry_id` 在此出生）
- `@export target_room: String`、`@export target_entry: String`
- `@export required_ability: String = ""` — 能力门禁字段（本期不判定，仅占位）
- Area2D，mask=player_body；激活角色进入 → 找到组 `"room"` 的 Room → `room.depart(target_room, target_entry)`
- 现有 `LevelExit` 用法被它取代。

## 5. 数据流（一次房间切换）
```
玩家走进 RoomA 的 PortalAB
  → PortalAB 找到 RoomA(组room) → RoomA.depart(RoomB.tscn, "from_A")
    → Game.save_party_state(RoomA.PartyManager)   # 存血量/解锁/血瓶
    → RoomManager.go_to(RoomB.tscn, "from_A")      # pending_entry="from_A"; change_scene
  → RoomB 实例化 → RoomB._ready()
    → Game.apply_party_state(RoomB.PartyManager)   # 恢复血量/解锁/血瓶
    → 找 entry_id=="from_A" 的 Portal，把队伍放那儿出生
```
回头（RoomB→RoomA）走相同路径，靠各自 Portal 的 entry_id 对应。

## 6. 编辑器摆关卡
- **预制体库**：角色/敌人/机关/Portal/Pickup 都做成干净 .tscn，编辑器里拖进 room 场景即可。
- **TileSet 地形**：从 `assets/scene/{floor_stone,stone_block,ceiling_stone}` 建一个带矩形碰撞的 `dungeon_tileset.tres`；房间用 `TileMapLayer` 刷地形（替代现在的 StaticBody 色块/精灵块，编辑器里好摆太多）。
- **房间根** = 一个 `Room` 脚本的 Node2D，包含：TileMapLayer(地形) + PartyManager(预制) + CameraFollow + HUD + 若干 Portal + 敌人/机关实例 + 可选 DeathZone/Background。

## 7. 迁移
把现有教学关拆成 **2 个相连房间**验证框架：
- `room_tutorial_a.tscn`：移动/跳跃/打史莱姆/深坑/拿 Archer/第一道开关墙 → 末端一个 Portal 到 B。
- `room_tutorial_b.tscn`：哥布林战 + 第二道开关墙 + 终点。入口 Portal 回 A。
- 主场景设为 `room_tutorial_a.tscn`；`Game.start_new_game()` 在首个房间初始化。
- 迁移仍可用 build 脚本生成初版 .tscn（输出是普通可编辑场景），之后你在编辑器里继续调。

## 8. 测试策略
- **逻辑单测**（headless）：`Game.save/apply_party_state` 往返一致；`RoomManager.go_to` 设置 pending_entry；`RoomPortal` 进入触发 depart；`Room` 按 pending_entry 选对入口。
- **场景烟测**：两个房间各自实例化无错、含必需节点（PartyManager/Portal/入口）。
- **集成**：模拟 A→B→A 切换，断言队伍血量/解锁状态被带过去、出生在正确入口。
- 复用现有 17 套测试当回归安全网；每步移动文件后全量跑。

## 9. 范围边界
### ✅ 本子项目
房间框架（Game/RoomManager/RoomBase/RoomPortal）、TileSet 地形、预制体库、目录渐进整理、教学关迁成 2 房间、上述测试。
### ❌ 留给子项目 2
- 存档/读档（跨重启记住进度与位置）
- 能力门禁判定（字段已留）
- 地图 UI / 小地图
- 更多房间内容、Boss、音效

## 10. 完成判定
能从 room_a 出发，正常游玩（移动/战斗/切角色/解谜/二段跳过坑），走到 Portal 进入 room_b，队伍血量与解锁状态被带过去并在 b 的正确入口出生；从 b 走回 a 也对应正确；新房间能在编辑器里拖预制体 + 刷 TileMap 摆出来。全套测试绿。
