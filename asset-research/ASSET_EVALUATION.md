# Death Island — Asset Evaluation Table

**Date:** 2026-11-04
**Phase:** 2 - Professional Asset Acquisition and Visual Transformation
**Goal:** Visual presentation comparable to Mad Island using professionally authored, independently sourced artwork.

---

## Asset Evaluation Matrix

| Category | Asset Pack | Source | License | Resolution | Animation Coverage | Decision |
|----------|-----------|--------|---------|------------|-------------------|----------|
| **Environment - Beach/Tropical** | Wildshore Island Survival Tileset | Layau_13 (itch.io) | Free* | 16x16 / 32x32 | Tiles only | **PRIMARY CANDIDATE** |
| **Environment - Beach/Tropical** | Tropical Beach Pixel Art Asset Pack | frodigefrodo (itch.io) | Free* | 16x16 | Props + animations | **SECONDARY** |
| **Environment - Jungle/Forest** | Kenney Modular Dungeon Kit | Kenney (CC0) | CC0 | 16x16 / 32x32 | Modular tiles | **PRIMARY CANDIDATE** |
| **Environment - Jungle/Forest** | Kenney Tiny Dungeon | Kenney (CC0) | CC0 | 16x16 | Modular tiles | **SECONDARY** |
| **Environment - Cave/Dungeon** | Roguelike Caves & Dungeons | OpenGameArt (CC0) | CC0 | 16x16 / 32x32 | Modular tiles | **PRIMARY CANDIDATE** |
| **Environment - General** | Kenney Survival Kit | Kenney (CC0) | CC0 | 16x16 / 32x32 | Tiles + props + chars | **PRIMARY CANDIDATE** |
| **Environment - Buildings** | Kenney Building Kit | Kenney (CC0) | CC0 | 16x16 / 32x32 | Modular buildings | **PRIMARY CANDIDATE** |
| **Environment - Furniture** | Kenney Furniture Kit | Kenney (CC0) | CC0 | 16x16 / 32x32 | Interior props | **PRIMARY CANDIDATE** |
| **Character - Protagonist (Male)** | Kenney Platformer Characters | Kenney (CC0) | CC0 | Multiple sizes | Idle, walk, run, jump, attack | **PRIMARY CANDIDATE** |
| **Character - Female NPC** | Kenney Platformer Characters (Female) | Kenney (CC0) | CC0 | Multiple sizes | Idle, walk, run, jump, attack | **PRIMARY CANDIDATE** |
| **Character - Enemy Humanoid** | hsdsz Goblin Pack Vol.1 | hsdsz (itch.io) | Free* | 32x32 / 64x64 | Idle, walk, attack, hurt, death | **PRIMARY CANDIDATE** |
| **Character - Enemy Beast** | hsdsz Wild Boar Pack | hsdsz (itch.io) | Free* | 32x32 / 64x64 | Idle, walk, attack, hurt, death | **PRIMARY CANDIDATE** |
| **Character - Enemy Spider** | Engvee Free Animated Isometric Spider | Engvee (itch.io) | Free* | 64x64 | Idle, walk, attack, death | **PRIMARY CANDIDATE** |
| **Character - Monster Variety** | Admurin Monster Pack | Admurin (itch.io) | Free* | Multiple | Various animations | **SECONDARY** |
| **Character - Medieval Fantasy** | OcO Medieval Fantasy Character Pack | OcO (itch.io) | Free* | 32x32 / 64x64 | Idle, walk, attack, etc. | **SECONDARY** |
| **UI - Icons & Panels** | Kenney UI Pack | Kenney (CC0) | CC0 | Various | N/A (static) | **PRIMARY CANDIDATE** |
| **UI - Adventure Theme** | UI Pack - Adventure (OpenGameArt) | OpenGameArt (CC0) | CC0 | Various | N/A (static) | **SECONDARY** |
| **Items - Weapons/Equipment** | Kenney Blaster Kit (adaptable) | Kenney (CC0) | CC0 | 16x16 / 32x32 | Static sprites | **PRIMARY CANDIDATE** |
| **Items - Generic** | Generic Items (OpenGameArt) | OpenGameArt (CC0) | CC0 | 16x16 / 32x32 | Static sprites | **SECONDARY** |

---

## License Verification Notes

* **Kenney Assets**: All CC0 (Public Domain) - **Confirmed commercial use allowed, no attribution required but appreciated**
* **OpenGameArt CC0 assets**: **Confirmed commercial use allowed**
* **itch.io "Free" assets**: Need individual license verification on each page
  - Layau_13 Wildshore: Need to check license on page
  - Engvee Spider: Need to check license on page
  - hsdsz Goblin/Boar: Need to check license on page
  - Admurin: Need to check license on page
  - OcO: Need to check license on page
  - frodigefrodo: Need to check license on page

---

## Recommended Core Pack Selection (Coherent Visual Style)

### Tier 1: Kenney Ecosystem (CC0 - Guaranteed Commercial Use)
These work together cohesively because they share the same art style, resolution standards, and palette:

1. **Kenney Survival Kit** - Base tileset, props, characters, UI elements
2. **Kenney Platformer Characters** - Male + Female protagonist sprites with full animation sets
3. **Kenney Building Kit** - Modular structures for shelters, crafting stations
4. **Kenney Furniture Kit** - Interior props for campfires, workbenches, etc.
5. **Kenney Modular Dungeon Kit / Tiny Dungeon** - Cave/dungeon environments
6. **Kenney UI Pack** - Complete UI icon set
7. **Kenney Blaster Kit** - Weapon/item sprites (adaptable for melee/tools)

