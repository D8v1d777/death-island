#!/usr/bin/env python3
"""
Image Generation Pipeline for Death Island Character Artwork

Provider-independent character art generation with support for:
- Manual: Import pre-generated images from local directory (zero API)
- ComfyUI: Local/remote ComfyUI HTTP API (optional, no API key)
- Replicate: Cloud API (optional, requires API token)

Usage:
    # Manual provider (zero API) - import browser-generated images
    python3 tools/generate_character_art.py --provider manual --character annie --input ./my_artwork/annie

    # ComfyUI provider (local server)
    python3 tools/generate_character_art.py --provider comfyui --character annie --comfyui-url http://192.168.1.100:8188

    # Replicate provider (cloud API)
    python3 tools/generate_character_art.py --provider replicate --character annie --api-token $REPLICATE_API_TOKEN
"""

import os
import sys
import argparse
import shutil
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any, List
from dataclasses import dataclass

# Add tools directory to path for provider imports
sys.path.insert(0, str(Path(__file__).parent))

from art_providers import (
    ProviderRegistry,
    create_manual_provider,
    create_comfyui_provider,
    create_replicate_provider,
    BaseArtProvider,
    GenerationResult,
    ProviderConfig
)

from PIL import Image, ImageDraw


@dataclass
class CharacterSpec:
    name: str
    reference_path: str
    description: str
    output_dir: str
    views: List[str] = None

    def __post_init__(self):
        if self.views is None:
            self.views = ["front", "three_quarter", "side", "rear"]


# Character specifications
CHARACTERS = {
    "annie": CharacterSpec(
        name="Annie",
        reference_path="src/assets/illustrated/ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg",
        description=(
            "young female survivor, blonde hair, youthful face, "
            "survival outfit with practical clothing, "
            "slim build, determined expression, "
            "post-apocalyptic island survivor aesthetic"
        ),
        output_dir="generated_art/annie"
    ),
    "ellie": CharacterSpec(
        name="Ellie",
        reference_path="src/assets/illustrated/ELLIE_PRODUCTION_CHARACTER_BIBLE.jpg",
        description=(
            "young female survivor, dark hair, wearing glasses, "
            "olive green tank top, blue jeans, "
            "practical accessories, athletic build, "
            "intelligent resourceful look, "
            "post-apocalyptic island survivor aesthetic"
        ),
        output_dir="generated_art/ellie"
    ),
    "marie": CharacterSpec(
        name="Marie",
        reference_path="src/assets/illustrated/MARIE_PRODUCTION_CHARACTER_BIBLE.jpg",
        description=(
            "female survivor, original reference identity, "
            "post-apocalyptic island survivor aesthetic"
        ),
        output_dir="generated_art/marie"
    ),
}


