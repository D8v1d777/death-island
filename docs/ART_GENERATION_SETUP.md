# Death Island Character Art Generation Setup

**Version**: 1.0  
**Branch**: `feature/female-character-integration`  
**Last Updated**: 2026-11-04

---

## Overview

This document describes the character art generation pipeline for Death Island. The pipeline is **provider-independent** and supports multiple generation backends without requiring paid API access.

### Supported Providers

| Provider | API Key Required | Cost | Use Case |
|----------|-----------------|------|----------|
| **Manual** | No | Free | Import browser-generated artwork (Leonardo AI, Hugging Face Spaces, etc.) |
| **ComfyUI** | No (local) | Free* | Local/remote GPU generation via ComfyUI |
| **Replicate** | Yes | Paid | Cloud generation via Replicate API |

*ComfyUI requires a separate GPU-equipped machine. The Android development device should NOT run ComfyUI.

---

## Quick Start: Zero-API Workflow (Recommended)

### 1. Generate Images in Browser

Use any free browser-based image generation service:

- **Leonardo AI** (leonardo.ai) - Daily free credits
- **Hugging Face Spaces** (huggingface.co/spaces) - Various free models
- **Playground AI** (playgroundai.com) - Free tier
- **Microsoft Designer** (designer.microsoft.com) - Free with account
- **Local WebUI** - If you have a local Stable Diffusion WebUI

### 2. Prepare Images

Create a directory with 4 directional views named correctly:

```
/my_artwork/annie/
├── annie_front.png
├── annie_three_quarter.png
├── annie_side.png
└── annie_rear.png
```

**Requirements:**
- Format: PNG (preferred) or JPG/WebP
- Dimensions: ~1024×1024 or similar (will be resized to 128×128)
- Background: **Transparent** (critical for 2.5D sprites)
- Consistent character across all 4 views

### 3. Import with Manual Provider

```bash
cd /root/death-island-art-overhaul
python3 tools/generate_character_art.py \
  --provider manual \
  --character annie \
  --input /my_artwork/annie
```

### 4. Verify in Godot

The script will:
1. Copy images to `generated_art/annie/`
2. Create verification spritesheet: `character_annie_combined_VERIFICATION.png`
3. Copy to game assets: `src/assets/illustrated/combined/character_annie_combined_VERIFICATION.png`
4. Run Godot import

Open Godot and verify:
- Camera-facing (rotation.x = -45°)
- Scale/foot anchoring
- Visibility in beach/jungle lighting

---

## Provider Details

### Manual Provider (Zero-API)

**Purpose**: Import pre-generated images from local directory.

**Configuration:**
```bash
--provider manual --character <annie|ellie|marie> --input <directory>
```

**Expected Input Structure:**
```
<input_dir>/
├── <character>_front.png
├── <character>_three_quarter.png  (or: 3_quarter, threequarter, side_front)
├── <character>_side.png           (or: profile, side_view)
└── <character>_rear.png           (or: back, back_view)
```

**Supported extensions**: `.png`, `.jpg`, `.jpeg`, `.webp`

**Validation:**
- All 4 views must be present
- Images must be valid and readable
- Minimum 64×64 pixels
- Transparent background preserved

**Output:**
- Standardized images in `generated_art/<character>/`
- Verification spritesheet with orange placeholders for animation frames
- Provenance metadata recorded

---

### ComfyUI Provider

**Purpose**: Generate images via ComfyUI HTTP API.

**Requirements:**
- ComfyUI server running (separate machine with GPU)
- Models installed on ComfyUI machine (SDXL, FLUX, etc.)
- Network access from Android device to ComfyUI server

**Configuration:**
```bash
--provider comfyui --character <annie|ellie|marie> \
  [--comfyui-url http://<host>:8188] \
  [--workflow /path/to/workflow.json] \
  [--timeout 300]
```

**Default URL**: `http://127.0.0.1:8188`

