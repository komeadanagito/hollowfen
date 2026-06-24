# Hollowfen 教学关 v2（敌人扩展 + 关卡加长 + HUD 改版）Plan

> 迭代计划，承接 `2026-06-24-hollowfen-tutorial-level.md`，作者本人 inline 执行。逻辑组件走 TDD headless，场景走 headless 构建脚本 + 烟测（见 memory [[headless-class-cache-refresh]]）。

**Goal:** 让教学关更丰富：3 种敌人（史莱姆 + 剑哥布林追击挥砍 + 弓哥布林保持距离射箭，哥布林先用色块占位）、关卡扩到 8-10 段、HUD 改为长条血条 + 左上角随切换变化的方形透明头像。

**已确认决策：** 中等 AI（三种行为不同）；扩到 8-10 段线性进阶；保留史莱姆。头像方形、只露头、白底抠成透明。

## Global Constraints（沿用 v1）
- 碰撞层：terrain=1, player_body=2, enemy_body=4, player_hitbox=8, enemy_hitbox=16, player_hurtbox=32, enemy_hurtbox=64, puzzle_target=128。
- 玩家弹/箭 layer=player_hitbox(8) mask=1+64+128=193；**敌人箭** layer=enemy_hitbox(16) mask=terrain(1)+player_hurtbox(32)=33。
- 新 class_name 后跑 `Godot --headless --editor --quit-after 200 --path .` 刷新类缓存。
- 占位命名 `PH_*` + `editor_description` 物料注释。

## 关键设计

### 玩家发现机制
- `CharacterBase._ready()` 里 `add_to_group("player")`。敌人 AI 用 `get_tree().get_nodes_in_group("player")` 找 `is_active()` 的那个作为目标（解耦，不依赖 PartyManager 引用）。

### 敌人箭 `enemy_arrow.tscn`
- 复用 `arrow.gd`（已是通用 Area2D，命中 hurtbox 调 `receive_hit`）。新场景：layer=16, mask=33，红色弹体。速度沿玩家方向水平飞。

### MeleeGoblin（剑哥布林）`scripts/enemies/melee_goblin.gd`
- `CharacterBody2D`，子节点：Health、Hurtbox(64)、MeleeHitbox(16, mask=32)、Sprite(占位橙块 80×110)、CollisionShape。
- 状态 PATROL/CHASE/ATTACK：巡逻；player 进 `detect_range`(450) 且竖直差<120 → 追击；进 `attack_range`(95) → 停下 windup(0.3s) 开 hitbox(0.15s) 冷却(0.8s)。gravity=3000。
- @export：speed=160, chase_speed=240, detect_range=450, attack_range=95, patrol_distance=250, damage=12, max_health=45。

### RangedGoblin（弓哥布林）`scripts/enemies/ranged_goblin.gd`
- `CharacterBody2D`，子节点：Health、Hurtbox(64)、Muzzle、Sprite(占位紫块 80×110)、CollisionShape。
- 状态 IDLE/AIM/RETREAT：player 进 `fire_range`(750) 且竖直差<100 → 每 `fire_interval`(1.6s) 朝 player 方向发 `enemy_arrow`；player 进 `min_distance`(220) → 后退。gravity=3000。
- @export：fire_range=750, min_distance=220, retreat_speed=180, fire_interval=1.6, max_health=30, arrow_damage=8。

### HUD 改版 `scripts/ui/hud.gd` + `scenes/ui/hud.tscn`
- 左上 HBox：`Avatar`(TextureRect 96×96, 方形头像) + 竖排(`NameLabel` + `HealthBar`)。
- `HealthBar`：ProgressBar（StyleBoxFlat 背景深灰、前景红绿），min=0 max=当前角色 max_health，value=current，宽 ~320。长条样式。
- `character_switched` → 换 avatar 纹理（按角色名映射）+ 重连 health_changed + 刷新 bar。
- 头像纹理：`assets/knight_avatar_head.png` / `assets/archer_avatar_head.png`（见下）。

### 头像处理（assets）
- 源：`assets/knight_avatar.png`(1024² RGBA 全身白底)、`assets/archer_avatar.png`(684×1024)。
- 管线（PIL）：从四边 flood-fill 去白底→透明（保留眼白等内部白）；按 alpha bbox 找内容，取头部方形裁切（顶部对齐，边长≈内容高×系数，水平居中）；resize 256²；存 `*_head.png`。**生成后肉眼校验裁切，必要时调系数。**

## 任务
- **T9** 头像处理 → 两个透明方形头像，肉眼校验。
- **T10** `CharacterBase` 加 player 组 + `enemy_arrow.tscn`（TDD：敌人箭命中玩家 hurtbox 扣血）。
- **T11** MeleeGoblin 脚本+占位场景（TDD：检测进入追击；攻击范围开 hitbox）+ 烟测。
- **T12** RangedGoblin 脚本+占位场景（TDD：范围内发射 enemy_arrow；过近后退）+ 烟测。
- **T13** HUD 改版（bar + avatar，build + 烟测：切换换头像、扣血改 bar.value）。
- **T14** 扩建 `tutorial_level.tscn` 到 8-10 段，混编三种敌人 + 更多平台/解谜 + 重新烟测 + 2s 运行无错。
- **T15** 全量回归 + 人工游玩验证。