def create_verification_spritesheet(
    view_paths: Dict[str, str],
    character_name: str,
    output_dir: str,
    frame_size: int = 128
) -> str:
    """Create spritesheet for STATIC VERIFICATION ONLY.

    Places 4 directional views in frames 0-3 (idle slots).
    Frames 4-11 (walk/run slots) are marked as orange placeholders
    indicating where genuine animation frames will go later.

    This matches the animation system's frame layout:
    - Frames 0-3: idle (and drink)
    - Frames 4-7: walk (and dodge)
    - Frames 8-11: run (and attack_light, attack_heavy, gather, craft, hurt, death)
    """
    views_order = ["front", "three_quarter", "side", "rear"]
    images = []

    for view in views_order:
        if view in view_paths:
            img = Image.open(view_paths[view]).convert("RGBA")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
            images.append(img)
        else:
            # Magenta = missing view
            img = Image.new("RGBA", (frame_size, frame_size), (255, 0, 255, 128))
            images.append(img)

    # 12 frames horizontally for character animation layout
    combined_width = frame_size * 12
    combined = Image.new("RGBA", (combined_width, frame_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(combined)

    # Frames 0-3: Place the 4 directional views in idle slots
    for i in range(4):
        if i < len(images):
            combined.paste(images[i], (i * frame_size, 0))
        else:
            # Magenta placeholder
            ph = Image.new("RGBA", (frame_size, frame_size), (255, 0, 255, 128))
            combined.paste(ph, (i * frame_size, 0))

    # Frames 4-11: Orange placeholders for animation frames (walk/run)
    for i in range(4, 12):
        ph = Image.new("RGBA", (frame_size, frame_size), (255, 165, 0, 180))
        combined.paste(ph, (i * frame_size, 0))
        # Label the frame with its intended animation
        try:
            if i < 8:
                label = f"WALK\n{i-3}/4"
            else:
                label = f"RUN\n{i-7}/4"
            # Draw text centered
            bbox = draw.textbbox((0, 0), label)
            text_w = bbox[2] - bbox[0]
            text_h = bbox[3] - bbox[1]
            x = i * frame_size + (frame_size - text_w) // 2
            y = (frame_size - text_h) // 2
            draw.text((x, y), label, fill=(255, 255, 255, 255))
        except:
            pass  # Font not available, skip labeling

    output_path = os.path.join(output_dir, f"character_{character_name.lower()}_combined_VERIFICATION.png")
    combined.save(output_path)
    print(f"Created VERIFICATION spritesheet: {output_path}")
    print("  Frames 0-3: Directional views (front, 3/4, side, rear) -> idle slots")
    print("  Frames 4-7: Orange placeholders -> walk animation slots")
    print("  Frames 8-11: Orange placeholders -> run/attack/gather/hurt/death slots")
    return output_path


def create_animation_spritesheet(
    animation_frames: Dict[str, List[str]],  # {"idle": [4 paths], "walk": [4 paths], "run": [4 paths]}
    character_name: str,
    output_dir: str,
    frame_size: int = 128
) -> str:
    """Create PRODUCTION spritesheet from genuine animation frames.

    Expected input: 12 unique frame paths organized by animation.
    Frame layout matches AnimationSetResource.create_survivor_set():
    - Frames 0-3: idle (4 frames)
    - Frames 4-7: walk (4 frames)
    - Frames 8-11: run (4 frames) - shared with attack_light, attack_heavy, gather, craft, hurt, death
    """
    combined_width = frame_size * 12
    combined = Image.new("RGBA", (combined_width, frame_size), (0, 0, 0, 0))

    frame_index = 0

    # Idle frames (0-3)
    for i in range(4):
        if "idle" in animation_frames and i < len(animation_frames["idle"]):
            img = Image.open(animation_frames["idle"][i]).convert("RGBA")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
            combined.paste(img, (frame_index * frame_size, 0))
        else:
            ph = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
            combined.paste(ph, (frame_index * frame_size, 0))
        frame_index += 1

    # Walk frames (4-7)
    for i in range(4):
        if "walk" in animation_frames and i < len(animation_frames["walk"]):
            img = Image.open(animation_frames["walk"][i]).convert("RGBA")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
            combined.paste(img, (frame_index * frame_size, 0))
        else:
            ph = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
            combined.paste(ph, (frame_index * frame_size, 0))
        frame_index += 1

    # Run frames (8-11)
    for i in range(4):
        if "run" in animation_frames and i < len(animation_frames["run"]):
            img = Image.open(animation_frames["run"][i]).convert("RGBA")
            img = img.resize((frame_size, frame_size), Image.Resampling.LANCZOS)
            combined.paste(img, (frame_index * frame_size, 0))
        else:
            ph = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
            combined.paste(ph, (frame_index * frame_size, 0))
        frame_index += 1

    output_path = os.path.join(output_dir, f"character_{character_name.lower()}_combined.png")
    combined.save(output_path)
    print(f"Created PRODUCTION spritesheet: {output_path}")
    return output_path


def copy_to_game_assets(spritesheet_path: str, character_name: str, is_verification: bool = True) -> str:
    """Copy spritesheet to game assets directory."""
    game_assets_dir = "src/assets/illustrated/combined"
    os.makedirs(game_assets_dir, exist_ok=True)

    suffix = "_VERIFICATION" if is_verification else ""
    game_filename = f"character_{character_name.lower()}_combined{suffix}.png"
    game_path = os.path.join(game_assets_dir, game_filename)

    shutil.copy2(spritesheet_path, game_path)
    print(f"Copied to game assets: {game_path}")
    return game_path


def run_godot_import() -> bool:
    """Run Godot import to process new textures."""
    try:
        result = subprocess.run(
            ["godot", "--headless", "--path", "src", "--import"],
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode == 0:
            print("Godot import completed successfully")
            return True
        else:
            print(f"Godot import failed: {result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print("Godot import timed out")
        return False
    except Exception as e:
        print(f"Godot import error: {e}")
        return False


def create_provider(args) -> BaseArtProvider:
    """Create provider instance based on command line arguments."""
    provider_name = args.provider.lower()

    if provider_name == "manual":
        if not args.input:
            raise ValueError("Manual provider requires --input directory")
        return create_manual_provider(input_dir=args.input)

    elif provider_name == "comfyui":
        return create_comfyui_provider(
            comfyui_url=args.comfyui_url,
            workflow_path=args.workflow,
            timeout=args.timeout
        )

    elif provider_name == "replicate":
        if not args.api_token and not os.environ.get("REPLICATE_API_TOKEN"):
            raise ValueError("Replicate provider requires --api-token or REPLICATE_API_TOKEN env var")
        return create_replicate_provider(
            api_token=args.api_token,
            default_model=args.model
        )

    else:
        raise ValueError(f"Unknown provider: {provider_name}. Available: {ProviderRegistry.list_providers()}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate character artwork for Death Island",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Manual provider (zero API) - import browser-generated images
  python3 tools/generate_character_art.py --provider manual --character annie --input ./my_artwork/annie

  # ComfyUI provider (local/remote server)
  python3 tools/generate_character_art.py --provider comfyui --character annie --comfyui-url http://localhost:8188

  # Replicate provider (cloud API)
  python3 tools/generate_character_art.py --provider replicate --character annie --api-token $REPLICATE_API_TOKEN

Providers:
  manual    - Import pre-generated images from local directory (NO API KEY REQUIRED)
  comfyui   - Generate via ComfyUI HTTP API (local/remote, no API key)
  replicate - Generate via Replicate cloud API (requires API token)
"""
    )

    # Provider selection
    parser.add_argument("--provider", choices=["manual", "comfyui", "replicate"],
                       default="manual", help="Generation provider (default: manual)")

    # Character selection
    parser.add_argument("--character", choices=["annie", "ellie", "marie"],
                       help="Character to generate (required unless --list-providers)")

    # Output directory
    parser.add_argument("--output-dir", default="generated_art",
                       help="Base output directory (default: generated_art)")

    # Manual provider args
    parser.add_argument("--input", help="Input directory for manual provider (required for manual)")

    # ComfyUI provider args
    parser.add_argument("--comfyui-url", default="http://127.0.0.1:8188",
                       help="ComfyUI server URL (default: http://127.0.0.1:8188)")
    parser.add_argument("--workflow", help="Path to ComfyUI workflow JSON")
    parser.add_argument("--timeout", type=int, default=300,
                       help="Generation timeout in seconds (default: 300)")

    # Replicate provider args
    parser.add_argument("--api-token", help="Replicate API token (or set REPLICATE_API_TOKEN env var)")
    parser.add_argument("--model", choices=["flux", "sdxl"], default="flux",
                       help="Replicate model to use (default: flux)")

    # General options
    parser.add_argument("--skip-import", action="store_true",
                       help="Skip Godot import step")
    parser.add_argument("--list-providers", action="store_true",
                       help="List available providers and exit")

    args = parser.parse_args()

    # List providers and exit
    if args.list_providers:
        print("Available providers:")
        availability = ProviderRegistry.check_provider_availability()
        for name, status in availability.items():
            print(f"  {name}: {status}")
        return

    # Get character spec
    if args.character not in CHARACTERS:
        print(f"ERROR: Unknown character: {args.character}")
        sys.exit(1)

    spec = CHARACTERS[args.character]
    spec.output_dir = f"{args.output_dir}/{args.character}"

    # Validate reference image exists
    if not os.path.exists(spec.reference_path):
        print(f"ERROR: Reference image not found: {spec.reference_path}")
        if args.character == "marie":
            print("Marie's original reference is not available in the repository.")
            print("Expected: src/assets/illustrated/MARIE_PRODUCTION_CHARACTER_BIBLE.jpg")
            print("Please provide the original user-supplied Marie reference image.")
        sys.exit(1)

    # Create provider
    try:
        provider = create_provider(args)
    except ValueError as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    # Validate provider config
    valid, error = provider.validate_config()
    if not valid:
        print(f"ERROR: Provider configuration invalid: {error}")
        sys.exit(1)

    # Check provider availability
    if not provider.is_available():
        print(f"WARNING: Provider '{provider.name}' reports as not available.")
        print("This may be expected (e.g., ComfyUI server not running).")
        if args.provider != "manual":
            response = input("Continue anyway? [y/N]: ")
            if response.lower() != 'y':
                sys.exit(1)

    print(f"Using provider: {provider.name}")
    print(f"Character: {spec.name}")
    print(f"Reference: {spec.reference_path}")
    print(f"Output dir: {spec.output_dir}")
    print(f"Views: {spec.views}")
    print()

    # Generate views
    try:
        result: GenerationResult = provider.generate_views(
            reference_path=spec.reference_path,
            character_name=spec.name,
            character_description=spec.description,
            views=spec.views,
            output_dir=spec.output_dir,
            model=args.model if hasattr(args, 'model') else "flux"
        )
    except Exception as e:
        print(f"Generation failed: {e}")
        sys.exit(1)

    if not result.success:
        print(f"Generation failed: {result.error}")
        sys.exit(1)

    print(f"Successfully generated {len(result.view_paths)} views")
    print(f"Provider metadata: {result.metadata}")
    print()

    # Create verification spritesheet
    spritesheet = create_verification_spritesheet(
        result.view_paths, args.character, spec.output_dir
    )

    # Copy to game assets
    copy_to_game_assets(spritesheet, args.character, is_verification=True)

    # Run Godot import
    if not args.skip_import:
        run_godot_import()

    print()
    print("=== NEXT STEPS ===")
    print("1. Run Godot and verify character in-game:")
    print("   - Camera-facing (rotation.x = -45°)")
    print("   - Scale/foot anchoring (pixel_size = height/texture_height)")
    print("   - Visibility in beach/jungle lighting")
    print("2. Only after visual approval, proceed to genuine animation generation")
    print("3. For production: generate 12 unique animation frames and use create_animation_spritesheet()")


if __name__ == "__main__":
    main()