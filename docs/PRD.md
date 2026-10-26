# Product Requirements Document — Death Island

## Vision Statement

Death Island is an atmospheric, mature survival RPG about isolation, adaptation, dangerous encounters, trust, and the cost of survival. Players explore a mysterious island, manage scarce resources, craft tools and shelter, fight hostile creatures, and interact with original NPCs whose fates intertwine with the player's choices.

## Target Audience

- **Primary**: Adult players (17+) who enjoy survival RPGs, atmospheric exploration, and meaningful choices
- **Platform**: Android mobile (Realme Narzo N53 class devices)
- **Play Session**: 15-45 minutes typical, supports longer sessions

## Core Gameplay Loops

### Primary Loop (Minute-to-Minute)
1. **Explore** → Move through island regions, discover resources/landmarks
2. **Gather** → Collect wood, stone, fiber, food, water
3. **Manage** → Monitor health, stamina, hunger, thirst, inventory weight
4. **Craft** → Transform resources into tools, weapons, shelter components
5. **Survive** → Fight/avoid enemies, manage environmental threats

### Secondary Loop (Session-to-Session)
1. **Progress** → Upgrade equipment, expand shelter, unlock recipes
2. **Connect** → Meet NPCs, build trust, accept quests
3. **Decide** → Make choices affecting relationships, access, outcomes
4. **Persist** → Save progress, resume later

### Meta Loop (Long-term)
1. **Master** → Learn island secrets, optimal routes, enemy patterns
2. **Conclude** → Reach narrative endings based on choices

## Feature Requirements

### M0 — Foundation (Current)
- [ ] GitHub repository with CI/CD
- [ ] Godot project booting to main scene
- [ ] Basic project structure documented
- [ ] Automated checks passing

### M1 — Vertical Slice (Playable Core)
- [ ] Third-person player controller + camera
- [ ] On-screen movement joystick (left)
- [ ] Touch camera control + action buttons (right)
- [ ] Player health, stamina, hunger, thirst
- [ ] Two gatherable resources (e.g., Wood, Stone)
- [ ] Inventory with stack limits, weight system
- [ ] One crafting recipe (e.g., Stone Axe)
- [ ] One enemy with AI, health, attack, loot
- [ ] Basic HUD (health, stamina, hunger, thirst, quick slots)
- [ ] Pause/settings menu
- [ ] Save/load (player state, inventory, world state)

### M2 — Progression & World
- [ ] Handcrafted island with 3-5 distinct regions
- [ ] Day/night cycle (after profiling)
- [ ] Shelter building + resource processing (campfire, workbench)
- [ ] 3+ enemy types with varied behaviors
- [ ] Loot tables per enemy/region
- [ ] Quest framework + original NPC dialogue
- [ ] Companion recruitment + follow/assist behavior
- [ ] Equipment slots + progression (durability, upgrades)
- [ ] Versioned, validated save data + corruption recovery

### M3 — Presentation & Optimization
- [ ] Original art direction + consistent UI system
- [ ] Combat telegraphs, hit effects, animation transitions, audio
- [ ] Scalable render distance/effects settings
- [ ] Texture/mesh budgets documented
- [ ] Object pooling (projectiles, effects, enemies)
- [ ] Loading indicators + graceful recovery
- [ ] Local performance telemetry (no PII)
- [ ] Device profiling results documented

### M4 — Release Candidate
- [ ] Validated APK export + installation
- [ ] Fresh install, save/load, pause/resume, low-storage tests
- [ ] Target device testing (Realme Narzo N53)
- [ ] Crash-free, no memory leaks, touch conflicts resolved
- [ ] Thermal performance acceptable
- [ ] Release notes + build checklist
- [ ] Known issues documented

## Non-Goals (Explicitly Out of Scope)

- Multiplayer/co-op
- Procedural world generation
- Modding support
- Advanced graphics (ray tracing, complex shaders)
- Elaborate adult content systems
- Huge open world (keep island small/dense)
- Backend services, analytics, accounts
- VR/AR support
- Desktop/console ports (mobile-first)

