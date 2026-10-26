# Quality Gates — Death Island

## Overview

Quality gates are mandatory checks that must pass before code merges to `main` or a milestone is considered complete. Gates are organized by severity: **Blocking** (must pass), **Warning** (review required), **Advisory** (track over time).

---

## Gate Categories

### 1. Code Quality (Blocking)

| Gate | Tool | Threshold | Failure Action |
|------|------|-----------|----------------|
| GDScript Lint | `gdlint` | 0 errors, 0 warnings | Block merge |
| GDScript Format | `godot --format` | No diff after format | Block merge |
| Type Checking | `godot --check-only` | 0 type errors | Block merge |
| Naming Conventions | Custom script | 100% compliance | Block merge |
| No `print()` in prod | Grep check | 0 occurrences in `scripts/` | Block merge |
| No TODO without issue | Grep check | 0 `TODO:` without `#issue` | Block merge |

### 2. Testing (Blocking)

| Gate | Tool | Threshold | Failure Action |
|------|------|-----------|----------------|
| Unit Tests | `gdUnit4` / custom | 100% pass | Block merge |
| Integration Tests | Godot headless | 100% pass | Block merge |
| Core Systems Coverage | Custom | ≥ 80% (crafting, inventory, combat math) | Block merge |
| Save/Load Coverage | Custom | 100% (critical path) | Block merge |

### 3. Build (Blocking)

| Gate | Tool | Threshold | Failure Action |
|------|------|-----------|----------------|
| Godot Project Parses | `godot --headless --check-only` | Success | Block merge |
| Debug APK Builds | Godot export | Success, < 200 MB | Block merge |
| Release APK Builds | Godot export | Success, < 150 MB | Block merge (M3+) |
| Export Preset Valid | Godot export | No missing templates | Block merge |

### 4. Performance (Blocking at M1+, Warning at M0)

| Gate | Metric | Threshold (Target Device) | Failure Action |
|------|--------|---------------------------|----------------|
| FPS (Gameplay) | Average | ≥ 30 FPS | Block merge (M1+) |
| FPS (Menu) | Average | ≥ 60 FPS | Block merge (M1+) |
| Frame Time p99 | 99th percentile | ≤ 50 ms (30 FPS) | Block merge (M1+) |
| Launch Time (Cold) | Startup to playable | ≤ 10 s | Block merge (M1+) |
| Scene Transition | Load time | ≤ 3 s | Block merge (M2+) |
| Memory (Runtime) | Peak RSS | ≤ 1.5 GB | Block merge (M1+) |
| Memory Growth | 1hr playtest | ≤ 50 MB growth | Block merge (M2+) |
| Battery Drain | 1hr playtest | ≤ 15% | Block merge (M3+) |
| Thermal Throttling | 30 min sustained | None | Block merge (M3+) |

### 5. Functional (Blocking per Milestone)

| Milestone | Acceptance Scenario | Verification |
|-----------|---------------------|--------------|
| M0 | Fresh clone → headless launch → CI passes | Automated |
| M1 | 10-step playable scenario (see PRD) | Manual on device |
| M2 | Explore 5 regions, complete 3 quests, recruit companion | Manual on device |
| M3 | Scalable settings work, telemetry exports, profiling done | Manual + automated |
| M4 | Full validation checklist (see ROADMAP) | Manual on device |

### 6. Security (Blocking)

| Gate | Check | Threshold | Failure Action |
|------|-------|-----------|----------------|
| No Secrets | `git-secrets` / `truffleHog` | 0 findings | Block merge |
| No Dangerous APIs | Grep: `eval`, `loadstring`, `OS.execute` | 0 in `scripts/` | Block merge |
| Input Validation | Code review | All system boundaries | Block merge |
| Save Validation | Code review | Version + checksum + bounds | Block merge |

### 7. Documentation (Warning)

| Gate | Check | Threshold | Failure Action |
|------|-------|-----------|----------------|
| Public API Docstrings | Custom script | 100% of public classes/methods | Warning |
| ADR for Arch Changes | `docs/DECISIONS/` | 1 ADR per significant change | Warning |
| Roadmap Current | Manual | Milestones match reality | Warning |
| Asset Provenance | `docs/research/asset-provenance.md` | All assets documented | Warning (M3+) |

---

## CI/CD Pipeline

### GitHub Actions: `.github/workflows/ci.yml`

