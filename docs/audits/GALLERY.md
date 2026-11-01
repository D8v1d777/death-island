# Current gameplay gallery

The six README images are actual 1280x720 Godot 4.3 Compatibility viewport captures.
The runner starts Dave through the production new-game API, arranges bounded
inventory/encounter fixtures, and calls real movement, interaction, combat,
crafting and building APIs. Scenario 05 navigates from inventory to crafting.
Images are never composited or presented as target-phone photographs.

## Regeneration

```bash
python3 tools/check.py
DEATH_ISLAND_GALLERY_DIR="$PWD/docs/images" python3 tools/check.py --gallery
python3 tools/validate_gallery.py docs/images --readme README.md
```

Without the environment override, `--gallery` writes to `build/gallery/`, suitable
for CI. It uses Xvfb/OpenGL, seed 20261030 and fixed simulation FPS 30. The fixed
simulation FPS is not a measured rendering-performance claim. GPU/driver/font
differences may change encoded bytes; state/scenario results must remain valid.

The wrapper rejects engine errors, requires six successful actions, checks WebP
containers, source/engine metadata and SHA-256 digests, and runs Godot's decoder
against all six files. Decoded images must be nonblank, distinct and 1280x720.
`gallery.json` records source revision (the source commit before capture/artifact
commit), character/texture, scenario, menu, frame, dimensions and actual state changes.

## Scenarios and visual review

| File under `docs/images/` | Expected evidence / visual subject |
|---|---|
| `01-wreckshore-walk.webp` | Movement >0.3m; Dave, wreck, beacon, shoreline and mobile HUD |
| `02-jungle-gather.webp` | Wood count increases; axe pose, jungle tree and reward feedback |
| `03-boar-combat.webp` | Enemy health decreases; attack pose, boar, damage number and HUD |
| `04-campfire-cooking.webp` | Cooked meat present after actual crafting; campfire, cooking pose, Mara and HUD |
| `05-inventory-crafting.webp` | Axe count increases by one; crafting menu with ingredient inventory and costs |
| `06-shelter-building.webp` | Four successful placed parts; completed shelter, builder and camp environment |

All six replacement scenarios were inspected at full size during this execution;
the final committed capture files are reviewed again after generation. The obsolete
`05-cave-mining.webp` remains unlinked historical evidence, not a seventh gallery entry.
Both dedicated character screenshots are also produced and inspected under
`build/screenshots/character-dave.png` and `character-marie.png` by `--render-only`.

Final regeneration used source revision `2e30b53`; all six image hashes remained
identical to the replacements already visually reviewed at full size. The manifest
was refreshed to identify that final runtime source. No unreviewed image replaced
an accepted capture during this final regeneration.

Visual acceptance here covers readable gameplay captures and correct current
interim texture use. It does not approve reference fidelity, full animation sets,
phone performance or production art. No original-reference processing was retried.
