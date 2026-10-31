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
