# Roadmap — Death Island

## Implementation ledger — 2026-10-30

The original milestone checklists below describe the full product target. They
are not completion certificates. The repository now has a playable illustrated
2.5D implementation spanning M1/M2 and an initial M3 art pass (ADR 003).

Implemented: real input mappings and touch ownership; survival/combat/gathering;
atomic crafting; 25 item definitions and 15 recipes; five authored regions; four
enemy archetypes; processing stations and shelter pieces; three quest branches;
trust, one recruitable companion and three endings; validated save slots/backups;
menus, adjustable controls, render-distance/FPS settings, original synthesized SFX
and bounded local frame-time capture. Original character/prop illustration,
gameplay-driven action frames, fixed orthographic camera, textured regions,
completed shelter art and six README gameplay captures are implemented.

Automated evidence and build results are recorded in `docs/audits/BUILD_VERIFICATION.md`.
Do not infer device performance from headless tests or software-rendered screenshots.

COMP-01 utility implementation is verified: bounded carry/gather orders, return
transactions, combat interruption and persistence. See [acceptance evidence](audits/COMP-01.md).

Still required for the **entire M0–M4 roadmap**:

* M0: verify the rewritten workflow on GitHub after publishing changes.
* M1: install and play the acceptance loop on the target Android phone, including
  multitouch, lifecycle/backgrounding and real save/relaunch.
* M2: production-quality terrain/caves and navigation, companion route/balance playtesting,
  complete equipment-slot content, quest-failure paths and broader balance testing.
* M3: finished character animation and environment art, music/ambience, richer combat
  feedback, freely repositionable touch controls/text scaling, effect-quality tiers,
  thermal/battery APIs, percentile telemetry, sustained and multi-device profiling.
* M4: release signing/AAB, current Play requirements (including native-library page
  alignment), low-storage/pause-resume/long-session validation, release review.

The build is labeled `0.3.0-dev`; release certification still requires those gates.

### Original milestone plan

| Milestone | Focus | Duration | Status |
|-----------|-------|----------|--------|
| **M0** | Repository & Build Foundation | 1-2 weeks | Local implementation; remote CI pending |
| **M1** | Playable Survival Vertical Slice | 4-6 weeks | Automated checks; device gate pending |
| **M2** | Progression & World Systems | 6-8 weeks | Playable prototype implementation |
| **M3** | Presentation & Mobile Optimization | 4-6 weeks | Initial presentation; profiling pending |
| **M4** | Release Candidate | 2-4 weeks | ⏳ Planned |

---

## M0 — Repository & Build Foundation (Weeks 1-2)

**Goal**: Establish canonical repo, CI/CD, and bootable Godot project.

### Deliverables
- [x] GitHub repository `death-island` (private)
- [x] README.md, CONTRIBUTING.md, LICENSE (MIT), .gitignore
- [x] AGENTS.md (project-specific engineering rules)
- [x] docs/PRD.md, ARCHITECTURE.md, ROADMAP.md, QUALITY_GATES.md
- [x] docs/DECISIONS/ directory
- [x] tests/ directory
- [ ] Minimal Godot 4 project (`project.godot`, `Main.tscn`)
- [ ] GitHub Actions CI workflow (lint, typecheck, headless test)
- [ ] Android export preset configured (debug)
- [ ] Reproducible build documented

### Acceptance Criteria
- Fresh clone → `godot --path . --headless` launches without error
- CI passes on PR
- Debug APK builds (even if not installable yet)
- All docs present and cross-linked

### Tasks
- [x] Create GitHub repo and clone
- [x] Write all M0 documentation
- [ ] Create Godot project structure
- [ ] Create Main.tscn with autoloads
- [ ] Configure Android export preset
- [ ] Write GitHub Actions workflow
- [ ] Test headless launch
- [ ] Push to main, verify CI

---

## M1 — Playable Survival Vertical Slice (Weeks 3-8)

**Goal**: End-to-end playable core loop on target device.

