#!/usr/bin/env python3
"""
Process Kenney New Platformer Pack texture atlas assets into horizontal strip spritesheets
for the Death Island game's Sprite3D animation system.

The Kenney pack uses Texture Atlas format (grid of frames). This script:
1. Parses XML metadata to find frame positions
2. Groups frames by animation (idle, walk, jump, etc.) and character
3. Creates horizontal strip spritesheets for each animation
4. Generates AnimationSetResource .tres files
"""

import os
import xml.etree.ElementTree as ET
from PIL import Image
import json

# Paths
BASE_DIR = "/root/death-island-art-overhaul"
ASSET_DIR = f"{BASE_DIR}/assets-download/opengameart/kenney_new-platformer-pack"
SPRITESHEET_DIR = f"{ASSET_DIR}/Spritesheets"
OUTPUT_DIR = f"{BASE_DIR}/assets-processed"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Character colors available
CHARACTER_COLORS = ["beige", "green", "pink", "purple", "yellow"]

# Animation mapping: Kenney names -> Game animation names
ANIMATION_MAP = {
    "idle": "idle",
    "walk_a": "walk",
    "walk_b": "walk",  # alternate frame
    "run_a": "run",
    "run_b": "run",
    "jump": "jump",
    "climb_a": "climb",
    "climb_b": "climb",
    "duck": "duck",
    "hit": "hurt",
    "front": "idle",  # front facing idle
}

# For walk animation, we need to interleave walk_a and walk_b
WALK_FRAMES = ["walk_a", "walk_b"]

def parse_xml(xml_path):
    """Parse Texture Atlas XML and return dict of frame info."""
    tree = ET.parse(xml_path)
    root = tree.getroot()
    frames = {}
    for subtex in root.findall("SubTexture"):
        name = subtex.get("name")
        x = int(subtex.get("x"))
        y = int(subtex.get("y"))
        w = int(subtex.get("width"))
        h = int(subtex.get("height"))
        frames[name] = {"x": x, "y": y, "width": w, "height": h}
    return frames

def extract_frames(spritesheet_path, frames_dict, prefix_filter):
    """Extract frames matching a prefix from the spritesheet."""
    img = Image.open(spritesheet_path).convert("RGBA")
    extracted = {}
    for name, info in frames_dict.items():
        if name.startswith(prefix_filter):
            frame = img.crop((
                info["x"], info["y"],
                info["x"] + info["width"],
                info["y"] + info["height"]
            ))
            extracted[name] = frame
    return extracted

def create_horizontal_strip(frames, frame_order, output_path, frame_size=(128, 128)):
    """Create a horizontal strip spritesheet from a list of frames."""
    if not frames:
        return None

    # Calculate strip dimensions
    strip_width = frame_size[0] * len(frame_order)
    strip_height = frame_size[1]

    strip = Image.new("RGBA", (strip_width, strip_height), (0, 0, 0, 0))

    for i, frame_name in enumerate(frame_order):
        if frame_name in frames:
            frame = frames[frame_name]
            # Resize if needed
            if frame.size != frame_size:
                frame = frame.resize(frame_size, Image.LANCZOS)
            strip.paste(frame, (i * frame_size[0], 0), frame)

    strip.save(output_path)
    return {
        "start_frame": 0,
        "frame_count": len(frame_order),
        "frame_size": frame_size
    }

