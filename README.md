# Death Island

An atmospheric, mature survival RPG for Android about isolation, adaptation, dangerous encounters, trust, and the cost of survival.

## Overview

Death Island is an original Android survival RPG built with Godot 4, targeting the Realme Narzo N53 (Android 15, 6GB RAM, ARM64). The game features offline-first single-player gameplay with touch-native controls.

### Pillars

- **Exploration**: Discover distinct island regions, landmarks, hidden resources, and environmental clues
- **Survival**: Manage health, stamina, supplies, shelter, and equipment
- **Crafting**: Transform gathered resources into tools, weapons, workstations, and upgrades
- **Combat**: Readable enemy attacks, dodge timing, stamina trade-offs, hit feedback, and meaningful progression
- **Characters**: Original NPCs with motivations, dialogue, trust, quests, and companion behavior
- **Consequences**: Decisions alter relationships, resources, quest outcomes, and access to locations
- **Mature Tone**: Dark themes and optional adult-oriented narrative for clearly adult fictional characters
- **Mobile-First Usability**: Large touch targets, readable text, responsive landscape layouts, configurable controls, and a pause system

## Target Platform

- **Device**: Realme Narzo N53
- **OS**: Android 15 (API 35)
- **RAM**: 6 GB
- **Architecture**: ARM64
- **Engine**: Godot 4.x with Compatibility renderer
- **Orientation**: Landscape

## Performance Goals

- Stable 30 FPS on target device
- Conservative draw calls and memory usage
- Texture atlases where appropriate
- Object pooling for projectiles/effects
- Bounded enemy counts

## Development Status

**Current Milestone**: M0 — Repository and Build Foundation

See [ROADMAP.md](docs/ROADMAP.md) for detailed milestones.

## Building

### Prerequisites

- Godot 4.3+ (standard or .NET version)
- Android SDK with API 35
- JDK 21
- Gradle wrapper (included)

### Editor

```bash
# Open in Godot editor
godot --path .
```

### Export (Android)

```bash
# Debug APK
godot --headless --export-release "Android" build/death-island.apk

# Release AAB (for Play Store)
godot --headless --export-release "Android" build/death-island.aab
```

## Project Structure

```
death-island/
├── .github/workflows/     # CI/CD pipelines
├── docs/                  # Design documents
│   ├── ARCHITECTURE.md
│   ├── DECISIONS/         # Architecture Decision Records
│   ├── PRD.md
│   ├── QUALITY_GATES.md
│   └── ROADMAP.md
├── tests/                 # Test scripts and fixtures
├── src/                   # Godot project source
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   ├── resources/
│   └── assets/
├── AGENTS.md              # Project-specific engineering rules
├── CONTRIBUTING.md
├── LICENSE
└── .gitignore
```

## License

See [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

*Death Island is an original game inspired by survival-RPG mechanics. All characters, story, assets, and code are original creations.*