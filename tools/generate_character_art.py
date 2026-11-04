#!/usr/bin/env python3
"""
Image Generation Pipeline for Death Island Character Artwork
Uses Replicate API directly via HTTP requests
"""

import os
import sys
import json
import time
import base64
import requests
from pathlib import Path
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
import argparse

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


class ReplicateClient:
    """Direct HTTP client for Replicate API"""

    def __init__(self, api_token: str):
        self.api_token = api_token
        self.base_url = "https://api.replicate.com/v1"
        self.headers = {
            "Authorization": f"Token {api_token}",
            "Content-Type": "application/json"
        }

    def create_prediction(self, model: str, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a prediction"""
        url = f"{self.base_url}/predictions"
        payload = {
            "version": model,
            "input": input_data
        }
        response = requests.post(url, headers=self.headers, json=payload)
        response.raise_for_status()
        return response.json()

    def get_prediction(self, prediction_id: str) -> Dict[str, Any]:
        """Get prediction status"""
        url = f"{self.base_url}/predictions/{prediction_id}"
        response = requests.get(url, headers=self.headers)
        response.raise_for_status()
        return response.json()

    def wait_for_completion(self, prediction_id: str, timeout: int = 300, poll_interval: int = 5) -> Dict[str, Any]:
        """Wait for prediction to complete"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            result = self.get_prediction(prediction_id)
            status = result.get("status")
            if status == "succeeded":
                return result
            elif status == "failed":
                raise Exception(f"Prediction failed: {result.get('error', 'Unknown error')}")
            elif status == "canceled":
                raise Exception("Prediction was canceled")
            time.sleep(poll_interval)
        raise TimeoutError(f"Prediction timed out after {timeout} seconds")

    def generate_image(self, model: str, input_data: Dict[str, Any], timeout: int = 300) -> List[str]:
        """Generate image and return output URLs"""
        prediction = self.create_prediction(model, input_data)
        result = self.wait_for_completion(prediction["id"], timeout)
        return result.get("output", [])


def encode_image_to_base64(image_path: str) -> str:
    """Encode image to base64 string"""
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def download_image(url: str, output_path: str) -> bool:
    """Download image from URL"""
    try:
        response = requests.get(url, stream=True, timeout=60)
        response.raise_for_status()
        with open(output_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False


class CharacterArtPipeline:
    """Pipeline for generating character artwork from reference images"""

    def __init__(self, api_token: str):
        self.client = ReplicateClient(api_token)
        # Using Stable Diffusion XL or similar for character generation
        # Model versions from Replicate
        self.models = {
            "sdxl": "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
            "flux": "black-forest-labs/flux-schnell:987739f9e2e9d3e5e5c5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5e5",
        }

    def generate_character_view(
        self,
        reference_path: str,
        view: str,
        character_name: str,
        character_description: str,
        output_dir: str,
        model: str = "flux"
    ) -> Optional[str]:
        """Generate a single character view"""

        # Build prompt based on view and character description
        view_prompts = {
            "front": "full body front view, standing pose, facing camera directly",
            "three_quarter": "full body three-quarter view, 45 degree angle, facing slightly right",
            "side": "full body side profile view, facing right",
            "rear": "full body rear view, back facing camera"
        }

        view_prompt = view_prompts.get(view, view_prompts["front"])

        # Reference image as base64 for img2img
        reference_b64 = encode_image_to_base64(reference_path)

        # Build prompt
        prompt = (
            f"{character_description}, {view_prompt}, "
            "2.5D isometric game character sprite, pixel art style, "
            "transparent background, clean edges, game-ready asset, "
            "consistent lighting, orthographic projection, "
            "high quality, detailed, professional game art"
        )

        negative_prompt = (
            "background, watermark, text, logo, label, frame, border, "
            "low quality, blurry, distorted, deformed, ugly, "
            "duplicate, multiple characters, cropped, cut off, "
            "shadow on ground, perspective distortion"
        )

        input_data = {
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "image": f"data:image/jpeg;base64,{reference_b64}",
            "strength": 0.7,
            "num_inference_steps": 30,
            "guidance_scale": 7.5,
            "num_outputs": 1,
        }

        try:
            print(f"Generating {character_name} {view} view...")
            output_urls = self.client.generate_image(self.models[model], input_data)

            if output_urls:
                output_filename = f"{character_name.lower()}_{view}.png"
                output_path = os.path.join(output_dir, output_filename)
                if download_image(output_urls[0], output_path):
                    print(f"  Saved to {output_path}")
                    return output_path
            return None
        except Exception as e:
            print(f"Error generating {view} view: {e}")
            return None

    def generate_all_views(
        self,
        spec: CharacterSpec,
        model: str = "flux"
    ) -> Dict[str, str]:
        """Generate all views for a character"""
        os.makedirs(spec.output_dir, exist_ok=True)

        results = {}
        for view in spec.views:
            result = self.generate_character_view(
                spec.reference_path,
                view,
                spec.name,
                spec.description,
                spec.output_dir,
                model
            )
            if result:
                results[view] = result

        return results


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
    from PIL import Image, ImageDraw, ImageFont

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
    from PIL import Image

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
            # Transparent placeholder
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


def main():
    parser = argparse.ArgumentParser(description="Generate character artwork from references")
    parser.add_argument("--api-token", required=True, help="Replicate API token")
    parser.add_argument("--character", choices=["annie", "ellie", "marie"], required=True)
    parser.add_argument("--model", choices=["sdxl", "flux"], default="flux")
    parser.add_argument("--output-dir", default="generated_art")

    args = parser.parse_args()

    # Character specifications
    characters = {
        "annie": CharacterSpec(
            name="Annie",
            reference_path="src/assets/illustrated/ANNIE_PRODUCTION_CHARACTER_BIBLE.jpg",
            description=(
                "young female survivor, blonde hair, youthful face, "
                "survival outfit with practical clothing, "
                "slim build, determined expression, "
                "post-apocalyptic island survivor aesthetic"
            ),
            output_dir=f"{args.output_dir}/annie"
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
            output_dir=f"{args.output_dir}/ellie"
        ),
        "marie": CharacterSpec(
            name="Marie",
            reference_path="",  # Need to find original reference
            description=(
                "female survivor, original reference identity, "
                "post-apocalyptic island survivor aesthetic"
            ),
            output_dir=f"{args.output_dir}/marie"
        ),
    }

    spec = characters[args.character]

    if not os.path.exists(spec.reference_path):
        print(f"ERROR: Reference image not found: {spec.reference_path}")
        if args.character == "marie":
            print("Marie's original reference is not available in the repository.")
            print("Please provide the original user-supplied Marie reference image.")
        sys.exit(1)

    pipeline = CharacterArtPipeline(args.api_token)
    results = pipeline.generate_all_views(spec, args.model)

    if results:
        # Create VERIFICATION spritesheet (static phase - 4 views in idle slots)
        spritesheet = create_verification_spritesheet(
            results, args.character, args.output_dir
        )

        # Copy to game assets directory (with VERIFICATION suffix for clarity)
        game_assets_dir = "src/assets/illustrated/combined"
        os.makedirs(game_assets_dir, exist_ok=True)

        import shutil
        game_path = os.path.join(game_assets_dir, f"character_{args.character}_combined_VERIFICATION.png")
        shutil.copy2(spritesheet, game_path)
        print(f"Copied to game assets: {game_path}")

        # Run Godot import
        import subprocess
        subprocess.run(["godot", "--headless", "--path", "src", "--import"], capture_output=True)
        print("Godot import completed")
        print()
        print("=== NEXT STEPS ===")
        print("1. Run Godot and verify character in-game:")
        print("   - Camera-facing (rotation.x = -45°)")
        print("   - Scale/foot anchoring (pixel_size = height/texture_height)")
        print("   - Visibility in beach/jungle lighting")
        print("2. Only after visual approval, proceed to genuine animation generation")
        print("3. For production: generate 12 unique animation frames and use create_animation_spritesheet()")
    else:
        print("No views generated successfully")
        sys.exit(1)


if __name__ == "__main__":
    main()