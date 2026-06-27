# Hollowfen Level 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Level 2 as a playable four-character progression level with blood vials, bonfires, bats, revival totems, shields/heavy enemies, breakable obstacles, push boxes, and unlocks for the ocarina girl and hammer warrior.

**Architecture:** Keep new systems in focused Godot scripts and scenes that match existing patterns. Extend shared combat/character code only where needed for reusable health healing, corpse revival, party vials, and activation/collision behavior.

**Tech Stack:** Godot 4.6 GDScript, `.tscn` scenes, existing lightweight `tests/test_*.gd` SceneTree test style.

---

### Task 1: Health, Blood Vials, and HUD Data

**Files:**
- Modify: `scripts/combat/health.gd`
- Modify: `scripts/party/party_manager.gd`
- Modify: `scripts/ui/hud.gd`
- Test: `tests/test_health.gd`
- Test: `tests/test_party_manager.gd`
- Test: `tests/test_hud.gd`

- [ ] Add failing tests for `Health.heal`, party vial count, vial use, and refill.
- [ ] Implement `Health.heal(amount)`.
- [ ] Add party-level `max_vials`, `vials`, `use_vial()`, `refill_vials()`, and `vials_changed`.
- [ ] Update HUD to show vial count.
- [ ] Run health, party, and HUD tests.

### Task 2: Bonfire

**Files:**
- Create: `scripts/world/bonfire.gd`
- Create: `scenes/world/bonfire.tscn`
- Test: `tests/test_bonfire.gd`

- [ ] Add failing tests for bonfire activation, healing party members, refilling vials, and recording rest position.
- [ ] Implement bonfire activation against `PartyManager`.
- [ ] Create a simple bonfire scene using existing placeholder drawing primitives.
- [ ] Run bonfire tests.

### Task 3: New Character Scenes

**Files:**
- Create: `scripts/characters/ocarina_girl.gd`
- Create: `scripts/characters/hammer_warrior.gd`
- Create: `scripts/combat/homing_note.gd`
- Create: `scenes/combat/homing_note.tscn`
- Create: `scenes/characters/ocarina_girl.tscn`
- Create: `scenes/characters/hammer_warrior.tscn`
- Test: `tests/test_ocarina_girl.gd`
- Test: `tests/test_hammer_warrior.gd`

- [ ] Add failing tests for both character scenes loading, stats, health, and attack behavior.
- [ ] Implement ocarina girl healing plus low-damage homing note.
- [ ] Implement hammer warrior high-damage melee hitbox.
- [ ] Run character tests.

### Task 4: Obstacles and Push Boxes

**Files:**
- Create: `scripts/world/breakable_obstacle.gd`
- Create: `scenes/world/breakable_obstacle.tscn`
- Create: `scripts/world/push_box.gd`
- Create: `scenes/world/push_box.tscn`
- Test: `tests/test_breakable_obstacle.gd`
- Test: `tests/test_push_box.gd`

- [ ] Add failing tests for hammer breaking obstacles and pushing boxes.
- [ ] Implement breakable obstacle hit handling.
- [ ] Implement push box as a physics-friendly rigid body.
- [ ] Run obstacle tests.

### Task 5: New Enemies and Revival Totem

**Files:**
- Modify: enemy death handling scripts as needed.
- Create: `scripts/enemies/bat.gd`
- Create: `scenes/enemies/bat.tscn`
- Create: `scripts/enemies/revival_totem.gd`
- Create: `scenes/enemies/revival_totem.tscn`
- Create: `scenes/enemies/shield_goblin.tscn`
- Create: `scenes/enemies/heavy_goblin.tscn`
- Test: `tests/test_bat.gd`
- Test: `tests/test_revival_totem.gd`

- [ ] Add failing tests for bat movement/damage and totem healing/revival.
- [ ] Add revive support to enemies without destabilizing existing death tests.
- [ ] Implement bat patrol/attack.
- [ ] Implement revival totem pulse heal/revive.
- [ ] Create shield/heavy enemy variants from existing goblin scenes.
- [ ] Run enemy tests.

### Task 6: Level 2 Scene and Script

**Files:**
- Create: `scripts/world/level_2.gd`
- Create: `scenes/level_2.tscn`
- Test: `tests/test_level_2_scene.gd`

- [ ] Add failing scene smoke test for Level 2 structure.
- [ ] Build cliff platform parkour opening with doors, switches, bats, and bonfire.
- [ ] Add ocarina girl unlock, revival totem encounter, hammer unlock, breakable/push-box section, final combat room, second bonfire, and exit.
- [ ] Wire unlocks, deaths, pits, bonfires, doors, and exit.
- [ ] Run Level 2 scene test.

### Task 7: Full Verification

**Files:**
- All touched files.

- [ ] Run all real `tests/test_*.gd` except `test_helper.gd`.
- [ ] Fix regressions.
- [ ] Summarize implementation and known visual/manual QA needs.
