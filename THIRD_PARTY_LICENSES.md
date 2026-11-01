# Credits and attribution inventory

- **Death Island contributors:** original project code, SVG art, shaders, narrative,
  UI and synthesized sound cues; repository [MIT license](LICENSE).
- **Dave/Marie interim strips:** palette derivatives of the original Survivor/Mara
  geometry, introduced in `6f8a705`; same repository license. Not verified against
  original character references. See [asset provenance](docs/research/asset-provenance.md).
- **Godot Engine 4.3 and bundled default font/dependencies:** retain the engine's
  upstream copyright/license and all applicable third-party notices:
  https://godotengine.org/license/ and
  https://github.com/godotengine/godot/blob/4.3-stable/COPYRIGHT.txt.
- **Development tooling and project-local skills:** outside `src/` and not shipped
  in the APK; pinned Python versions are in `tools/requirements.txt` and skill
  provenance in `skills-lock.json`.

Reference-board JPEGs with unresolved individual provenance are excluded from
exports. No Mad Island assets were downloaded, extracted or integrated in this work.

This inventory is **not a complete distributable notice bundle**. Before release,
package the exact engine/template/Android dependency notices, check final-art source
rights and verify attribution against the final release APK/AAB. Current debug-build
CI does not certify those legal/distribution obligations.
