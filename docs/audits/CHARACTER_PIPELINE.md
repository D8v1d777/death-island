# Dave and Marie character pipeline

## Runtime wiring

- The player scene exposes a `character_id` export with `dave` and `marie` choices. Dave remains the safe default.
- `CharacterRoster.gd` is the canonical ID/display-name/art-key registry and normalizes unknown IDs to Dave.
- `Art.tres` maps the IDs to dedicated runtime strips: Dave uses `Dave.svg`; Marie uses `Marie.svg`. Existing `survivor` and `mara` keys remain intact so NPCs and old content do not break. Both new strips are 2048×448 (eight 256×448 frames), with distinct character palettes and their own named assets.
- `IllustratedActor` resolves a character ID before constructing its Sprite3D. Existing movement/action timing and simulation logic remain unchanged.
- Unit tests verify ID normalization, fallback behavior, and both texture registrations.

## Important art limitation

The two previously committed JPEG reference-sheet files were malformed binary copies (Godot could not decode them during a clean import), so they have been removed from this feature branch to restore deterministic imports. The source reference images supplied in chat are not available as valid binary files through the current GitHub text-file interface. Dedicated Dave and Marie vector strips are now registered and the malformed JPEGs are gone. These strips were derived from the repository’s existing Survivor/Mara vector geometry with differentiated palettes; they are an integration-ready interim art pass, **not** verified faithful conversions of the missing approved reference sheets.

## Next art gate

Restore the original approved full-resolution Dave and Marie reference images using binary-safe Git blob uploads. Revise the interim strips to match those references (face, hair, clothing, silhouette, and palette), then add import/render snapshots for both characters and verify their actions on the target Android device before claiming final character-art completion.

## Stabilization work verified in this execution

Source change `649595c` adds title-screen Dave/Marie selection (rather than only an
Inspector setting), canonical HUD names, default identity for legacy saves, and
runtime texture-size/missing-resource fallback. Loaded IDs and textures agree.
New-game and load flows preserve selection without changing save version 2.

`python3 tools/check.py --render-only` passed **40 character assertions**: real
title-menu selection, dedicated texture binding, 2048x448/eight-cell dimensions,
transparent strip corners, supported action mappings, save/reload for both IDs,
legacy/invalid identity handling, and missing/wrong-sized strip fallback.
Actual 1280x720 snapshots for both were generated and inspected at full size:
`build/screenshots/character-dave.png` and `character-marie.png`. They show the live
world/UI and the respective interim palette, with no missing textures or clipped
actor. These are not faithful-original-art approval. Idle and dodge are held poses;
walking uses two frames, other actions use a single existing pose plus procedural
bobbing. Dedicated run, heavy, hit and death drawings remain missing.

## Reference recovery evidence

The historical staging payloads were inspected without executing their one-shot
installer or submitting images to a processor:

| Identity | Historical input | Decoded transport bytes | Result |
|---|---|---:|---|
| Dave | `fea176b:.github/character-source/DAVE_PRODUCTION_CHARACTER_BIBLE.jpg.b64` | 5096 | Byte-identical to removed corrupt blob `19b47052816808b48d92cd97085028dc04828084` |
| Marie | `d204f37:.github/character-source/MARIE_PRODUCTION_CHARACTER_BIBLE.jpg.b64` | 4500 | Byte-identical to removed corrupt blob `b5f1aa7a6797aae05f505e477542942600d353db`, previously installed under the mistaken ELLIE filename |

Those payloads are not recovered originals; restoring them would restore the known
import failure. The fetched master/feature histories and known branches contain no
distinct valid approved source. Targeted Dave/Marie filename searches under `/root`
found no source JPEG/PNG/WebP. Read-only OpenCode database metadata showed **zero
file-attachment records for Death Island sessions**. No connected file-source tool
is available in this harness. Further GitHub branch/issue/comment metadata requests
encountered TLS handshake timeouts; unavailable remote attachments are not claimed
exhaustively inspected. Reference-recovery delegation also hit the prior image
policy block, and that route was stopped.

**Remaining required input:** the two original approved Dave and Marie image files,
or accessible original attachment URLs. No face/hair/clothing/silhouette fidelity
claim is possible from the interim SVG derivatives. No blocked image was retried.
