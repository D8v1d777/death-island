# Pass 1.5 — safe checkpoint and remote integration

Date: 2026-11-01. Repository: `D8v1d777/death-island`.
Checkout: `/root/death-island-execution`.
Branch: `feat/dave-marie-character-pipeline`.

## Checkpoint and preservation

Starting HEAD: `549590be22469e2801b0639802fd8a88a6a44385`.
Entry state matched Pass 1: eight modified tracked files, twenty untracked files,
and an empty staging area. Every pending change was inspected before staging,
including the four existing documentation captures.

Checkpoint: `3ba92a2ac2f553521955ff3751843391223585d7`
(`chore: checkpoint incomplete Phase 1/2 development foundation`).

All 28 files are now tracked in that explicitly **incomplete development
checkpoint**. Twenty-seven are byte-identical to the backed-up entry contents.
`docs/IMPLEMENTATION_DESIGN.md` only had a trailing space removed at line 119 and
a missing final newline added. Git's staged whitespace check initially reported
that pre-existing space; it passed after normalization. The backup retains the
exact original document. No game behavior was changed in this pass.

The original `PASS1_COMPILATION_RECOVERY.md` remains an unchanged historical
record: its dirty-tree and ahead/behind statements describe the end of Pass 1.
The incomplete switching, persistence, farming and render-validation findings
in that record still apply.

## Recoverable backup

Location: `/root/death-island-pass1.5-backup-20261101/`.

- `history.bundle`: standalone target-branch history through the starting HEAD.
- `working-tree.tar.gz`: exact reviewed 28-file working overlay.
- `manifest.json`: paths, original status, sizes, modes and SHA-256 hashes.
- `tracked.patch`, empty `staged.patch`, and `status.txt`: original Git state.
- `SHA256SUMS`: checksums of those six primary artifacts.
- `checkpoint.bundle`: standalone history through the incomplete checkpoint.
- `RECOVERY.md`: recovery commands and verification details.
- `RESTORE_VERIFIED.txt`: completed recovery-drill record.

Recovery was actually tested by cloning the standalone initial bundle and
extracting its overlay into `/tmp/opencode/death-island-pass15-restore-check`.
HEAD, all 28 hashes, the exact eight-modified/twenty-untracked Git status and
`git fsck --full --no-reflogs` passed. The source contents were rechecked unchanged
after backup. The clone is independent of the original worktrees.

To restore the pre-checkpoint state, use a **new, nonexistent destination**:

```bash
git clone --branch feat/dave-marie-character-pipeline \
  /root/death-island-pass1.5-backup-20261101/history.bundle \
  /tmp/opencode/death-island-recovered
tar -xzf /root/death-island-pass1.5-backup-20261101/working-tree.tar.gz \
  -C /tmp/opencode/death-island-recovered
git -C /tmp/opencode/death-island-recovered status --short
```

For a clean checkpoint recovery, clone `checkpoint.bundle` instead and omit the
overlay. No caches, private saves, signing files, APKs or build directories are
included in the working overlay or new checkpoint.

## Exact commit reconciliation

Fetched remote: `19a7a4743fed6f09cbf04d165b3e20862a46a315`.
Merge base: `a99fb84b3b3e6d8a762fe0021ad9e22db0a732a6`.
Before merging, the histories were three commits ahead / three behind.

Local-only commits, all retained:

1. `b8463e7018bb9e1d7b21a16ebda7b9875446f4fe` — gallery validation recovery.
2. `549590be22469e2801b0639802fd8a88a6a44385` — headless Label3D teardown fix.
3. `3ba92a2ac2f553521955ff3751843391223585d7` — incomplete foundation checkpoint.

Remote-only commits, all integrated:

1. `366cf499b83f3c449b4563a954b02559ae009ee6` — gallery validation/metadata/docs.
2. `be26ba43a39430725b193055f3f726e71dcaa5c8` — feature-branch CI and beta publishing.
3. `19a7a4743fed6f09cbf04d165b3e20862a46a315` — valid gallery fixture revision.