**Security Notes:**
- Do NOT expose ComfyUI publicly without authentication
- Use VPN/Tailscale for remote access
- Do NOT run ComfyUI on Android phone (insufficient RAM/GPU)

**Workflow:**
- Provide a custom workflow JSON for character generation
- Default workflow is minimal example - customize for your models
- Workflow should accept reference image + prompt, output 1024×1024

**Hardware Requirements (for ComfyUI machine):**
| Model | VRAM (min) | RAM | Notes |
|-------|-----------|-----|-------|
| SDXL | 8 GB | 16 GB | Base + Refiner |
| FLUX Schnell | 12 GB | 24 GB | Fast, good quality |
| FLUX Dev | 24 GB | 32 GB | Higher quality |

---

### Replicate Provider

**Purpose**: Generate images via Replicate cloud API.

**Requirements:**
- Replicate account with credits
- `REPLICATE_API_TOKEN` environment variable

**Configuration:**
```bash
--provider replicate --character <annie|ellie|marie> \
  [--api-token $REPLICATE_API_TOKEN] \
  [--model flux|sdxl]
```

**Models:**
- `flux` (default): black-forest-labs/flux-schnell - Fast, good quality
- `sdxl`: stability-ai/sdxl - Higher quality, slower

**Cost**: ~$0.003-0.01 per image depending on model

**Security:**
- Never commit API token to Git
- Use environment variable: `export REPLICATE_API_TOKEN="..."`
- Token only needed for replicate provider

---

## Annie Production Specification

### Character Identity (from ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg)

| Attribute | Specification |
|-----------|---------------|
| **Name** | Annie |
| **Age Appearance** | Young adult (early 20s) |
| **Hair** | Blonde, shoulder-length, slightly messy |
| **Face** | Youthful, determined expression |
| **Build** | Slim, athletic |
| **Clothing** | Practical survival outfit |
| **Colors** | Earth tones (browns, greens, greys) |
| **Accessories** | Minimal - utility belt, pouches |
| **Silhouette** | Recognizable at distance |

### Generation Prompts

**Base Description (used in all prompts):**
```
young female survivor, blonde hair, youthful face, 
survival outfit with practical clothing, 
slim build, determined expression, 
post-apocalyptic island survivor aesthetic
```

**View-Specific Additions:**
| View | Prompt Addition |
|------|-----------------|
| Front | `full body front view, standing pose, facing camera directly` |
| Three-Quarter | `full body three-quarter view, 45 degree angle, facing slightly right` |
| Side | `full body side profile view, facing right` |
| Rear | `full body rear view, back facing camera` |

**Negative Prompt (always applied):**
```
background, watermark, text, logo, label, frame, border, 
low quality, blurry, distorted, deformed, ugly, 
duplicate, multiple characters, cropped, cut off, 
shadow on ground, perspective distortion
```

### Technical Parameters

| Parameter | Value |
|-----------|-------|
| Output Size | 1024×1024 (resized to 128×128) |
| Background | Transparent (alpha channel) |
| Style | 2.5D isometric, pixel art aesthetic |
| Lighting | Consistent, orthographic projection |
| Camera Pitch | -45° (orthographic) |
| Frame Size | 128×128 pixels |
| Combined Texture | 1536×128 (12 frames × 128px) |

---

## 12-Frame Mapping (CRITICAL)

The animation system expects this exact frame layout:

| Frames | Animation | Used By |
|--------|-----------|---------|
| **0-3** | Idle (4 frames) | idle, drink |
| **4-7** | Walk (4 frames) | walk, dodge |
| **8-11** | Run (4 frames) | run, attack_light, attack_heavy, gather, craft, hurt, death |

**Verification Spritesheet:**
- Frames 0-3: 4 directional views (front, 3/4, side, rear)
- Frames 4-11: Orange placeholders labeled "WALK 1/4" through "RUN 4/4"

**Production Spritesheet:**
- Must contain 12 genuine animation frames
- No duplicated frames across animations (unless intentionally shared per table above)

---

## Godot Integration & Visual Verification

### How Art Enters Gameplay

