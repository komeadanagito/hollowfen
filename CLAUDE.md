# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the project (main scene)
godot --path .

# Open in editor
godot --editor --path .

# Run a single test suite
godot --headless --path . --script res://tests/test_health.gd

# Run all tests
for t in tests/test_*.gd; do [ "$t" = "tests/test_helper.gd" ] && continue; godot --headless --path . --script "res://$t"; done

# Broker service (TypeScript/Vite)
cd broker-server && npm install
cd broker-server && npm run dev
cd broker-server && npm run build
cd broker-server && npm test
```

Tests must pass before submitting gameplay changes. Run the affected suite first, then all suites.

## Architecture

**Hollowfen** is a Godot 4.6 2D platformer. Main scene: `res://scenes/tutorial_level.tscn`.

### Character System

`CharacterBase` (`scripts/characters/character_base.gd`) is the shared base for all playable characters. It owns:
- A state machine (`IDLE/RUN/JUMP/FALL/ATTACK/HURT`) driven by `_physics_process`
- Coyote time + jump buffering
- `_active` flag: only the active character reads input
- `_last_safe` position, used by PartyManager on death handoff

`Knight` and `Archer` extend `CharacterBase`, overriding `_do_attack()`. Archer has `air_jumps = 1` (double jump); Knight has `air_jumps = 0`.

### Party System

`PartyManager` (`scripts/party/party_manager.gd`) manages the active character:
- Discovers `CharacterBase` children on `_ready`; index 0 starts active
- `switch_to_next()` / `switch_character` signal: teleports new character to old position + velocity
- `notify_death(character)`: marks dead, switches to living character at the dead one's last safe position; emits `party_wiped` if none remain
- Characters can be locked (e.g., Archer starts locked until pickup)

### Level Wiring (`TutorialLevel`)

`tutorial_level.gd` connects everything at runtime:
- Switch → Door via `activated` signal
- Character deaths → `PartyManager.notify_death`
- `party_wiped` → revive all + respawn at `$SpawnPoint`
- `DeathZone` (pit) → instant kill on `body_entered`
- `LevelExit` → completion

### Combat

- `Health` node emits `died` and `hit_taken` signals; `Hurtbox` emits `hit_taken` to parent
- `CharacterBase` connects to `Hurtbox.hit_taken` → enter HURT state with knockback
- `CharacterBase` connects to `Health.died` → freeze + play death animation
- Invincibility frames are managed inside `Hurtbox`

### Testing

Tests use `TestHelper` (`tests/test_helper.gd`) — a plain `RefCounted` with `check(bool, label)`, `eq(actual, expected, label)`, and `summary(suite) -> int` (returns exit code). Tests run headless and exit with 0 (all pass) or 1 (any fail).

One-off scene-builder utilities live in `scratchpad/` — these are not tests and not shipped.

### Hastur Broker / Godot Node Control

Use the Hastur broker instead of ad hoc UI automation when inspecting, editing, or controlling Godot nodes. Start it with:

```bash
cd broker-server && npm run dev
```

The dev script runs `tsx src/index.ts --auth-token 995e7c3f6fabc40a1bcd8a6f94dcad0106959c26c5827d2d3b261e1969109bd7`. TCP executor connections listen on `localhost:5301`, and HTTP API calls listen on `localhost:5302`. Use `Authorization: Bearer 995e7c3f6fabc40a1bcd8a6f94dcad0106959c26c5827d2d3b261e1969109bd7`.

Prefer structured Godot endpoints for node work:
- `POST /api/godot/tree`
- `POST /api/godot/node/get`
- `POST /api/godot/node/set`
- `POST /api/godot/node/call`

Use `POST /api/execute` only when a custom GDScript snippet is needed. Target the `Hollowfen` executor or `/Users/quan/MyFile/GameProject/hollowfen/` project path; use `type: "editor"` for editing scenes and `type: "game"` for the running game executor.

## Conventions

- GDScript: tabs, `snake_case` for vars/functions/files, `PascalCase` for `class_name`
- `@export` vars for all tunable gameplay values
- Node paths that tests or scenes depend on must stay stable
- Do not commit `.godot/` cache files
- Commits use Conventional Commit prefixes: `feat:`, `fix:`, `tweak:`, `refactor:`
- PRs for visual/animation/layout changes include screenshots or clips
