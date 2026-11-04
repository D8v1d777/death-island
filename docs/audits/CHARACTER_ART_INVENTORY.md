# Death Island — Character Art Inventory

**Repository:** D8v1d777/death-island
**Branch:** feature/mad-island-art-overhaul
**Engine:** Godot 4.3
**Date:** 2026-11-04

---

## Summary

This inventory catalogs all character-related image assets in the repository, reconciled with game entity definitions. Environment art, UI icons, resource items, and decorative objects are excluded.

**Character entities defined in game:**
- **Player (Survivor)** — main controllable character
- **Mara (Companion)** — female NPC companion, recruitable
- **Enemies:** Wild Boar, Ash Wolf, Cave Stalker (Spider), Ruins Guardian

**Reference artwork available:**
- 2 production character bibles (Annie, Ellie)
- 6 original procedural SVG illustrations
- Kenney Platformer Characters 1 (CC0) — 3 archetypes with cutout limbs and poses
- Processed sprite frames (5 colors × 10 animations for characters, 13 enemy types)
- Combined horizontal-strip spritesheets (12 frames each)

---

## Asset Inventory

### 1. Character Reference Bibles

| Asset | Type | Dimensions | Transparency | Character | Usability | Action |
|-------|------|------------|--------------|-----------|-----------|--------|
| `src/assets/illustrated/ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg` | Full-body reference illustration | 256×171 px | No (JPG, opaque) | Annie (referenced in docs) | Reference only — single static image, no animation frames | Use as visual reference for Annie's design if implemented |
| `src/assets/illustrated/ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg` | Full-body reference illustration | 320×213 px | No (JPG, opaque) | Ellie (referenced in docs) | Reference only — single static image, no animation frames | Use as visual reference for Ellie's design if implemented |

**Notes:** These are concept/reference images only. Not usable for animation. No alpha channel. Characters Annie and Ellie are referenced in documentation but not currently implemented as game entities.

---

### 2. Original Procedural SVG Illustrations (Project Internal)

| Asset | Type | Dimensions | Transparency | Character | Usability | Action |
|-------|------|------------|--------------|-----------|-----------|--------|
| `src/assets/illustrated/Survivor.svg` | Procedural full-body character | Vector (scalable) | Yes (SVG) | Player (Survivor) | Reference only — procedural geometry, not frame-based | Preserve as design reference; replace with frame-based Sprite3D |
| `src/assets/illustrated/Mara.svg` | Procedural full-body character | Vector (scalable) | Yes (SVG) | Mara (Companion) | Reference only — procedural geometry, not frame-based | Preserve as design reference; replace with frame-based Sprite3D |
| `src/assets/illustrated/Boar.svg` | Procedural enemy | Vector (scalable) | Yes (SVG) | Wild Boar | Reference only — procedural geometry, not frame-based | Preserve as design reference; replace with frame-based Sprite3D |
| `src/assets/illustrated/Wolf.svg` | Procedural enemy | Vector (scalable) | Yes (SVG) | Ash Wolf | Reference only — procedural geometry, not frame-based | Preserve as design reference; replace with frame-based Sprite3D |
| `src/assets/illustrated/Spider.svg` | Procedural enemy | Vector (scalable) | Yes (SVG) | Cave Stalker | Reference only — procedural geometry, not frame-based | Preserve as design reference; replace with frame-based Sprite3D |
| `src/assets/illustrated/Guardian.svg` | Procedural enemy | Vector (scalable) | Yes (SVG) | Ruins Guardian | Reference only — procedural geometry, not frame-based | Preserve as design reference; replace with frame-based Sprite3D |

**Notes:** These are the original procedural SVG artworks created for the project. They define the canonical character designs but are not frame-based animations. The game currently uses Kenney-derived raster sprites instead. Keep unmodified as design references.

---

### 3. Kenney Platformer Characters 1 (CC0 — Downloaded)

**Source:** `assets-download/kenney/kenney/2d/Platformer Characters 1/`
**License:** CC0 1.0 Universal (Public Domain)
**Archetypes:** Player (male), Female, Soldier — each with separate Limbs (for cutout) and Poses (individual frames)