1. **Art.tres** registers texture: `"annie": ExtResource("character_annie_combined.png")`
2. **Annie.gd** sets: `_illustration.art_key = "annie"` and `_illustration.height = 3.2`
3. **IllustratedArt.sprite()** creates Sprite3D with:
   - `hframes = 12` (auto-detected from texture width/height)
   - `pixel_size = height / texture_height`
   - `rotation.x = CAMERA_PITCH (-PI/4)` for camera-facing
   - `position = SCREEN_UP * height * 0.43` for foot anchoring
4. **AnimatedSpriteController** plays animations based on `AnimationSetResource`

### Verification Checklist

When testing in Godot, verify:

- [ ] **Camera-facing**: Character faces camera at all rotations (rotation.x = -45°)
- [ ] **Foot anchoring**: Feet stay on ground plane (no floating/sinking)
- [ ] **Scale**: Character is ~3.2 units tall, readable at gameplay distance
- [ ] **Beach visibility**: Clear against sand background
- [ ] **Jungle visibility**: Clear against grass/foliage background
- [ ] **Transparency**: No background artifacts, clean edges
- [ ] **Directional**: All 4 views look like same character
- [ ] **Animation preview**: Idle animation plays smoothly (frames 0-3)

### Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Vertical strip | Wrong rotation.x | Ensure `rotation.x = -PI/4` |
| Floating feet | Wrong pixel_size/position | Check `pixel_size = height/texture_height` |
| Invisible | Alpha cut mode | Set `alpha_cut = ALPHA_CUT_DISABLED` |
| Wrong scale | Wrong height | Match `height` in Annie.gd (3.2) |
| Cropped limbs | Source image too tight | Generate with more padding |

---

## Asset Validation Rules

The pipeline enforces these rules automatically:

1. **File format**: PNG/JPG/WebP only
2. **Dimensions**: Minimum 64×64, recommended 1024×1024
3. **Transparency**: Alpha channel preserved
4. **Naming**: `<character>_<view>.png` convention
5. **Completeness**: All 4 views required
6. **No corruption**: Valid image headers
7. **Isolation**: Annie/Ellie/Marie never overwrite each other
8. **Protection**: Survivor/Mara assets never touched

---

## Directory Structure

```
tools/
├── generate_character_art.py      # Main entry point
└── art_providers/
    ├── __init__.py                # Provider registry
    ├── base.py                    # Base provider interface
    ├── manual_provider.py         # Zero-API import
    ├── comfyui_provider.py        # ComfyUI HTTP API
    └── replicate_provider.py      # Replicate cloud API

src/assets/illustrated/
├── ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg   # Reference (committed)
├── ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg   # Reference (committed)
├── MARIE_PRODUCTION_CHARACTER_BIBLE.jpg   # Reference (MISSING - blocker)
└── combined/
    ├── character_annie_combined.png         # Production (approved)
    ├── character_annie_combined_VERIFICATION.png  # Verification (not committed)
    ├── character_ellie_combined.png         # Production (approved)
    ├── character_ellie_combined_VERIFICATION.png  # Verification (not committed)
    └── character_marie_combined.png         # Production (approved)

generated_art/                    # .gitignored - temporary work files
├── annie/
│   ├── annie_front.png
│   ├── annie_three_quarter.png
│   ├── annie_side.png
│   ├── annie_rear.png
│   └── character_annie_combined_VERIFICATION.png
├── ellie/
└── marie/
```

---

## Workflow Enforcement

### Annie-First Rule

```bash
# Only Annie can be generated until approved
python3 tools/generate_character_art.py --provider manual --character annie --input ./annie_art

# After Annie approval in Godot:
python3 tools/generate_character_art.py --provider manual --character ellie --input ./ellie_art

# Only after Marie reference provided:
python3 tools/generate_character_art.py --provider manual --character marie --input ./marie_art
```

### Animation Production (Future)

