# Asset provenance

* `src/assets/Icon.svg`: original vector icon created for Death Island.
* `src/assets/illustrated/*.svg`: original vector illustrations, authored through
  `tools/illustrate.py`. Includes Ayla and Mara's action atlases, animals, foliage,
  stations, shelter and terrain textures. No extracted/copied Mad Island assets.
  Exception to the generator path: `Dave.svg` and `Marie.svg` are dedicated interim
  palette derivatives of the original Survivor/Mara geometry, introduced in
  `6f8a705`, under the repository MIT license. They are not conversions verified
  against the unavailable approved references; see `docs/audits/CHARACTER_PIPELINE.md`.
* Reference-board JPEGs are not runtime art. Their individual provenance is not
  established; surviving boards are excluded by `src/export_presets.cfg` and the
  APK verifier. Removed malformed Dave/Marie copies remain in Git history.
* `Ground.gdshader` / `Water.gdshader`: original compact terrain/water shaders.
* `Art.tres` and the island resource: authored environment placement.
* `docs/images/*.webp`: actual running-game screenshots from GameplayGallery.
  Fixture setup/action evidence is in `docs/images/gallery.json`.
* `AudioPalette.tres` and AudioManager: original synthesized PCM sound cues.
* `IslandTheme.tres` and UI copy: original project UI.
* Ayla, Mara, quests, region names and endings: original fictional characters/narrative.
* Font: Godot's bundled default font, distributed by the engine under its bundled
  third-party notices. No additional font download.

Development-only skill: `wshobson/agents`, `godot-gdscript-patterns`, installed via
Skills CLI 1.7.4. See `skills-lock.json` for the content hash. It is outside `src/`
and not part of the APK. Godot Engine and its runtime dependencies retain their
upstream licenses; see https://godotengine.org/license/ and the engine's
`COPYRIGHT.txt` before producing a distributable release.
