# Death Island — Manus Tribal Cast 2.5D Experiment

## Scope

This branch contains an experimental 2.5D illustrated concept/reference package only. It does not replace the existing illustrated 2.5D/SVG character pipeline and does not modify gameplay code, scenes, scripts, shaders, project settings, or existing character artwork.

The visual direction is a fixed-angle survival-RPG presentation with hand-painted anime-inspired illustration, readable silhouettes, saturated tropical material cues, and practical woven, barkcloth, hide, rope, shell, stone, and wood details. The reference game was used only at a high level for presentation quality; no proprietary character, clothing, texture, model, animation, or UI content was reproduced. Mature and sexual-content elements were excluded.

## Deliverables

Six adult/elder concept sheets were successfully generated. Each sheet includes a character turnaround, close-up/material details, and a gameplay-pose row intended to communicate idle, walk, run, gather, work, attack, hit reaction, and rest readability.

The three youth entries are documented as blocked generation attempts. They are intentionally not represented by substitute images or repeated safety-filter retries. No 3D models, GLB/FBX exports, texture maps, rigs, animation clips, polygon counts, or Godot import tests were created in this restart.

## Export and organization

- Output root: `experiments/manus_tribal_cast/`
- Character sheets: `characters/<character_id>/concept_sheet.png`
- Manifest: `ASSET_MANIFEST.json`
- Cast preview: `previews/cast_contact_sheet.png`
- Source images are PNG, 2304 × 1536 pixels for the six completed sheets.
- Image generation model: GPT Image 2.5, medium quality.

## Visual review

The six delivered boards were inspected for complete sheet composition, readable adult/elder silhouettes, consistent turnaround structure, clothing coverage, age cues, and distinct identities. The adult female slim and fuller designs are separate characters with different faces, hair, outfits, palettes, and silhouettes.

## Known limitations

The generated boards are concept/reference art, not production-ready sprites. They contain no deterministic text labels, no final sprite slicing, no animation files, and no validated Godot import assets. Generated costume motifs should be reviewed for cultural specificity before any production use. The youth portion of the requested cast remains incomplete because generation was blocked by the image safety system.

## Suggested future integration

If approved by the project owner, the next step should be a human-reviewed sprite extraction pass from the selected boards, followed by SVG or raster sprite production that matches the existing pipeline. Any future gameplay integration should remain separate from this experiment until silhouettes, frame counts, scale, and licensing are approved.
