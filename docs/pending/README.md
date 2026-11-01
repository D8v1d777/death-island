# Pending Work Ledger

This folder is the durable queue for work that is blocked, incomplete, or not yet verified. Completed work must be removed from this queue only after its acceptance checks pass and evidence is recorded in the relevant audit or roadmap.

## Status key

- **BLOCKED** — cannot proceed with the current input or tool path; a safe replacement path is documented.
- **READY** — implementation can proceed without waiting for new input.
- **NEEDS-SPEC** — only the explicitly missing design detail must be recovered; do not invent it.
- **DEVICE-GATE** — implementation exists, but target-device acceptance remains outstanding.

## Current queue

| ID | Work | Status | Evidence / next action |
|---|---|---|---|
| ART-01 | Convert the blocked character concept into production art | BLOCKED | See [ART-01 reference conversion](ART-01-reference-conversion.md). Preserve the intended character through a fresh, non-explicit production brief rather than retrying the rejected source. |
| REL-01 | Relationship progression and marriage | READY | Current quest data tracks general trust and recruitment, but has no relationship stages, proposal state, or marriage state. Build explicit mutual-consent progression for adult characters and persist it safely. |
| STORY-01 | Make Dave the playable protagonist and update the opening | NEEDS-SPEC | Known requirement: Dave is the protagonist and ends up on the island after being struck. The rest of the incident description was not present in the implementation handoff; recover the full wording before writing the cause, sequence, or antagonist. |
| ART-02 | Finish character animation and production-ready 2.5D assets | READY | Current illustrated actors use limited action frames. Build genuine idle/move/gather/attack/hit/death animation sets and verify atlas frame mapping. Convert approved character sheets into usable sprite atlases or rigged models; do not ship concept sheets as runtime actors. |
| DEVICE-01 | Verify the current build on the target Android device | DEVICE-GATE | Follow `docs/ROADMAP.md` and `docs/audits/BUILD_VERIFICATION.md`. Automated/headless checks are not device acceptance. |

## Execution order

COMP-01 implementation passed its automated acceptance gates; evidence and
limitations are in [COMP-01 audit](../audits/COMP-01.md). Device acceptance remains DEVICE-01.

1. Keep the recovered Godot project and CI files intact; run the existing quality gates before feature work.
2. Complete COMP-01 with tests for gather/carry, inventory capacity, combat interruption, and save/reload.
3. Implement REL-01 on top of a reliable companion interaction flow.
4. Resolve STORY-01 from the complete story brief and then update the title/menu, quest dialogue, save metadata if needed, and README.
5. Resume ART-01 using the documented safe workflow, then complete ART-02.
6. Run device acceptance and update the audit with observed results.

## Repository integrity rule

Never commit a character-reference or asset-only change if the resulting tree unexpectedly removes `src/project.godot`, `src/scenes/`, `src/scripts/`, `src/tests/`, `tools/`, `.github/`, or the project documentation. Run a recursive tree check and inspect the changed-file list before advancing the branch.