| Asset Category | Count | Dimensions | Transparency | Character | Usability | Action |
|----------------|-------|------------|--------------|-----------|-----------|--------|
| **Player/Limbs/** (arm, body_back, body_front, hand, head, head_back, head_focus, head_hurt, leg) | 9 | ~80×110 px | Yes (palette) | Player (male) | Ready for cutout animation — separate body parts with pivots | Build Skeleton2D rig from limbs for procedural animation |
| **Player/Poses/** (idle, walk1, walk2, action1, action2, back, cheer1, cheer2, climb1, climb2, duck, fall, hang, hold1, hold2, hurt, jump, kick, skid, slide, stand, swim1, swim2, talk, swim) | 24 | 80×110 px | Yes (palette) | Player (male) | Ready for frame-by-frame — individual pose frames | Slice into SpriteFrames; map to game actions |
| **Female/Limbs/** (same structure as Player) | 9 | ~80×110 px | Yes (palette) | Female | Ready for cutout animation | Build Skeleton2D rig for female variant |
| **Female/Poses/** (idle, walk1, walk2, action1, action2, back, cheer1, cheer2, climb1, climb2, duck, fall, hang, hold1, hold2, hurt, jump, kick, skid, slide, stand, swim1, swim2, talk) | 23 | 80×110 px | Yes (palette) | Female | Ready for frame-by-frame | Slice into SpriteFrames; map to Mara/companion |
| **Soldier/Limbs/** (same structure) | 9 | ~80×110 px | Yes (palette) | Soldier | Ready for cutout animation | Build Skeleton2D rig for enemy/NPC variant |
| **Soldier/Poses/** (idle, walk1, walk2, action1, action2, back, cheer1, cheer2, climb1, climb2, duck, fall, hang, hold1, hold2, hurt, jump, kick, skid, slide, stand, swim1, swim2, talk) | 23 | 80×110 px | Yes (palette) | Soldier | Ready for frame-by-frame | Slice into SpriteFrames; map to hostile NPCs |

**Total Kenney character assets: ~97 images**

**Notes:** These are the highest-quality source assets available. CC0 license permits commercial use. The Limbs folders enable cutout (Skeleton2D) animation; the Poses folders provide hand-drawn frame-by-frame alternatives. Each archetype has distinct proportions and clothing.

---

### 4. Processed Character Sprite Frames (Rasterized from Kenney)

**Location:** `assets-processed/` (also mirrored at `src/assets/illustrated/`)
**Format:** PNG, RGBA, transparent background

#### Player/Companion Characters (5 color variants × 10 animations)

| Asset Pattern | Count | Dimensions | Character | Usability | Action |
|---------------|-------|------------|-----------|-----------|--------|
| `character_{beige,green,pink,purple,yellow}_idle.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_walk.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_run.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_attack.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_gather.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_drink.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_craft.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_dodge.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_hurt.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |
| `character_{beige,green,pink,purple,yellow}_death.png` | 5 | 128×128 | Survivor/Mara variants | Ready — single frame (should be multi-frame) | Combine into horizontal strip; register in AnimationSetResource |

**Total: 50 files (5 colors × 10 animations)**

**Critical Issue:** Each file appears to be a single frame (128×128), but animations require multiple frames. The combined spritesheets (below) suggest these were meant to be sliced from horizontal strips.

---

#### Enemy Characters (13 types × 4-5 animations)

| Enemy Type | Animations | Dimensions | Usability | Action |
|------------|------------|------------|-----------|--------|
| `enemy_barnacle_*` (idle, attack, hurt, death) | 4 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_bee_*` (idle, fly, hurt, death) | 4 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_fish_blue_*` (idle, swim, hurt, death) | 4 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_fly_*` (idle, fly, hurt, death) | 4 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_frog_*` (idle, jump, hurt, death) | 4 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_ladybug_*` (idle, walk, fly, hurt, death) | 5 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_mouse_*` (idle, walk, hurt, death) | 4 | ~64×64 | Ready — single frames | Combine into strips |
| `enemy_slime_normal_*` (idle, walk, hurt, death) | 4 | ~64×64 | **Used for Wild Boar** | Combine into strips |
| `enemy_slime_fire_*` (idle, walk, hurt, death) | 4 | ~64×64 | **Used for Guardian** | Combine into strips |
| `enemy_slime_spike_*` (idle, walk, hurt, death) | 4 | ~64×64 | Available | Combine into strips |
| `enemy_snail_*` (idle, walk, hurt, death) | 4 | ~64×64 | Available | Combine into strips |
| `enemy_worm_normal_*` (idle, move, hurt, death) | 4 | ~64×64 | **Used for Wolf** | Combine into strips |

**Total: ~52 files**

**Mapping to Game Entities (from Art.tres):**
- Wild Boar → `enemy_slime_normal_combined.png`
- Wolf → `enemy_worm_normal_combined.png`
- Spider → `enemy_fish_blue_combined.png`
- Guardian → `enemy_slime_fire_combined.png`

---

### 5. Combined Horizontal-Strip Spritesheets

**Location:** `src/assets/illustrated/combined/`
**Format:** PNG, RGBA, transparent background
**Layout:** 12 frames horizontal (128px each = 1536×128 total)

| Asset | Frames | Dimensions | Character | Usability | Action |
|-------|--------|------------|-----------|-----------|--------|
| `character_beige_combined.png` | 12 | 1536×128 | Survivor (Player) | **Currently used** — mapped to "survivor" in Art.tres | Verify frame alignment; register AnimationSetResource |
| `character_green_combined.png` | 12 | 1536×128 | Alt color | Available | Register if needed for alt skins |
| `character_pink_combined.png` | 12 | 1536×128 | **Mara (Companion)** | **Currently used** — mapped to "mara" in Art.tres | Verify frame alignment; register AnimationSetResource |
| `character_purple_combined.png` | 12 | 1536×128 | Alt color | Available | Register if needed for alt skins |
| `character_yellow_combined.png` | 12 | 1536×128 | Alt color | Available | Register if needed for alt skins |
| `enemy_barnacle_combined.png` | ~6-8 | ~512×64 | Barnacle | Available | Register for enemy variety |
| `enemy_bee_combined.png` | ~6-8 | ~512×64 | Bee | Available | Register for enemy variety |
| `enemy_fish_blue_combined.png` | ~6-8 | ~512×64 | **Spider (Cave Stalker)** | **Currently used** | Verify frame alignment |
| `enemy_fly_combined.png` | ~6-8 | ~512×64 | Fly | Available | Register for enemy variety |
| `enemy_frog_combined.png` | ~6-8 | ~512×64 | Frog | Available | Register for enemy variety |
| `enemy_ladybug_combined.png` | ~6-8 | ~512×64 | Ladybug | Available | Register for enemy variety |
| `enemy_mouse_combined.png` | ~6-8 | ~512×64 | Mouse | Available | Register for enemy variety |
| `enemy_slime_normal_combined.png` | ~6-8 | ~512×64 | **Wild Boar** | **Currently used** | Verify frame alignment |
| `enemy_slime_fire_combined.png` | ~6-8 | ~512×64 | **Guardian** | **Currently used** | Verify frame alignment |
| `enemy_slime_spike_combined.png` | ~6-8 | ~512×64 | Spike Slime | Available | Register for enemy variety |
| `enemy_snail_combined.png` | ~6-8 | ~512×64 | Snail | Available | Register for enemy variety |
| `enemy_worm_normal_combined.png` | ~6-8 | ~512×64 | **Wolf (Ash Wolf)** | **Currently used** | Verify frame alignment |

**Total: 18 combined spritesheets**

**Note:** These are the actual textures loaded by the game. Each is a horizontal strip where frames are 128px wide (characters) or ~64px wide (enemies). The AnimationSetResource defines which frames belong to which animation.

---

### 6. Animation Definitions (Resources)

**Location:** `src/resources/definitions/animations/`

| Resource | Character | Animations Defined | Status |
|----------|-----------|-------------------|--------|
| `character_beige.tres` | Survivor (Player) | idle, walk, run, attack, gather, drink, craft, dodge, hurt, death | **Active** |
| `character_green.tres` | Alt skin | Same as beige | Available |
| `character_pink.tres` | Mara (Companion) | Same as beige | **Active** |
| `character_purple.tres` | Alt skin | Same as beige | Available |
| `character_yellow.tres` | Alt skin | Same as beige | Available |
| `enemy_boar.tres` | Wild Boar | idle, walk, run, windup, attack, recover, hurt, death | **Active** |
| `enemy_wolf.tres` | Ash Wolf | Same as boar | **Active** |
| `enemy_spider.tres` | Cave Stalker | idle, walk, windup, attack, recover, hurt, death | **Active** |
| `enemy_guardian.tres` | Ruins Guardian | idle, walk, windup, attack, recover, hurt, death | **Active** |
| `enemy_barnacle.tres` | Barnacle | idle, attack, hurt, death | Available |
| `enemy_bee.tres` | Bee | idle, fly, hurt, death | Available |
| `enemy_fish_blue.tres` | Spider | idle, swim, hurt, death | **Active** |
| `enemy_fly.tres` | Fly | idle, fly, hurt, death | Available |
| `enemy_frog.tres` | Frog | idle, jump, hurt, death | Available |
| `enemy_ladybug.tres` | Ladybug | idle, walk, fly, hurt, death | Available |
| `enemy_mouse.tres` | Mouse | idle, walk, hurt, death | Available |
| `enemy_slime_normal.tres` | Slime/Boar | idle, walk, hurt, death | **Active** |
| `enemy_slime_fire.tres` | Fire Slime/Guardian | idle, walk, hurt, death | **Active** |
| `enemy_slime_spike.tres` | Spike Slime | idle, walk, hurt, death | Available |
| `enemy_snail.tres` | Snail | idle, walk, hurt, death | Available |
| `enemy_worm_normal.tres` | Worm/Wolf | idle, move, hurt, death | **Active** |

**Total: 20 AnimationSetResource files**

---

## Reconciliation with Game Entities

| Game Entity | Art Key | Texture (Art.tres) | Animation Resource | Status |
|-------------|---------|---------------------|-------------------|--------|
| Player | `survivor` | `character_beige_combined.png` | `character_beige.tres` | ✅ Active |
| Mara (Companion) | `mara` | `character_pink_combined.png` | `character_pink.tres` | ✅ Active |
| Wild Boar | `wild_boar` | `enemy_slime_normal_combined.png` | `enemy_boar.tres` / `enemy_slime_normal.tres` | ✅ Active |
| Ash Wolf | `wolf` | `enemy_worm_normal_combined.png` | `enemy_wolf.tres` / `enemy_worm_normal.tres` | ✅ Active |
| Cave Stalker | `spider` | `enemy_fish_blue_combined.png` | `enemy_spider.tres` / `enemy_fish_blue.tres` | ✅ Active |
| Ruins Guardian | `guardian` | `enemy_slime_fire_combined.png` | `enemy_guardian.tres` / `enemy_slime_fire.tres` | ✅ Active |

**Missing/Unimplemented Characters (referenced in docs but not in game):**
- **Annie** — has reference bible (`ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg`), no game entity
- **Ellie** — has reference bible (`ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg`), no game entity
- **Dave** — referenced in mission brief, no art assets found, no game entity
- **Marie** — referenced in mission brief, no art assets found, no game entity

---

## Critical Issues Identified

### 1. Character Appears as Narrow Vertical Strip (Rendering Defect)
**Observed in:** Latest gameplay gallery screenshots
**Root Cause:** Sprite3D `rotation.x = CAMERA_PITCH (-PI/4)` combined with billboard mode renders the sprite edge-on when the camera looks down at 45°.
**Investigation Needed:**
- Sprite3D local axis orientation
- Billboard mode setting (`SPRITE_BASE_3D_BILLBOARD_*`)
- Parent/child rotation hierarchy
- `pixel_size` calculation vs texture dimensions
- `position.y` offset (`SCREEN_UP * height * 0.43`)

**Expected:** Character should face camera, show full upright silhouette.
**Actual:** Character renders as thin vertical line (edge-on).

### 2. Single-Frame Files Instead of Animation Strips
**Location:** `assets-processed/` and `src/assets/illustrated/`
**Issue:** Individual animation files (idle.png, walk.png, etc.) are 128×128 single frames, but combined spritesheets have 12 frames horizontal.
**Impact:** If game loads individual files instead of combined sheets, animations won't play.
**Resolution:** Game currently uses combined spritesheets (correct). Individual files are source artifacts.

### 3. Kenney Assets Not Fully Integrated
**Available:** 97 high-quality Kenney frames (Limbs + Poses for 3 archetypes)
**Used:** Only 5-color variants derived from Kenney (via processing pipeline)
**Gap:** Original Kenney cutout limbs and pose frames not directly used in game. The processed 5-color variants appear to be recolored/simplified versions.

### 4. Annie/Ellie/Dave/Marie Referenced But Not Implemented
- Reference bibles exist for Annie and Ellie
- Dave and Marie mentioned in mission brief
- No game entities, no art pipelines, no animation resources

---

## Recommended Actions by Priority

### P0 — Fix Rendering Defect (Character appears as vertical strip)
1. Inspect Sprite3D billboard mode — should be `BILLBOARD_ENABLED` with `BILLBOARD_FIXED_Y` or similar
2. Verify `rotation.x = -PI/4` on Sprite3D vs parent Node3D
3. Check `pixel_size` calculation: `height / texture.get_height()` — texture is 128px tall, height=3.4 → pixel_size ≈ 0.0266
4. Ensure Sprite3D local +Y is up, +Z is forward (Godot convention)
5. Test with `billboard = SpriteBase3D.BILLBOARD_PARTICLES` (always face camera)

### P1 — Validate Animation Frame Mapping
1. Confirm each combined spritesheet's 12 frames align with AnimationSetResource frame indices
2. Character frames (128px): idle(0-3), walk(4-9), run(10-15), attack_light(16-19), attack_heavy(20-25), gather(26-30), drink(31-34), craft(35-40), dodge(41-44), hurt(45-47), death(48-53)
3. Enemy frames (64px): verify similar alignment

### P2 — Integrate Kenney Cutout Limbs for Procedural Animation
1. Import Kenney Limbs as separate textures
2. Build Skeleton2D rigs for Player, Female, Soldier archetypes
3. Use for smooth interpolation between key poses
4. Fall back to frame-by-frame (Poses) for complex actions

### P3 — Implement Missing Characters
1. **Annie** — use `ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg` as reference; create from Kenney Female archetype
2. **Ellie** — use `ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg` as reference; create from Kenney Female archetype
3. **Dave** — create from Kenney Soldier archetype
4. **Marie** — create from Kenney Female archetype

---

## Documentation References

- **Godot 4.3 Sprite3D:** https://docs.godotengine.org/en/4.3/classes/class_sprite3d.html
- **Godot 4.3 AnimatedSprite3D:** https://docs.godotengine.org/en/4.3/classes/class_animatedsprite3d.html
- **Godot 4.3 SpriteBase3D Billboard:** https://docs.godotengine.org/en/4.3/classes/class_spritebase3d.html
- **Godot 4.3 2D Sprite Animation:** https://docs.godotengine.org/en/4.3/tutorials/2d/2d_sprite_animation.html
- **Godot 4.3 Cutout Animation:** https://docs.godotengine.org/en/4.3/tutorials/animation/cutout_animation.html
- **Godot 4.3 2D Skeletons:** https://docs.godotengine.org/en/4.3/tutorials/animation/2d_skeletons.html
- **Kenney Platformer Characters 1:** https://kenney.nl/assets/platformer-characters

---

*Generated as part of Death Island Phase 2 Art Overhaul. Inventory complete as of 2026-11-04.*