### Core Systems
| System | Key Features |
|--------|--------------|
| Player Controller | Third-person, CharacterBody3D, move_and_slide, stamina sprint |
| Camera | Orbit around player, touch drag, zoom, collision avoidance |
| Touch Input | Virtual joystick (left), action buttons (right), haptic feedback |
| Health/Stamina | Damage, regen, stamina drain (sprint, dodge, attack) |
| Survival | Hunger, thirst decay; starvation damage; consumable restoration |
| Gathering | Interact with resource nodes (Wood, Stone), tool requirements |
| Inventory | Grid-based, stack limits, weight capacity, quick slots (4) |
| Crafting | Recipe validation, station requirement, result generation |
| Combat | Light/heavy attack, dodge (i-frames), enemy hitboxes, knockback |
| Enemy AI | Patrol → Detect → Chase → Attack → Flee/Die, simple state machine |
| HUD | Health/stamina bars, hunger/thirst icons, quick slots, mini-map placeholder |
| Pause Menu | Resume, Save, Settings, Quit to Main Menu |
| Save/Load | Binary format, versioned, checksum, 10 slots + quicksave + autosave |

### Content (Minimum Viable)
- [ ] 1 island test scene (50×50m, flat terrain, placeholder meshes)
- [ ] 2 resource node types: Tree (Wood), Rock (Stone)
- [ ] 1 crafting recipe: Stone Axe (2 Wood + 3 Stone)
- [ ] 1 enemy: Hostile Boar (patrol, charge attack, drops Meat + Hide)
- [ ] Player model: capsule placeholder + simple animations
- [ ] Basic UI: HUD, inventory grid, crafting list, pause overlay

### Acceptance Scenario (Must Work on Device)
1. Launch → playable in < 10s
2. Move with joystick, rotate camera with touch drag
3. Approach tree → gather Wood (2+)
4. Approach rock → gather Stone (2+)
5. Open inventory → see stacked items
6. Craft Stone Axe → consumes resources, adds to inventory
7. Encounter boar → fight (attack, dodge, stamina management)
8. Defeat boar → collect Meat, Hide
9. Pause → Save Game → Exit app
10. Relaunch → Load save → verify all state persisted

### Tasks by Priority
| Priority | Task |
|----------|------|
| P0 | Project structure, autoloads, Main.tscn |
| P1 | Player movement + camera (CharacterBody3D) |
| P1 | Touch input: joystick + camera drag |
| P1 | Touch input: action buttons (attack, dodge, interact) |
| P2 | Health, stamina, hunger, thirst components |
| P2 | Resource nodes + gathering interaction |
| P2 | Inventory system (data + UI) |
| P3 | Crafting system (data + UI) |
| P3 | Enemy AI (state machine) + combat |
| P3 | HUD + Pause menu |
| P4 | Save/Load system |
| P4 | Integration testing + device verification |

---

## M2 — Progression & World Systems (Weeks 9-16)

**Goal**: Expand world, add progression depth, NPCs, quests.

### World
- [ ] Handcrafted island: Beach, Jungle, Cliffs, Cave, Ruins (5 regions)
- [ ] Distinct visual themes per region (color palette, foliage, props)
- [ ] Region-specific resources and enemies
- [ ] Fast travel points (unlocked via exploration)

### Systems
| System | Additions |
|--------|-----------|
| Day/Night | Time cycle (24 min = 1 day), visibility changes, night enemies |
| Shelter | Build foundation, walls, roof, door; provides rest/save bonus |
| Processing | Campfire (cook meat), Workbench (advanced tools), Forge (metal) |
| Enemies | 3+ types: Boar, Wolf, Spider, Tribal Warrior (varied AI) |
| Loot Tables | Per-enemy, per-region, weighted drops |
| Quest Framework | State machine: Offered → Active → Complete/Failed |
| NPC Dialogue | Branching dialogue, trust tracker, relationship tiers |
| Companions | Recruit → Follow → Assist (combat, gather, carry) |
| Equipment | Slots: Weapon, Head, Chest, Hands, Feet, Accessory×2 |
| Progression | Durability, upgrade paths, set bonuses |
| Save v2 | Version migration, corruption recovery, backup slots |