def process_character_spritesheets():
    """Process character spritesheets into horizontal strips."""

    # Parse XML for default size (128x128)
    xml_path = f"{SPRITESHEET_DIR}/spritesheet-characters-default.xml"
    frames_dict = parse_xml(xml_path)

    # Load the spritesheet image
    spritesheet_path = f"{SPRITESHEET_DIR}/spritesheet-characters-default.png"

    results = {}

    for color in CHARACTER_COLORS:
        prefix = f"character_{color}_"
        char_frames = extract_frames(spritesheet_path, frames_dict, prefix)

        # Create horizontal strips for each animation
        char_results = {}

        # Idle
        if f"{prefix}idle" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}idle"],
                f"{OUTPUT_DIR}/character_{color}_idle.png",
                (128, 128)
            )
            char_results["idle"] = {"start_frame": 0, "frame_count": 1, "fps": 6}

        # Walk (alternate walk_a and walk_b for 2-frame animation)
        walk_frames = [f"{prefix}walk_a", f"{prefix}walk_b"]
        if all(f in char_frames for f in walk_frames):
            create_horizontal_strip(
                char_frames, walk_frames,
                f"{OUTPUT_DIR}/character_{color}_walk.png",
                (128, 128)
            )
            char_results["walk"] = {"start_frame": 0, "frame_count": 2, "fps": 10}

        # Run (same as walk but faster)
        if all(f in char_frames for f in walk_frames):
            create_horizontal_strip(
                char_frames, walk_frames,
                f"{OUTPUT_DIR}/character_{color}_run.png",
                (128, 128)
            )
            char_results["run"] = {"start_frame": 0, "frame_count": 2, "fps": 12}

        # Attack (use hit frame)
        if f"{prefix}hit" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}hit"],
                f"{OUTPUT_DIR}/character_{color}_attack.png",
                (128, 128)
            )
            char_results["attack"] = {"start_frame": 0, "frame_count": 1, "fps": 16}

        # Gather (use duck frame)
        if f"{prefix}duck" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}duck"],
                f"{OUTPUT_DIR}/character_{color}_gather.png",
                (128, 128)
            )
            char_results["gather"] = {"start_frame": 0, "frame_count": 1, "fps": 8}

        # Drink (use front frame)
        if f"{prefix}front" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}front"],
                f"{OUTPUT_DIR}/character_{color}_drink.png",
                (128, 128)
            )
            char_results["drink"] = {"start_frame": 0, "frame_count": 1, "fps": 6}

        # Craft (use climb_a)
        if f"{prefix}climb_a" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}climb_a"],
                f"{OUTPUT_DIR}/character_{color}_craft.png",
                (128, 128)
            )
            char_results["craft"] = {"start_frame": 0, "frame_count": 1, "fps": 6}

        # Dodge (use jump frame)
        if f"{prefix}jump" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}jump"],
                f"{OUTPUT_DIR}/character_{color}_dodge.png",
                (128, 128)
            )
            char_results["dodge"] = {"start_frame": 0, "frame_count": 1, "fps": 20}

        # Hurt
        if f"{prefix}hit" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}hit"],
                f"{OUTPUT_DIR}/character_{color}_hurt.png",
                (128, 128)
            )
            char_results["hurt"] = {"start_frame": 0, "frame_count": 1, "fps": 12}

        # Death (use hit frame)
        if f"{prefix}hit" in char_frames:
            create_horizontal_strip(
                char_frames, [f"{prefix}hit"],
                f"{OUTPUT_DIR}/character_{color}_death.png",
                (128, 128)
            )
            char_results["death"] = {"start_frame": 0, "frame_count": 1, "fps": 6}

        results[color] = char_results
        print(f"Processed character: {color}")

    return results

