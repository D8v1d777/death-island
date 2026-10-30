# Contributing to Death Island

Thank you for your interest in contributing to Death Island! This document outlines the guidelines and expectations for contributors.

## Code of Conduct

This project adheres to a standard of respectful and inclusive collaboration. Harassment, discrimination, or disruptive behavior will not be tolerated.

## Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the guidelines below
4. Run tests and verify the build
5. Submit a pull request

## Development Workflow

### Branching Strategy

- `main` — Production-ready code, protected branch
- `feature/*` — New features and enhancements
- `fix/*` — Bug fixes
- `chore/*` — Maintenance, refactoring, tooling
- `docs/*` — Documentation updates

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add player movement controller
fix: resolve inventory stacking bug
chore: update Godot to 4.3
docs: add architecture decision record for save system
test: add unit tests for crafting system
refactor: extract combat logic into separate module
```

### Pull Request Process

1. Ensure your branch is up to date with `main`
2. Run all quality gates (lint, tests, build)
3. Provide a clear PR description with:
   - What changed
   - Why it changed
   - How to test it
   - Any related issues
4. Request review from at least one maintainer
5. Address review feedback
6. Squash and merge after approval

## Code Standards

### GDScript Style

- Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Use gdformat's tab indentation (see ADR 001)
- PascalCase for class names, snake_case for variables/functions
- Type hints required for all public APIs
- Document public classes and functions with docstrings

### Architecture

- Follow the project architecture defined in [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Separate gameplay logic from UI
- Use data-driven definitions for items, recipes, enemies
- Avoid monolithic scripts; prefer composition over inheritance
- Write tests for testable gameplay logic

### Testing

- Unit tests for pure logic (stat calculations, crafting, inventory)
- Integration tests for system interactions
- Headless Godot tests where possible
- Run tests before committing: `python3 tools/check.py`

### Performance

- Profile on target device (Realme Narzo N53) before optimizing
- Target 30 FPS minimum, 60 FPS stretch goal
- Monitor memory, frame time, thermal throttling
- Use object pooling for frequent allocations

## Documentation

- Update relevant docs with any API or behavior changes
- Add Architecture Decision Records (ADRs) for significant choices
- Document public APIs with docstrings
- Keep [ROADMAP.md](docs/ROADMAP.md) current

## Security

- Never commit secrets, keys, or credentials
- Use Android Keystore for encryption keys
- Validate all external inputs
- Report security issues privately to maintainers

## Asset Guidelines

- Use original assets or assets with verified compatible licenses
- Preserve attribution where required
- Optimize textures for mobile (atlases, appropriate resolution)
- Document asset provenance in `docs/research/asset-provenance.md`

## Questions?

Open an issue for discussion before starting significant work.