After static verification approval:
1. Generate 12 genuine animation frames per character
2. Organize as: `{"idle": [4 paths], "walk": [4 paths], "run": [4 paths]}`
3. Use `create_animation_spritesheet()` for production texture
4. Copy to `src/assets/illustrated/combined/character_<name>_combined.png` (no VERIFICATION suffix)

---

## Testing

### Run Provider Tests
```bash
python3 tools/generate_character_art.py --list-providers
```

### Run Manual Provider Test
```bash
# Create test images
mkdir -p /tmp/test/annie
python3 -c "
from PIL import Image
for v in ['front','three_quarter','side','rear']:
    Image.new('RGBA',(128,128),(100,150,200,255)).save(f'/tmp/test/annie/annie_{v}.png')
"

# Test import
python3 tools/generate_character_art.py --provider manual --character annie --input /tmp/test/annie
```

### Run Godot Tests
```bash
cd src && GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --script tests/unit/run_tests.gd
cd src && GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --script tests/integration/run_tests.gd
```

### Run Type Check
```bash
cd src && GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . --check-only
```

---

## Security Considerations

1. **No API tokens in code**: All credentials via environment variables
2. **No secrets in logs**: Pipeline doesn't log tokens/keys
3. **Generated art not committed**: `.gitignore` excludes `generated_art/` and VERIFICATION textures
4. **ComfyUI security**: Local network only, use VPN for remote
5. **Replicate token**: Never hardcode, use `REPLICATE_API_TOKEN` env var
6. **Reference images**: Committed (they're production assets), not generated

---

## Storage Requirements

| Component | Size |
|-----------|------|
| Pipeline code | < 1 MB |
| Reference images | ~20 MB |
| Generated work (temp) | ~10 MB/character |
| Production textures | ~200 KB/character |
| ComfyUI models (external) | 10-50 GB (on GPU machine) |

**Android device**: Keep under 500 MB total project size

---

## Troubleshooting

### "Provider not available"

| Provider | Check |
|----------|-------|
| Manual | `--input` directory exists with correct files |
| ComfyUI | Server running at `--comfyui-url`, `/system_stats` returns 200 |
| Replicate | `REPLICATE_API_TOKEN` set, internet connection |

### "Missing views"

Check input directory naming:
```
annie_front.png ✓
annie_3_quarter.png ✓ (alias)
annie_profile.png ✓ (alias for side)
annie_back.png ✓ (alias for rear)
```

### "Godot import failed"

Run manually: `godot --headless --path src --import`

Check `.import` files are generated in `src/assets/illustrated/combined/`

### "Character invisible in game"

1. Check `rotation.x = -PI/4` in `IllustratedArt.gd`
2. Check `pixel_size = height / texture_height`
3. Check texture has `alpha_cut = ALPHA_CUT_DISABLED`
4. Verify `.import` file has correct settings

---

## Status Tracking

| Task | Status |
|------|--------|
| Provider architecture | ✅ Implemented |
| Manual provider | ✅ Implemented & Tested |
| ComfyUI provider | ✅ Implemented (untested - needs ComfyUI server) |
| Replicate provider | ✅ Implemented (refactored) |
| Annie production spec | ✅ Documented |
| Ellie production spec | ⏳ Pending (after Annie) |
| Marie production spec | ❌ Blocked (missing reference) |
| Animation production | ⏳ Pending (after static approval) |
| ART_GENERATION_SETUP.md | ✅ Created |
| FEMALE_ART_PIPELINE_AUDIT.md | ✅ Updated |
| Unit tests (40) | ✅ Passing |
| Integration tests (145) | ✅ Passing |
| Godot type check | ⏳ Running |

---

## Next Steps

1. **Wait for Godot type check to complete**
2. **Generate Annie static artwork** (manual provider or ComfyUI)
3. **Verify in Godot** (screenshots required)
4. **After approval**: Generate Ellie
5. **After Marie reference provided**: Generate Marie
6. **After all static approved**: Plan genuine animation production

---

*This document is the single source of truth for the character art generation pipeline. Update it when providers, workflows, or specifications change.*