def process_enemy_spritesheets():
    """Process enemy spritesheets into horizontal strips."""

    xml_path = f"{SPRITESHEET_DIR}/spritesheet-enemies-default.xml"
    frames_dict = parse_xml(xml_path)
    spritesheet_path = f"{SPRITESHEET_DIR}/spritesheet-enemies-default.png"

    # Enemy definitions: (prefix, animations)
    enemies = {
        "barnacle": {
            "idle": ["barnacle_attack_rest"],
            "attack": ["barnacle_attack_a", "barnacle_attack_b"],
            "hurt": ["barnacle_attack_rest"],
            "death": ["barnacle_attack_rest"],
        },
        "bee": {
            "idle": ["bee_rest"],
            "fly": ["bee_a", "bee_b"],
            "hurt": ["bee_rest"],
            "death": ["bee_rest"],
        },
        "fish_blue": {
            "idle": ["fish_blue_rest"],
            "swim": ["fish_blue_swim_a", "fish_blue_swim_b"],
            "hurt": ["fish_blue_rest"],
            "death": ["fish_blue_rest"],
        },
        "fly": {
            "idle": ["fly_rest"],
            "fly": ["fly_a", "fly_b"],
            "hurt": ["fly_rest"],
            "death": ["fly_rest"],
        },
        "frog": {
            "idle": ["frog_rest"],
            "jump": ["frog_idle", "frog_jump"],
            "hurt": ["frog_rest"],
            "death": ["frog_rest"],
        },
        "ladybug": {
            "idle": ["ladybug_rest"],
            "walk": ["ladybug_walk_a", "ladybug_walk_b"],
            "fly": ["ladybug_fly"],
            "hurt": ["ladybug_rest"],
            "death": ["ladybug_rest"],
        },
        "mouse": {
            "idle": ["mouse_rest"],
            "walk": ["mouse_walk_a", "mouse_walk_b"],
            "hurt": ["mouse_rest"],
            "death": ["mouse_rest"],
        },
        "slime_normal": {
            "idle": ["slime_normal_rest"],
            "walk": ["slime_normal_walk_a", "slime_normal_walk_b"],
            "hurt": ["slime_normal_rest"],
            "death": ["slime_normal_flat"],
        },
        "slime_fire": {
            "idle": ["slime_fire_rest"],
            "walk": ["slime_fire_walk_a", "slime_fire_walk_b"],
            "hurt": ["slime_fire_rest"],
            "death": ["slime_fire_flat"],
        },
        "slime_spike": {
            "idle": ["slime_spike_rest"],
            "walk": ["slime_spike_walk_a", "slime_spike_walk_b"],
            "hurt": ["slime_spike_rest"],
            "death": ["slime_spike_flat"],
        },
        "snail": {
            "idle": ["snail_rest"],
            "walk": ["snail_walk_a", "snail_walk_b"],
            "hurt": ["snail_shell"],
            "death": ["snail_rest"],
        },
        "worm_normal": {
            "idle": ["worm_normal_rest"],
            "move": ["worm_normal_move_a", "worm_normal_move_b"],
            "hurt": ["worm_normal_rest"],
            "death": ["worm_normal_rest"],
        },
    }

    results = {}

    for enemy_name, animations in enemies.items():
        # Find frames matching this enemy prefix
        enemy_frames = {}
        for frame_name, info in frames_dict.items():
            if frame_name.startswith(enemy_name + "_"):
                enemy_frames[frame_name] = info

        if not enemy_frames:
            print(f"No frames found for enemy: {enemy_name}")
            continue

        # Extract frames
        img = Image.open(spritesheet_path).convert("RGBA")
        extracted = {}
        for frame_name, info in enemy_frames.items():
            frame = img.crop((
                info["x"], info["y"],
                info["x"] + info["width"],
                info["y"] + info["height"]
            ))
            extracted[frame_name] = frame

        enemy_results = {}

        for anim_name, frame_names in animations.items():
            valid_frames = [f for f in frame_names if f in extracted]
            if valid_frames:
                output_path = f"{OUTPUT_DIR}/enemy_{enemy_name}_{anim_name}.png"
                create_horizontal_strip(
                    {k: extracted[k] for k in valid_frames},
                    valid_frames,
                    output_path,
                    (64, 64)
                )
                enemy_results[anim_name] = {
                    "start_frame": 0,
                    "frame_count": len(valid_frames),
                    "fps": 8 if anim_name in ["walk", "fly", "move", "swim"] else 6
                }

        results[enemy_name] = enemy_results
        print(f"Processed enemy: {enemy_name}")

    return results