## Technical Constraints

| Constraint | Value |
|------------|-------|
| Engine | Godot 4.3+ |
| Language | GDScript (no C#/.NET) |
| Renderer | Compatibility (start) |
| Min Android API | 24 (Android 7.0) |
| Target Android API | 35 (Android 15) |
| Architecture | ARM64 (arm64-v8a) |
| Orientation | Landscape only |
| Storage | Internal app data only (`user://`) |
| Network | None required (offline-first) |
| Permissions | Minimal (vibration, wake lock) |

## Performance Requirements

| Metric | Minimum | Target |
|--------|---------|--------|
| FPS (target device) | 30 | 60 |
| Launch time (cold) | < 10s | < 5s |
| Scene transition | < 3s | < 1s |
| Memory (runtime) | < 1.5 GB | < 1 GB |
| Battery drain (1hr) | < 15% | < 10% |
| Thermal throttling | None at 30 min | None at 60 min |

## Content Guidelines

### Maturity Rating
- Target: **ESRB M (Mature 17+)** / **PEGI 18**
- Dark themes: violence, death, survival horror elements
- Optional romantic/sexual content: **only** between clearly adult fictional characters, with explicit consent mechanics
- No: sexual violence, non-consensual content, exploitation, minors in sexual contexts

### Narrative Principles
- Player agency: choices have visible consequences
- No "game over" for narrative decisions (only survival failure)
- Multiple endings based on trust, resources, exploration
- Environmental storytelling > exposition dumps

### Accessibility
- Scalable UI/text (system font size respected)
- Colorblind-safe palette (validate with simulator)
- Remappable touch controls (position, size, opacity)
- Pause anytime (even in combat)
- Haptic feedback toggle
- Audio sliders per bus

## Success Criteria (M1 Acceptance)

The following scenario must work end-to-end on target device:

1. Launch game → reaches playable state in < 10s
2. Move around island using virtual joystick + camera drag
3. Approach resource nodes → gather **Wood** and **Stone** (2+ each)
4. Open inventory → see items stacked correctly
5. Craft **Stone Axe** from recipe (consumes resources)
6. Encounter enemy → fight using attack/dodge controls
7. Defeat enemy → collect loot (meat, hide)
8. Pause → Save Game → Exit app
9. Relaunch → Load save → verify state persisted (position, inventory, health, world)

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Godot 4 Android export broken | Medium | High | Test export early (M0), pin working template version |
| Performance on target device | High | High | Profile from M1, Compatibility renderer, strict budgets |
| Touch control usability | Medium | High | Playtest early, iterate on joystick/button layout |
| Save corruption | Low | Critical | Versioned binary format, checksums, recovery flow |
| Scope creep | High | Medium | Strict milestone gates, non-goals documented |
| Asset pipeline bottlenecks | Medium | Medium | Procedural/placeholder art first, replace incrementally |

## Dependencies

### Godot Core
- Godot 4.3+ (stable)
- Export templates for Android (same version)

### Third-Party (Minimal)
- None required for M0-M1
- Consider: `gdUnit4` for testing, `Dialogic` for dialogue (evaluate later)

### Android SDK
- Build tools 34+
- Platform tools 35+
- NDK r26+ (for ARM64)

## Milestone Timeline (Estimates)

| Milestone | Duration | Dependencies |
|-----------|----------|--------------|
| M0: Foundation | 1-2 weeks | GitHub, Godot installed |
| M1: Vertical Slice | 4-6 weeks | M0 complete |
| M2: Progression | 6-8 weeks | M1 verified |
| M3: Polish/Optimize | 4-6 weeks | M2 verified |
| M4: Release Candidate | 2-4 weeks | M3 verified |
| **Total** | **17-26 weeks** | — |

---

*This PRD is a living document. Update with each milestone completion.*