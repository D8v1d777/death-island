# AGENTS.md — Death Island Project-Specific Engineering Rules

This file extends the global CLAUDE.md with project-specific conventions and rules for Death Island.

## Project Context

- **Game**: Death Island — Android survival RPG
- **Engine**: Godot 4.3+, GDScript
- **Target**: Realme Narzo N53 (Android 15, 6GB RAM, ARM64)
- **Renderer**: Compatibility (start), Forward+ (profile before enabling)
- **Orientation**: Landscape only

## Architecture Rules

### Layer Separation (Strict)

```
UI Layer (scenes/ui/)
    ↓ signals/calls
Gameplay Systems (scripts/systems/)
    ↓ uses
Data Definitions (resources/definitions/)
    ↓ persists
Save System (scripts/save/)
```

**Never** let UI directly mutate game state. UI emits intent signals; systems apply changes.

### Script Organization

```
scripts/
├── autoloads/          # Global singletons (GameManager, SaveManager, AudioManager)
├── components/         # Reusable node components (Health, Inventory, Interactable)
├── systems/            # Gameplay systems (Combat, Crafting, Survival, AI)
├── entities/           # Entity scripts (Player, Enemy, NPC, ResourceNode)
├── ui/                 # UI-specific logic (HUD, Menus, InventoryUI)
├── data/               # Data classes, enums, constants
└── utils/              # Pure utility functions (math, serialization, validation)
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scenes | PascalCase, `.tscn` | `PlayerController.tscn` |
| Scripts | PascalCase, `.gd` | `PlayerController.gd` |
| Resources | PascalCase, `.tres` | `ItemDefinition.tres` |
| Autoloads | PascalCase, `Global` suffix | `GameManagerGlobal` |
| Signals | past_tense, snake_case | `health_changed`, `item_crafted` |
| Groups | plural, snake_case | `enemies`, `resource_nodes` |
| Export vars | PascalCase for resources | `@export var item_definition: ItemDefinition` |

### Data-Driven Design

All game content **must** be defined in resources, not hardcoded:

- Items → `resources/definitions/items/`
- Recipes → `resources/definitions/recipes/`
- Enemies → `resources/definitions/enemies/`
- Quests → `resources/definitions/quests/`
- Dialogue → `resources/definitions/dialogue/`

Scripts reference these via `@export` or resource loading.

## Godot-Specific Rules

### Scene Tree

- One root `Main.tscn` with autoloads
- Gameplay scenes instanced under `/root/GameWorld`
- UI scenes instanced under `/root/UILayer` (CanvasLayer)
- No logic in root scene — delegate to autoloads

### Input Handling

- Use InputMap actions, not raw key/scancode checks
- Define actions in `project.godot` → `[input]`
- Mobile touch: virtual joystick + action buttons
- Support gamepad as secondary input

### Resource Management

- Preload heavy resources in background during loading screens
- Use `ResourceLoader.load_threaded_request()` for async
- Unload unused scenes with `QueueFree()` + `call_deferred("free")`
- Texture atlases for UI and particle effects

### Physics

- Fixed timestep: 60 Hz (default)
- Player movement: `CharacterBody3D` with `move_and_slide()`
- Enemies: `CharacterBody3D` or `RigidBody3D` (kinematic mode)
- Collision layers defined in `project.godot` → `[layer_names/3d_physics]`

### Audio

- Bus layout: Master → [Music, SFX, UI, Ambience, Voice]
- Stream large music files, sample short SFX
- Use `AudioStreamPlayer3D` for positional, `AudioStreamPlayer` for 2D
- Volume controlled via autoload `AudioManagerGlobal`

## Mobile-Specific Rules

### Touch Controls

- Minimum touch target: 48dp (≈72px at 160dpi)
- Virtual joystick: left screen, 120px radius
- Action buttons: right screen, 80px minimum
- Haptic feedback on significant actions (Godot `Input.vibrate_handheld()`)

### Performance Budgets (Target Device)

| Metric | Budget |
|--------|--------|
| Draw calls | < 100 |
| Triangles/frame | < 50k |
| Texture memory | < 512 MB |
| Script memory | < 100 MB |
| Frame time (30 FPS) | < 33 ms |
| Frame time (60 FPS) | < 16 ms |
| APK size (debug) | < 200 MB |
| APK size (release) | < 150 MB |

### Orientation

- Landscape only: `orientation="landscape"` in `project.godot`
- Handle rotation changes gracefully (Godot 4 auto-handles)
- UI anchors relative to screen edges, not absolute positions

### Save System

- Save to `user://save/` (Godot private app data)
- Binary format with version header + checksum
- Auto-save on: scene transition, major milestone, pause
- Manual save: pause menu → Save Game
- Max 10 save slots + 1 quicksave + 1 autosave

