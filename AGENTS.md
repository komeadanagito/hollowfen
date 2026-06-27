# Repository Guidelines

## Project Structure & Module Organization
Hollowfen is a Godot 4 project. `project.godot` defines the project settings and currently runs `res://scenes/tutorial_level.tscn` as the main scene. Runtime GDScript lives in `scripts/`, grouped by domain such as `characters/`, `combat/`, `enemies/`, `party/`, `puzzle/`, `ui/`, and `world/`. Scene files mirror those domains under `scenes/`. Art and sprites belong in `assets/`, with character, enemy, prop, and scene assets kept in separate subfolders. Automated test scripts live in `tests/test_*.gd`; one-off builder utilities and generated-scene helpers live in `scratchpad/`. `broker-server/` is a separate TypeScript/Vite helper service.

## Build, Test, and Development Commands
- `godot --path .`: run the Godot project locally using the configured main scene.
- `godot --editor --path .`: open the project in the Godot editor.
- `godot --headless --path . --script res://tests/test_health.gd`: run a single GDScript test suite.
- `for t in tests/test_*.gd; do [ "$t" = "tests/test_helper.gd" ] && continue; godot --headless --path . --script "res://$t"; done`: run all test suites.
- `cd broker-server && npm install`: install broker dependencies.
- `cd broker-server && npm run build`: build the broker service with Vite.
- `cd broker-server && npm run dev`: start the local broker development server.

## Godot Node Control via Hastur Broker
When inspecting, editing, or controlling nodes inside the running Godot editor, use the Hastur broker instead of ad hoc UI automation. Start it with `cd broker-server && npm run dev`, which runs `tsx src/index.ts --auth-token 995e7c3f6fabc40a1bcd8a6f94dcad0106959c26c5827d2d3b261e1969109bd7`. The broker listens on TCP `localhost:5301` for Godot executor connections and HTTP `localhost:5302` for API calls. Use `Authorization: Bearer 995e7c3f6fabc40a1bcd8a6f94dcad0106959c26c5827d2d3b261e1969109bd7` with HTTP requests, target the `Hollowfen` executor or `/Users/quan/MyFile/GameProject/hollowfen/` project path, and prefer the structured Godot endpoints `POST /api/godot/tree`, `/api/godot/node/get`, `/api/godot/node/set`, and `/api/godot/node/call`; use `/api/execute` only when a custom GDScript snippet is needed.

## Coding Style & Naming Conventions
Use UTF-8 files. Follow Godot GDScript conventions: tabs for indentation, `snake_case` for variables, functions, scenes, and files, and `PascalCase` for `class_name` declarations such as `CharacterBase` or `TestHelper`. Prefer exported variables for tunable gameplay values and keep node paths stable when tests or scenes depend on them. Keep assets named by role and state, for example `knight_spritesheet_clean.png` or `test_tutorial_level_scene.gd`.

## Testing Guidelines
Tests are lightweight GDScript scripts using `tests/test_helper.gd`. Name new suites `test_<feature>.gd`, keep checks explicit with labels, and return the helper summary exit code. Add or update tests when changing combat routing, character state, scene wiring, puzzle behavior, or UI state. Run the affected suite first, then run all `tests/test_*.gd` before submitting broader gameplay changes.

## Commit & Pull Request Guidelines
Recent history uses concise Conventional Commit prefixes such as `feat:`, `fix:`, and `tweak:`. Keep commits focused and describe player-visible behavior or technical intent, for example `fix: restore knight double jump timing`. Pull requests should include a short summary, test commands run, linked issue or design note when relevant, and screenshots or clips for visual, animation, or level-layout changes. Do not commit `.godot/` cache output or local secrets.
