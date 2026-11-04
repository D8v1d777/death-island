# Female Character Art Pipeline Audit

**Date**: 2026-11-04  
**Branch**: `feature/female-character-integration`  
**Commit**: e48a0a9 (NPC infrastructure complete)  
**Status**: AUDIT - No paid generation performed

---

## 1. Script Verification

| Item | Value |
|------|-------|
| **Script Path** | `/root/death-island-art-overhaul/generate_character_art.py` |
| **Git Status** | `??` (untracked) |
| **git status --short** | `?? generate_character_art.py` |
| **Lines of Code** | 328 |
| **Dependencies** | requests, pillow (system), argparse |

**Note**: Script is NOT committed. Per instructions, it should be committed to a tracked tools directory (e.g., `tools/`) but WITHOUT credentials, `.env`, or tokens.

---

## 2. Current Atlas-Assembly Logic Analysis

### The Bug: `create_spritesheet_from_views()` (lines 203-243)

```python
# Current (WRONG) logic:
views_order = ["front", "three_quarter", "side", "rear"]
# 4 views × 3 duplicates each = 12 frames
for i in range(12):
    view_idx = i // 3  # 3 frames per view
    combined.paste(images[view_idx], (i * frame_size, 0))
```

**Resulting Frame Layout (WRONG):**
| Frame | Source View | Problem |
|-------|-------------|---------|
| 0-2 | Front | 3 copies of same static front view |
| 3-5 | Three-quarter | 3 copies of same static 3/4 view |
| 6-8 | Side | 3 copies of same static side view |
| 9-11 | Rear | 3 copies of same static rear view |

**Why This Breaks Animation**: The animation system expects **3 distinct animation rows** (idle, walk, run), each with 4 unique frames. The current script produces **4 camera angles** duplicated, not animation frames.

---

## 3. Explicit 12-Frame Mapping Table

### Required Frame Layout (per `AnimationSetResource.create_survivor_set()` and `IllustratedArt.get_animation_set()`)

| Frame | Animation | Frame-in-Anim | Used By | Description |
|-------|-----------|---------------|---------|-------------|
| **0** | idle | 1/4 | idle, drink | Standing still, breathing |
| **1** | idle | 2/4 | idle, drink | Standing still, breathing |
| **2** | idle | 3/4 | idle, drink | Standing still, breathing |
| **3** | idle | 4/4 | idle, drink | Standing still, breathing |
| **4** | walk | 1/4 | walk, dodge | Left foot forward |
| **5** | walk | 2/4 | walk, dodge | Right foot forward |
| **6** | walk | 3/4 | walk, dodge | Left foot forward |
| **7** | walk | 4/4 | walk, dodge | Right foot forward |
| **8** | run | 1/4 | run, attack_light, attack_heavy, gather, craft, hurt, death | Full stride start |
| **9** | run | 2/4 | run, attack_light, attack_heavy, gather, craft, hurt, death | Full stride mid |
| **10** | run | 3/4 | run, attack_light, attack_heavy, gather, craft, hurt, death | Full stride late |
| **11** | run | 4/4 | run, attack_light, attack_heavy, gather, craft, hurt, death | Full stride end |

### Frame Sharing Summary

| Animation | Frames Used | Shares With |
|-----------|-------------|-------------|
| **idle** | 0-3 | drink |
| **walk** | 4-7 | dodge |
| **run** | 8-11 | attack_light, attack_heavy, gather, craft, hurt, death |
| **drink** | 0-3 | idle |
| **dodge** | 4-7 | walk |
| **attack_light** | 8-11 | run, attack_heavy, gather, craft, hurt, death |
| **attack_heavy** | 8-11 | run, attack_light, gather, craft, hurt, death |
| **gather** | 8-11 | run, attack_light, attack_heavy, craft, hurt, death |
| **craft** | 8-11 | run, attack_light, attack_heavy, gather, hurt, death |
| **hurt** | 8-11 | run, attack_light, attack_heavy, gather, craft, death |
| **death** | 8-11 | run, attack_light, attack_heavy, gather, craft, hurt |

---

## 4. Genuine Animation Artwork Required

### Static Character Artwork (Phase 1 - Current Mission)
For **visual verification only** (single static pose per character):
- 4 directional views: Front, Three-quarter, Side, Rear
- Transparent background
- 2.5D isometric perspective (orthographic, -45° camera pitch)
- 128×128 per frame
- **Purpose**: Verify camera-facing, scale, foot anchoring, visibility in beach/jungle

### Genuine Animation Frames (Phase 2 - Future)
**Each character needs 12 unique frames minimum** (1536×128 combined):

| Animation | Unique Frames Needed | Notes |
|-----------|---------------------|-------|
| Idle | 4 | Breathing, subtle weight shift |
| Walk | 4 | 4-frame walk cycle |
| Run | 4 | 4-frame run cycle |
| Attack Light | 4* | Can share run frames (current design) |
| Attack Heavy | 4* | Can share run frames (current design) |
| Gather | 4* | Can share run frames (current design) |
| Hurt | 4* | Can share run frames (current design) |
| Death | 4* | Can share run frames (current design) |
| Drink | 4* | Shares idle frames |
| Dodge | 4* | Shares walk frames |
| Craft | 4* | Shares run frames |

**Total unique frames per character: 12** (idle 4 + walk 4 + run 4)  
*All other actions currently reuse run/walk/idle frames per animation set design*

**If genuine unique animations are desired for attack/gather/hurt/death**: +28 frames/character (4 each × 7 actions)