### Acceptance
- Explore all 5 regions, gather region-specific resources
- Build shelter, cook food, craft advanced tools
- Complete 3+ quests with branching outcomes
- Recruit 1 companion, verify follow/assist behavior
- Survive 3+ day/night cycles
- Save/load across versions (migration test)

---

## M3 — Presentation & Mobile Optimization (Weeks 17-22)

**Goal**: Visual polish, performance optimization, scalable settings.

### Art & UI
- [ ] Original art direction: stylized low-poly, cohesive palette
- [ ] Consistent UI system: theming, animations, transitions
- [ ] Combat telegraphs: windup animations, screen shake, hit pause
- [ ] Hit effects: particles, numbers, sound, knockback direction
- [ ] Animation transitions: blend trees, procedural layering

### Optimization
- [ ] Scalable render distance (Low/Medium/High)
- [ ] Effect quality tiers (Particles, Shadows, Post-processing)
- [ ] Texture/mesh budgets enforced (see ARCHITECTURE.md)
- [ ] Object pooling: projectiles, effects, enemies, UI elements
- [ ] Loading indicators: progress, tips, async scene loading
- [ ] Graceful recovery: OOM handling, missing resource fallbacks

### Telemetry (Local Only)
- [ ] FPS graph (session)
- [ ] Frame time percentiles (p50, p95, p99)
- [ ] Memory usage (script, texture, mesh)
- [ ] Battery estimate (Android API)
- [ ] Thermal state (Android API)
- [ ] Export to CSV for analysis

### Device Profiling
- [ ] Test on Realme Narzo N53 (primary)
- [ ] Test on 2+ additional devices (different GPU/CPU)
- [ ] Document results: settings → FPS, memory, thermals
- [ ] Define minimum/recommended device specs

---

## M4 — Release Candidate (Weeks 23-26)

**Goal**: Production-ready build, validated on target device.

### Validation Checklist
- [ ] Fresh install from APK → launches, no crashes
- [ ] Save/load: 10 slots, quicksave, autosave, corruption recovery
- [ ] App pause/resume: background 1hr → resume correct state
- [ ] Low storage: < 100MB free → graceful handling
- [ ] Target device: 30 min playtest, no thermal throttle
- [ ] Memory: no growth > 50MB over 1hr
- [ ] Touch: no ghost touches, dead zones, conflicts
- [ ] Battery: < 15% drain per hour
- [ ] All M1-M3 acceptance scenarios pass

### Release Artifacts
- [ ] Signed release AAB (Play Store)
- [ ] Signed release APK (direct/sideload)
- [ ] Release notes (features, known issues, credits)
- [ ] Build checklist (versions, keys, signing, verification)
- [ ] Asset attribution file (THIRD_PARTY_LICENSES.md)

### Known Issues Tracking
- Document all unresolved bugs with severity
- Decision: ship with / fix / defer to post-launch

---

## Post-Launch (Not in Scope for M0-M4)

- Content updates (new regions, enemies, quests)
- Quality-of-life improvements from player feedback
- Performance optimization for lower-end devices
- Localization (start with English only)
- Accessibility enhancements
- Steam/desktop port evaluation

---

## Dependency Graph

```
M0 ──┬──► M1 ──┬──► M2 ──┬──► M3 ──┬──► M4
     │         │         │         │
     ▼         ▼         ▼         ▼
  Repo      Core      World     Polish   Ship
  + CI      Loop      + NPCs    + Perf   Build
```

**Critical Path**: M0 → M1 → M2 → M3 → M4 (no parallelization of milestones)

**Parallel Within Milestone**: Systems can be developed in parallel (e.g., inventory UI + crafting data)

---

## Risk Register

| Risk | Milestone | Mitigation |
|------|-----------|------------|
| Godot Android export broken | M0 | Test export immediately, pin template version |
| Touch controls unusable | M1 | Playtest weekly, iterate layout |
| Performance < 30 FPS | M1-M3 | Profile early, Compatibility renderer, strict budgets |
| Save corruption | M1 | Versioned binary, checksums, automated corruption tests |
| Scope creep | All | Hard milestone gates, non-goals documented |

---

*Update this roadmap at each milestone boundary. Dates are estimates; accept criteria drive completion.*