### Tier 2: Specialized Enemy Packs (Need License Verification)
For unique enemy variety beyond Kenney's limited enemy selection:

1. **hsdsz Goblin Pack Vol.1** - Humanoid enemies with full animation sets
2. **hsdsz Wild Boar Pack** - Beast enemy with full animation sets
3. **Engvee Animated Isometric Spider** - Arachnid enemy with animations

### Tier 3: Environment Specific (Need License Verification)
For distinctive beach/island look:

1. **Layau_13 Wildshore Island Survival Tileset** - Tropical beach theme
2. **frodigefrodo Tropical Beach Pixel Art** - Animated beach props

---

## Integration Strategy

### AnimationSetResource Mapping
Each asset pack will need AnimationSetResource configurations matching their frame layouts:

| Entity Type | Source Pack | Sprite Sheet Layout | Required Animations |
|-------------|-------------|---------------------|---------------------|
| Dave (Protagonist) | Kenney Platformer Characters (Male) | Horizontal strips | idle, walk, run, attack_light, attack_heavy, gather, drink, craft, dodge, hurt, death |
| Mara (Companion) | Kenney Platformer Characters (Female) | Horizontal strips | Same as Dave |
| Wild Boar | hsdsz Wild Boar Pack | Horizontal strips | idle, walk, run, windup, attack, recover, hurt, death |
| Goblin | hsdsz Goblin Pack | Horizontal strips | idle, walk, windup, attack, recover, hurt, death |
| Spider | Engvee Spider | Horizontal strips | idle, walk, windup, attack, recover, hurt, death |
| Guardian | Admurin/OcO or Kenney large enemy | Horizontal strips | idle, walk, windup, attack, recover, hurt, death |

### Texture Import Settings (Godot 4.3 Compatibility Renderer)
- **Format**: PNG (lossless) or WebP (lossy, smaller)
- **Compression**: ETC2 for mobile (VRAM efficient)
- **Mipmaps**: Enabled (for orthographic camera zoom)
- **Filter**: Linear with mipmaps
- **Fix Alpha Border**: Enabled (prevents edge artifacts)
- **Max Size**: 2048px (mobile VRAM budget)

---

## Next Steps

1. **Verify licenses** for all Tier 2 and Tier 3 "Free*" assets
2. **Download** Tier 1 Kenney packs (CC0, guaranteed safe)
3. **Create test project** to verify sprite sheet layouts and frame counts
4. **Generate AnimationSetResource .tres files** for each entity type
5. **Replace placeholder art** in Art.tres with actual asset references
6. **Configure texture imports** for mobile budgets
7. **Test in-game** with AnimatedSpriteController
8. **Capture gameplay screenshots** for gallery
9. **Create THIRD_PARTY_LICENSES.md** with full attribution

---

## Vertical Slice Priority

1. **Dave on beach** - Kenney Survival Kit beach tiles + Kenney male character
2. **Dave in jungle** - Kenney Survival Kit jungle tiles + Kenney male character
3. **Gathering** - Kenney character gather animation + resource nodes
4. **Combat** - Kenney character attack + hsdsz boar/goblin enemy
5. **Campfire & crafting** - Kenney Building Kit + Furniture Kit + UI Pack
6. **Cave exploration** - Kenney Modular Dungeon/Tiny Dungeon
7. **Shelter & settlement** - Kenney Building Kit
8. **Companion interaction** - Kenney female character + dialogue UI
9. **NPC/Environment composition** - All above combined

---

## Sources Referenced

- [Wildshore Island Survival Tileset by Layau_13](https://layau.itch.io/free-wildshore-island-survival-tileset)
- [Engvee Free Animated Isometric Spider](https://engvee.itch.io/free-animated-isometric-spider)
- [hsdsz Goblin Pack Vol.1](https://hsdsz.itch.io/goblin-enemy-pack-vol-1)
- [hsdsz Wild Boar Pack](https://hsdsz.itch.io/)
- [Admurin Asset Packs](https://admurin.itch.io/)
- [OcO Asset Packs](https://oco.itch.io/)
- [Kenney Survival Kit](https://kenney.nl/assets/survival-kit)
- [Kenney Platformer Characters](https://kenney.nl/assets/platformer-characters)
- [Kenney Building Kit](https://kenney-assets.itch.io/building-kit)
- [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit)
- [Kenney Modular Dungeon Kit](https://kenney.nl/assets/modular-dungeon-kit)
- [Kenney Tiny Dungeon](https://kenney-assets.itch.io/tiny-dungeon)
- [Kenney UI Pack](https://kenney.nl/assets/ui-pack)
- [Kenney Blaster Kit](https://kenney.nl/assets/blaster-kit)
- [Roguelike Caves & Dungeons (OpenGameArt)](https://opengameart.org/content/roguelike-caves-dungeons-pack)
- [Generic Items (OpenGameArt)](https://opengameart.org/content/generic-items)
- [Tropical Beach by frodigefrodo](https://frodigefrodo.itch.io/tropical-beach-pixel-art-asset-pack-with-animations)
- [UI Pack - Adventure (OpenGameArt)](https://opengameart.org/content/ui-pack-adventure)

---

*License status "Free*" = listed as free download on itch.io but requires individual license verification for commercial use rights.