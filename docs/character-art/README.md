# Character concept art — Annie, Ellie and Marie

Status: **concept references only; not runtime character assets**

This folder is the hand-off point for the first female-character art pass. The generated composite concept boards are visual direction references, not sprite atlases. They contain presentation labels and multi-view artwork in a single flattened image; the apparent animation rows are not guaranteed to be frame-accurate, consistently sized, transparent, or separable.

## Character identity rules

- **Annie:** use `src/assets/illustrated/ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg` as the canonical identity reference. Preserve her established face, blonde hairstyle, clothing silhouette and palette. The generated concept board is subordinate to the production bible.
- **Ellie:** use `src/assets/illustrated/ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg` as the canonical identity reference. Preserve her established face, dark hairstyle, outfit silhouette and palette. The generated concept board is subordinate to the production bible.
- **Marie:** this is the working name for the previously unnamed female NPC reference supplied by the project owner. Treat that supplied reference as canonical. Do not silently replace her with a different generated design or infer unconfirmed biography, age, or gameplay role.

## Generated concept boards

The three generated boards supplied for this pass are design explorations. Before they are imported into the game, they must be compared side-by-side with the canonical references and approved by the project owner. If a board conflicts with a character bible or the supplied Marie reference, the canonical reference wins.

## Required production workflow

1. Keep the original concept boards in a documentation/reference location, separate from runtime textures.
2. Extract or regenerate each character as an individual, full-body image on a clean/transparent background. Do not crop a character out of a flattened composite unless the crop is manually checked for panel borders, labels, shadows, and clipping.
3. Obtain approval for each static design before generating animation frames.
4. Generate animation frames from the approved character reference, not from the composite board's tiny animation thumbnails.
5. Validate frame consistency: identity, outfit, anatomy, scale, lighting, foot baseline, silhouette, alpha channel, and frame bounds.
6. Build separate atlases and metadata per character. Do not assume the displayed “12 frames” in a concept sheet correspond to twelve valid frames.
7. Integrate each character through the existing Godot actor/art resource architecture. Do not overwrite Survivor/Mara mappings or mark Annie, Ellie, or Marie as integrated until each is instantiated in gameplay and visually verified.

## Acceptance gates

- [ ] Annie design matches Annie's production bible.
- [ ] Ellie design matches Ellie's production bible.
- [ ] Marie design matches the supplied unnamed-NPC reference.
- [ ] Each approved character has individually extracted, clean source artwork.
- [ ] Each animation atlas has verified dimensions, alpha, frame order, and metadata.
- [ ] Each character is registered in the appropriate character/NPC definitions.
- [ ] Each character appears correctly in a real gameplay capture.
- [ ] Automated tests and visual checks pass.

**Important:** a concept sheet is not a game-ready sprite sheet. No runtime integration is claimed by this document.
