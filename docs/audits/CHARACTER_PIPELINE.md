# Dave and Marie character pipeline

## Runtime wiring

- The player scene exposes a `character_id` export with `dave` and `marie` choices. Dave remains the safe default.
- `CharacterRoster.gd` is the canonical ID/display-name/art-key registry and normalizes unknown IDs to Dave.
- `Art.tres` maps the IDs to runtime sprite strips: Dave uses `Survivor.svg`; Marie uses `Mara.svg`. Existing `survivor` and `mara` keys remain intact so NPCs and old content do not break.
- `IllustratedActor` resolves a character ID before constructing its Sprite3D. Existing movement/action timing and simulation logic remain unchanged.
- Unit tests verify ID normalization, fallback behavior, and both texture registrations.

## Important art limitation

`DAVE_PRODUCTION_CHARACTER_BIBLE.jpg` and `ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg` are reference-sheet images, not animation atlases. The latter filename is retained for compatibility, but its concept is intended to represent Marie. The currently registered game sprites are vector animation strips at 2048×448 (eight 256×448 frames); they are the runtime assets. The reference JPEGs previously committed to the repo are small compressed copies and are **not** promoted as production-quality final art.

## Next art gate

Create authored, game-ready 8-frame vector/raster strips from the approved Dave and Marie designs, keeping consistent frame bounds, baseline, silhouette, outfit details, and transparent backgrounds. Add import/render snapshots for both characters and verify their actions on the target Android device before claiming final character-art completion.