Integration used `git merge --no-ff --no-commit
origin/feat/dave-marie-character-pipeline`, followed by inspection, resolution,
and verification before committing. Both parent histories are preserved.

### Conflict resolution and changed files

The only conflict was `docs/images/gallery.json`. Parsing index stages 2 and 3
proved their complete JSON values identical. Relative to the merge base, both
recovered exactly the same `source_revision`; every capture record and image hash
matched. Remote two-space formatting was retained after this comparison. No
capture was generated or replaced, and no functional conflict required discarding
either implementation.

Changes introduced by the merge relative to the checkpoint:

- `.github/workflows/ci.yml`: reviewed remote branch trigger/publishing job.
- `docs/audits/GALLERY.md`: reviewed remote documentation corrections.
- `docs/images/gallery.json`: semantically identical remote formatting.
- This integration audit.

The remote versions of the gallery validator, test fixture and capture runner
already matched the local fixes and required no additional edits. All six paths
changed by the remote-only commits match the remote tree after resolution.

## Verification actually executed

Before checkpointing and again on the resolved integrated tree:

| Gate | Result |
| --- | --- |
| `python3 tools/check.py` | Passed |
| Python unit tests | 10 passed |
| `gdlint src/scripts src/tests` | No problems |
| `gdformat --check src/scripts src/tests` | 63 files unchanged |
| Godot 4.3 headless editor import | Passed; no script/resource errors |
| Existing gallery files, links, hashes and image decoding | Passed |
| Godot unit suite | 48 passed, 0 failed |
| Gameplay integration suite | 198 passed, 0 failed |
| Recovery integration suite | 75 passed, 0 failed |
| Main-scene launch smoke | Passed |
| Stability integration suite | 42 passed, 0 failed |

Additionally, after resolution, `python3 tools/check.py --clean-import` passed
using a new temporary source copy without the existing `.godot` cache.
The actual standalone stability command was:

```bash
GODOT_SILENCE_ROOT_WARNING=1 timeout 60s godot --headless --path src \
  res://tests/integration/StabilityTestRunner.tscn
```

Each engine/test command used an isolated `XDG_DATA_HOME` under
`/tmp/opencode/death-island-pass15-*`. Normal user saves were not addressed.
Installed Godot was `4.3.stable.official.77dcf97d8`; no dependencies were installed.
Final output was inspected, including the existing `pkg_resources` deprecation
notice and Android build-tools fallback notice (`using 34.0.0`). No test or engine
failure was suppressed. Git whitespace checks and file-preservation checks passed.

Logs: `/tmp/opencode/death-island-pass15-precheck.log`,
`death-island-pass15-prestability.log`, `death-island-pass15-integrated-check.log`,
`death-island-pass15-integrated-stability.log`, and
`death-island-pass15-clean-import.log`.

## Push readiness and scope

The integration retains both histories and supports a normal fast-forward push
relative to the fetched remote SHA; no force push is needed. Nothing was pushed.

**Full CI/beta readiness is not certified.** The retained Dave-default title UI
has no `CharacterChoice`, but `CharacterTestRunner.gd` still accesses that node.
The integrated remote CI invokes `--render-only`, then gallery capture and Android
build; successful builds on this feature branch trigger beta prerelease publishing.
Rendered/capture, Android and remote security jobs were not run in this pass, so
the passing Pass 1 suite is not a claim that this complete CI pipeline will pass.
Resolve the known render-test/UI contract mismatch before expecting a green CI
push or treating the checkpoint as a tester-ready beta.

Only the requested target checkout was operated on. No command inspected or edited
the `/root/death-island` working tree. Git uses the shared repository metadata for
normal target-worktree commits/fetch/merge; its other branch and index were not
operated on. A pre-existing `git count-objects` warning about a worktree metadata
`refs` entry was observed; it was not cleaned or altered.

No artwork generation, new gameplay/biome features, dependency installation,
destructive Git operations or paid external asset calls were performed. The
attached world-expansion dossier remains reference for a later pass.