def process_tiles_spritesheets():
    """Process tiles spritesheets for environment."""

    xml_path = f"{SPRITESHEET_DIR}/spritesheet-tiles-default.xml"
    frames_dict = parse_xml(xml_path)
    spritesheet_path = f"{SPRITESHEET_DIR}/spritesheet-tiles-default.png"

    # We just need the individual tiles for the tilemap
    # The game uses a different system for tiles (TileMap with individual textures)
    # But we can extract key tiles as individual images

    # Key tiles for island survival
    key_tiles = [
        "block_brown", "block_green", "block_grey", "block_yellow",
        "brick_brown", "brick_grey", "bricks_brown", "bricks_grey",
        "bridge", "bridge_logs", "bush", "cactus",
        "chain", "conveyor", "door_closed", "door_open",
        "fence", "fence_broken", "fireball",
        "flag_blue_a", "flag_red_a", "flag_yellow_a",
        "grass_center", "grass_left", "grass_right",
        "ladder", "liquid_lava", "liquid_water",
        "sign", "sign_exit", "spikes", "spring"
    ]

    img = Image.open(spritesheet_path).convert("RGBA")
    tile_dir = f"{OUTPUT_DIR}/tiles"
    os.makedirs(tile_dir, exist_ok=True)

    for tile_name in key_tiles:
        # Find exact match or prefix match
        for frame_name, info in frames_dict.items():
            if frame_name == tile_name or frame_name.startswith(tile_name + "_"):
                frame = img.crop((
                    info["x"], info["y"],
                    info["x"] + info["width"],
                    info["y"] + info["height"]
                ))
                frame.save(f"{tile_dir}/{frame_name}.png")
                break

    print("Processed tiles")
    return {"tiles": key_tiles}

def generate_animation_set_resources(char_results, enemy_results):
    """Generate AnimationSetResource .tres files."""

    tres_dir = f"{BASE_DIR}/src/resources/definitions/animations"
    os.makedirs(tres_dir, exist_ok=True)

    # Character animation set (for Dave - beige, Mara - pink/green)
    for color, anims in char_results.items():
        if not anims:
            continue

        tres_path = f"{tres_dir}/character_{color}.tres"
        with open(tres_path, "w") as f:
            f.write('[gd_resource type="AnimationSetResource" format=3]\n\n')
            f.write('animations = {\n')
            for anim_name, info in anims.items():
                f.write(f'    "{anim_name}": {{\n')
                f.write(f'        "start_frame": {info["start_frame"]},\n')
                f.write(f'        "frame_count": {info["frame_count"]},\n')
                f.write(f'        "loop": {str(anim_name in ["idle", "walk", "run"]).lower()},\n')
                f.write(f'        "fps": {info["fps"]}\n')
                f.write('    },\n')
            f.write('}\n')
            f.write('default_fps = 8.0\n')
        print(f"Generated: {tres_path}")

    # Enemy animation sets
    for enemy_name, anims in enemy_results.items():
        if not anims:
            continue

        tres_path = f"{tres_dir}/enemy_{enemy_name}.tres"
        with open(tres_path, "w") as f:
            f.write('[gd_resource type="AnimationSetResource" format=3]\n\n')
            f.write('animations = {\n')
            for anim_name, info in anims.items():
                f.write(f'    "{anim_name}": {{\n')
                f.write(f'        "start_frame": {info["start_frame"]},\n')
                f.write(f'        "frame_count": {info["frame_count"]},\n')
                f.write(f'        "loop": {str(anim_name in ["idle", "walk", "fly", "move", "swim"]).lower()},\n')
                f.write(f'        "fps": {info["fps"]}\n')
                f.write('    },\n')
            f.write('}\n')
            f.write('default_fps = 8.0\n')
        print(f"Generated: {tres_path}")

def main():
    print("Processing Kenney New Platformer Pack assets...")

    # Process character spritesheets
    char_results = process_character_spritesheets()

    # Process enemy spritesheets
    enemy_results = process_enemy_spritesheets()

    # Process tiles
    tile_results = process_tiles_spritesheets()

    # Generate AnimationSetResource files
    generate_animation_set_resources(char_results, enemy_results)

    # Save summary
    summary = {
        "characters": char_results,
        "enemies": enemy_results,
        "tiles": tile_results
    }
    with open(f"{OUTPUT_DIR}/processing_summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    print("\nDone! Assets processed to:", OUTPUT_DIR)
    print("AnimationSetResource files generated to:", f"{BASE_DIR}/src/resources/definitions/animations/")

if __name__ == "__main__":
    main()