```yaml
name: CI
on: [push, pull_request]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Godot
        uses: ./.github/actions/setup-godot
      - name: Lint
        run: gdlint src/
      - name: Format Check
        run: godot --headless --format --check-only src/
      - name: Type Check
        run: godot --headless --check-only src/
      - name: Unit Tests
        run: godot --headless --script tests/unit/run_tests.gd
      - name: Integration Tests
        run: godot --headless --script tests/integration/run_tests.gd
      - name: Build Debug APK
        run: godot --headless --export-release "Android" build/death-island-debug.apk
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: debug-apk
          path: build/death-island-debug.apk

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Secret Scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
      - name: Dangerous API Check
        run: |
          ! grep -r "eval\|loadstring\|OS\.execute" src/ --include="*.gd" || exit 1
```

### Required Status Checks (Branch Protection)

Configure in GitHub → Settings → Branches → `main` → Branch protection rules:

- [ ] `lint-and-test` (required)
- [ ] `security` (required)
- [ ] Require linear history
- [ ] Require 1 approval
- [ ] Dismiss stale reviews
- [ ] No force push

---

## Local Verification Commands

Run before pushing:

```bash
# 1. Format & Lint
godot --headless --format src/
gdlint src/

# 2. Type Check
godot --headless --check-only src/

# 3. Unit Tests
godot --headless --script tests/unit/run_tests.gd

# 4. Integration Tests (if Godot headless available)
godot --headless --script tests/integration/run_tests.gd

# 5. Build Test
godot --headless --export-release "Android" build/test.apk

# 6. Security Scan
trufflehog filesystem . --no-verification
```

---

## Milestone-Specific Gates

### M0 — Foundation
- [ ] All Code Quality gates pass
- [ ] All Build gates pass
- [ ] CI pipeline green
- [ ] Headless launch verified
- [ ] Documentation complete

### M1 — Vertical Slice
- [ ] All M0 gates +
- [ ] All Performance gates (Blocking)
- [ ] All Functional gates (M1 acceptance scenario)
- [ ] Save/Load 100% coverage
- [ ] Device test on Realme Narzo N53 (or equivalent)

### M2 — Progression
- [ ] All M1 gates +
- [ ] Memory growth gate
- [ ] Save migration test (v1 → v2)
- [ ] Quest/Dialogue system tests

### M3 — Polish
- [ ] All M2 gates +
- [ ] Battery drain gate
- [ ] Thermal throttling gate
- [ ] Telemetry export verified
- [ ] Multi-device profiling documented

### M4 — Release Candidate
- [ ] All M3 gates +
- [ ] Full validation checklist (ROADMAP M4)
- [ ] Signed release builds
- [ ] Release notes complete
- [ ] Known issues documented

---

## Gate Enforcement

### Automated (CI)
- Code Quality, Testing, Build, Security → **Required status checks**
- Failures block merge automatically

### Manual (PR Review)
- Performance (device testing)
- Functional (acceptance scenarios)
- Documentation completeness

### Self-Certification (Per Milestone)
At milestone completion, lead engineer certifies:

```markdown
## Milestone M{num} Completion Certificate

**Date**: YYYY-MM-DD
**Commit**: <sha>
**Branch**: <branch>
**Device Tested**: Realme Narzo N53 (Android 15)

### Gates Passed
- [ ] Code Quality
- [ ] Testing
- [ ] Build
- [ ] Performance (on device)
- [ ] Functional (acceptance scenario)
- [ ] Security
- [ ] Documentation

### Known Issues
1. Issue description — Severity — Decision (ship/fix/defer)

### Sign-off
Lead: <name>
```

---

## Escalation

If a blocking gate fails but the team believes it's a false positive or acceptable risk:

1. Document the rationale in the PR
2. Get explicit approval from lead engineer
3. Create follow-up issue to address properly
4. **Never** bypass without documented exception

---

## Metrics Dashboard (Tracking Over Time)

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Avg FPS (device) | ≥ 30 | — | — |
| p99 Frame Time | ≤ 50ms | — | — |
| Launch Time | ≤ 10s | — | — |
| Memory Peak | ≤ 1.5GB | — | — |
| APK Size (release) | ≤ 150MB | — | — |
| Test Coverage (core) | ≥ 80% | — | — |
| Save/Load Success | 100% | — | — |
| Crash-Free Sessions | 100% | — | — |

*Update at each milestone. Use for go/no-go decisions.*

---

*Quality gates are not optional. They exist to prevent known failure modes. If a gate feels too strict, propose a change with data — don't ignore it.*