---

## 5. Asset Isolation Verification

| Asset | Path | Status |
|-------|------|--------|
| Annie reference | `src/assets/illustrated/ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg` | ✅ Exists (7KB) |
| Ellie reference | `src/assets/illustrated/ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg` | ✅ Exists (12KB) |
| Marie reference | **Not in repository** | ❌ **BLOCKER** |
| Survivor art | `src/assets/illustrated/Survivor.svg` + `character_beige_combined.png` | ✅ Protected |
| Mara art | `src/assets/illustrated/Mara.svg` + `character_pink_combined.png` | ✅ Protected |
| Annie combined | `src/assets/illustrated/combined/character_annie_combined.png` | ⚠️ Placeholder (copy of Survivor) |
| Ellie combined | `src/assets/illustrated/combined/character_ellie_combined.png` | ⚠️ Placeholder (copy of Mara) |
| Marie combined | `src/assets/illustrated/combined/character_marie_combined.png` | ⚠️ Placeholder (copy of purple variant) |

**Verification**: Original Survivor and Mara assets are **untouched**. New female characters use separate `art_key` values ("annie", "ellie", "marie") in Art.tres and NPC scripts.

---

## 6. Annie-First Workflow Compliance

| Step | Requirement | Status |
|------|-------------|--------|
| 1 | Generate Annie static artwork only | ⏳ Pending (script fix + token) |
| 2 | Verify in Godot gameplay | ⏳ Pending |
| 3 | Camera-facing (rotation.x = -PI/4) | ⏳ Verify after import |
| 4 | Scale/foot anchoring (pixel_size = height/texture_height) | ⏳ Verify after import |
| 5 | Beach/jungle visibility | ⏳ Verify after import |
| 6 | Only then proceed to Ellie | ✅ Enforced by workflow |
| 7 | Only then proceed to Marie (with reference) | ✅ Enforced by workflow |
| 8 | Genuine animations after static approval | ✅ Enforced by workflow |

---

## 7. Marie Blocker

**Exact Blocker**: "Original user-supplied unnamed female NPC reference (Marie)" — **no such file exists in the repository**.

**Searches performed**:
- `find /root/death-island-art-overhaul -iname "*marie*"` → Only returns placeholder assets created during NPC integration
- `find /root/death-island-art-overhaul -iname "*Marie*"` → Same
- `grep -r "Marie" --include="*.jpg" --include="*.png" --include="*.svg"` → No original reference

**Action Required**: User must provide the original Marie reference image. Do not invent/replace.

---

## 8. Remaining Blockers (No API Token Required Validation)

| Blocker | Type | Resolution |
|---------|------|------------|
| **generate_character_art.py not committed** | Process | Commit to `tools/` directory |
| **Script atlas-assembly logic is wrong** | Code | Fix `create_spritesheet_from_views()` to produce 12 animation frames, not 4 views × 3 |
| **No Replicate API token** | External | User must provide `REPLICATE_API_TOKEN` |
| **Marie reference missing** | Asset | User must provide original reference |
| **Annie/Ellie static verification not done** | Validation | Requires fixed script + token + Godot import |
| **Godot import pipeline untested for new assets** | Integration | Test after first generation |

---

## 9. Required Script Fix

### `create_spritesheet_from_views()` must be rewritten to:

1. **Accept 12 genuine animation frames** (not 4 views)
2. **Or**: Generate animation frames via img2img with specific prompts per frame
3. **Or**: For static verification only — create a "verification spritesheet" with 4 views in frames 0-3 and duplicate to fill 12 frames **with clear labeling**

### Minimal Fix for Static Verification Phase:

```python
def create_verification_spritesheet(view_paths, character_name, output_dir, frame_size=128):
    """Create spritesheet for STATIC VERIFICATION ONLY.
    Places 4 views in frames 0-3, marks remaining frames as 'TODO: animation'.
    """
    views_order = ["front", "three_quarter", "side", "rear"]
    images = []
    for view in views_order:
        if view in view_paths:
            img = Image.open(view_paths[view]).convert("RGBA")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
        else:
            img = Image.new("RGBA", (frame_size, frame_size), (255, 0, 255, 128))  # Magenta = missing
        images.append(img)
    
    combined = Image.new("RGBA", (frame_size * 12, frame_size), (0, 0, 0, 0))
    for i in range(12):
        if i < 4:
            combined.paste(images[i], (i * frame_size, 0))
        else:
            # Frames 4-11: placeholder for animation frames
            ph = Image.new("RGBA", (frame_size, frame_size), (255, 165, 0, 128))  # Orange = animation TODO
            # Add frame number text if PIL supports it
            combined.paste(ph, (i * frame_size, 0))
    
    output_path = os.path.join(output_dir, f"character_{character_name.lower()}_combined_VERIFICATION.png")
    combined.save(output_path)
    return output_path
```

---

## 10. Next Steps (No Paid Requests)

1. **Commit** `generate_character_art.py` to `tools/generate_character_art.py`
2. **Fix** `create_spritesheet_from_views()` per §9 above
3. **Wait** for user to provide `REPLICATE_API_TOKEN`
4. **Wait** for user to provide Marie's original reference
5. **Generate** Annie static artwork only (4 views)
6. **Import** to Godot, verify in-game (screenshots)
7. **Only after Annie approval**: proceed to Ellie, then Marie, then genuine animations

---

**Audit Complete** — No billable API calls made. No placeholder replacement. No merge.