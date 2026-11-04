# Female Character Art Pipeline Audit

**Date**: 2026-11-04  
**Branch**: `feature/female-character-integration`  
**Latest Commit**: `b9079aa` (chore: add female character art pipeline script and audit)  
**Status**: AUDIT UPDATED — Script fixed and committed. Provider architecture not yet implemented.

---

## 1. Script Verification (UPDATED)

| Item | Value |
|------|-------|
| **Script Path** | `/root/death-island-art-overhaul/tools/generate_character_art.py` |
| **Git Status** | ✅ Committed in `b9079aa` |
| **git status --short** | (clean) |
| **Lines of Code** | ~430 |
| **Dependencies** | requests, pillow (system), argparse |

**Note**: Script is now in `tools/` directory, committed without credentials.

---

## 2. Current Atlas-Assembly Logic Analysis (FIXED)

### Previous Bug (now fixed)
The old `create_spritesheet_from_views()` incorrectly duplicated 4 directional views 3× each to fill 12 frames.

### Current Implementation (FIXED in `b9079aa`)

**`create_verification_spritesheet()`** — Static verification phase:
- Frames 0-3: 4 genuine directional views (front, three_quarter, side, rear) → idle slots
- Frames 4-7: Orange placeholders labeled "WALK 1/4" through "WALK 4/4" → walk slots  
- Frames 8-11: Orange placeholders labeled "RUN 1/4" through "RUN 4/4" → run/attack/gather/craft/hurt/death slots

**`create_animation_spritesheet()`** — Production phase (for future genuine animation):
- Accepts 12 unique frames organized as: `{"idle": [4 paths], "walk": [4 paths], "run": [4 paths]}`
- Maps to correct 12-frame layout matching `AnimationSetResource.create_survivor_set()`

---

## 3. Explicit 12-Frame Mapping Table (UNCHANGED - CORRECT)

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

**Critical**: Four directional illustrations are NOT four animation frames. The verification spritesheet makes this explicit with orange placeholders.

---

## 4. Genuine Animation Artwork Required (UNCHANGED)

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

---

## 5. Asset Isolation Verification (UNCHANGED - VERIFIED)

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

## 6. Annie-First Workflow Compliance (ENFORCED)

| Step | Requirement | Status |
|------|-------------|--------|
| 1 | Generate Annie static artwork only | ⏳ Pending (requires provider implementation + token/backend) |
| 2 | Verify in Godot gameplay | ⏳ Pending |
| 3 | Camera-facing (rotation.x = -PI/4) | ⏳ Verify after import |
| 4 | Scale/foot anchoring (pixel_size = height/texture_height) | ⏳ Verify after import |
| 5 | Beach/jungle visibility | ⏳ Verify after import |
| 6 | Only then proceed to Ellie | ✅ Enforced by workflow |
| 7 | Only then proceed to Marie (with reference) | ✅ Enforced by workflow |
| 8 | Genuine animations after static approval | ✅ Enforced by workflow |

---

## 7. Marie Blocker (UNCHANGED)

**Exact Blocker**: "Original user-supplied unnamed female NPC reference (Marie)" — **no such file exists in the repository**.

**Searches performed**:
- `find /root/death-island-art-overhaul -iname "*marie*"` → Only returns placeholder assets created during NPC integration
- `find /root/death-island-art-overhaul -iname "*Marie*"` → Same
- `grep -r "Marie" --include="*.jpg" --include="*.png" --include="*.svg"` → No original reference

**Expected filename**: `src/assets/illustrated/MARIE_PRODUCTION_CHARACTER_BIBLE.jpg`

**Action Required**: User must provide the original Marie reference image. Do not invent/replace.

---

## 8. Remaining Blockers (UPDATED)

| Blocker | Type | Resolution |
|---------|------|------------|
| **Replicate API mandatory** | Architecture | Implement provider abstraction (Phase B) |
| **No zero-API workflow** | Feature | Implement manual provider (Phase C) |
| **No ComfyUI integration** | Feature | Implement optional ComfyUI provider (Phase D) |
| **No Replicate API token** | External | Optional after provider abstraction |
| **Marie reference missing** | Asset | User must provide original reference |
| **Annie/Ellie static verification not done** | Validation | Requires working provider + Godot import |
| **Godot import pipeline untested for new assets** | Integration | Test after first generation |
| **Tests not updated for new architecture** | Testing | Add provider/asset validation tests |
| **Documentation not updated** | Docs | Create ART_GENERATION_SETUP.md |

---

## 9. Implementation Status Summary

| Component | Status |
|-----------|--------|
| NPC Infrastructure (Annie/Ellie/Marie) | ✅ Complete (`e48a0a9`) |
| Art.tres texture registration | ✅ Complete |
| Script committed to `tools/` | ✅ Complete (`b9079aa`) |
| Atlas-assembly logic fixed | ✅ Complete (verification + production functions) |
| Provider abstraction | ⏳ **Phase B - Next** |
| Manual provider (zero-API) | ⏳ **Phase C - Next** |
| ComfyUI provider | ⏳ **Phase D - Next** |
| Replicate provider (optional) | ⏳ **Phase B/C - Refactor existing** |
| Annie production spec | ⏳ **Phase E - Next** |
| Test suite updates | ⏳ **Phase F - Next** |
| Documentation | ⏳ **Phase G - Next** |

---

**Audit Updated** — Reflects actual repository state as of commit `b9079aa`. Ready for Phase B implementation.