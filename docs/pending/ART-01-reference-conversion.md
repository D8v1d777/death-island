# ART-01 — Character reference conversion

**Status:** BLOCKED on the previously supplied source image  
**Scope:** Convert the intended character concept into a production-ready 2.5D game asset without weakening the game's visual direction.

## What happened

The image-processing route rejected the supplied character image multiple times. This ledger records the tool outcome only. It does **not** conclude that the source image is NSFW or describe its contents; the rejected image is not embedded in this task record.

Do not keep submitting the same image, crop it to evade a classifier, disguise its content, or route it through another processor for the purpose of bypassing a safety decision. That does not help the production pipeline and risks losing time without producing a usable asset.

## Replacement route

1. **Preserve design intent in text.** Write down only the intended fictional character's non-explicit design cues: adult age, silhouette, face shape, hairstyle, palette, costume, accessories, personality, and role in the story. Do not infer or fabricate features that are not in the approved concept.
2. **Create a fresh, original, non-explicit reference.** Use an adult fictional character, fully clothed in practical island-survival attire, neutral studio lighting, neutral standing pose, and a front/side/back turnaround. Keep the design attractive and high quality without nudity, sexualized framing, or explicit detail. This is a new image, not an edit or disguised re-submission of the blocked source.
3. **If a new image is still unavailable, use an asset pipeline rather than a weaker placeholder.** Select a suitable CC0 or CC-BY asset with a compatible style and license, or produce a neutral 3D blockout from the written brief. Record author, source URL, license, attribution, modifications, and date in `docs/research/asset-provenance.md` before integration.
4. **Prepare runtime output.** Separate body, hair, clothing, accessories, and equipment where useful. Produce consistent proportions and pivots; generate a sprite atlas or a rigged model; validate transparent edges and frame alignment.
5. **Animate deliberately.** At minimum provide idle, walk/run, gather, light attack, heavy attack, hit reaction, and down/death states. Animation frames must be visibly distinct and must trigger from actual gameplay states—not a static image with a cosmetic wobble.
6. **Integrate behind the existing art abstraction.** Keep gameplay physics and hitboxes independent from illustration geometry. Preserve the game's fixed-angle 2.5D presentation, mobile texture budget, and Android Compatibility renderer.

## Acceptance criteria

- The new design is original and non-explicit, and the character is clearly represented as an adult.
- The production sheet has consistent face, costume, proportions, palette, and accessories across views.
- Runtime output is an actual sprite atlas or rigged model, not a reference-board JPEG.
- All required animation states are mapped and driven by game actions.
- Asset provenance and license obligations are recorded.
- Godot import, headless tests, Android export, and a rendered gameplay capture succeed.
- No source image is altered or re-routed for the purpose of bypassing a content restriction.

## Existing reference files

The repository's Ellie and Annie production character-bible images are retained under `src/assets/illustrated/`. They are references only; do not assume they are runtime-ready atlases.