## Testing Rules

### Test Structure

```
tests/
├── unit/               # Pure logic tests (no Godot)
├── integration/        # Godot headless tests
├── fixtures/           # Test data, mock resources
└── test_runners/       # Custom test runners if needed
```

### Running Tests

```bash
# Unit tests (GDScript, no engine)
godot --headless --script tests/unit/run_tests.gd

# Integration tests (requires Godot headless)
godot --headless --script tests/integration/run_tests.gd
```

### Test Coverage Targets

- Core systems (crafting, inventory, combat math): ≥ 80%
- Save/load: 100% (critical path)
- UI logic: ≥ 50%

## Git Workflow

### Branch Protection (Configure in GitHub)

- Require PR review (1 approval)
- Require status checks (lint, test, build)
- Require linear history (squash merge)
- Dismiss stale reviews on new commits
- No force push to `main`

### Required Status Checks

- `lint` — GDScript lint (gdlint or custom)
- `typecheck` — GDScript type verification (Godot 4.3+)
- `test-unit` — Unit tests pass
- `test-integration` — Integration tests pass (when runner available)
- `build-android` — Debug APK builds successfully

## Prohibited Patterns

- ❌ Global mutable state outside autoloads
- ❌ `get_node()` with hardcoded paths in `_ready()` (use `@onready` or `@export`)
- ❌ `yield()` / `await` in physics process (use signals or state machines)
- ❌ Direct UI ↔ Data coupling (always via systems)
- ❌ Magic numbers (use constants or exported vars)
- ❌ `print()` in production code (use `LoggerGlobal` with levels)
- ❌ Blocking operations on main thread (use threads/async)
- ❌ Unbounded arrays/lists (pool or cap)
- ❌ Real-time lighting in M0-M2 (baked only)

## Tooling

### Linting

```bash
# gdlint (install via pip)
gdlint src/
```

### Formatting

```bash
# Godot 4.3+ built-in formatter
godot --headless --format src/
```

### Static Analysis

```bash
# Godot 4.3+ type checking
godot --headless --check-only src/
```

## CI/CD

### GitHub Actions Workflows

- `.github/workflows/ci.yml` — PR checks (lint, test, build)
- `.github/workflows/release.yml` — Tagged releases (sign, upload artifacts)
- `.github/workflows/nightly.yml` — Nightly builds (optional)

### Android Build

- Use Godot export templates matching editor version
- Sign with debug keystore for CI, release keystore for production
- Archive APK/AAB as workflow artifacts

## Documentation Maintenance

- Update `docs/ARCHITECTURE.md` when structure changes
- Add ADR to `docs/DECISIONS/` for significant choices
- Keep `docs/ROADMAP.md` milestones current
- Update `docs/QUALITY_GATES.md` when thresholds change

## Emergency Procedures

### Hotfix Process

1. Create `hotfix/*` branch from `main`
2. Fix with minimal change + test
3. Fast-track PR (single reviewer ok for critical)
4. Tag release: `v{major}.{minor}.{patch+1}`

### Rollback

```bash
# Revert last merge
git revert -m 1 <merge-commit-sha>
git push origin main
```

---

*These rules are binding for all contributors. Exceptions require documented ADR.*