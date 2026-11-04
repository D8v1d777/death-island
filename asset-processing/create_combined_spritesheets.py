#!/usr/bin/env python3
"""
Create combined horizontal strip spritesheets from individual animation strips
matching the AnimationSetResource definitions.
"""

import os
from PIL import Image

BASE_DIR = "/root/death-island-art-overhaul"
ASSET_DIR = f"{BASE_DIR}/src/assets/illustrated"
ANIM_DIR = f"{BASE_DIR}/src/resources/definitions/animations"
OUTPUT_DIR = f"{BASE_DIR}/src/assets/illustrated/combined"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def parse_tres(tres_path):
    """Parse AnimationSetResource .tres file and return animations dict."""
    animations = {}
    with open(tres_path, "r") as f:
        content = f.read()

    # Simple parsing for the animations dictionary
    import re
    # Find animation entries
    pattern = r'"(\w+)":\s*\{[^}]*"start_frame":\s*(\d+),\s*"frame_count":\s*(\d+),\s*"loop":\s*(\w+),\s*"fps":\s*([\d.]+)'
    matches = re.findall(pattern, content)
    for name, start, count, loop, fps in matches:
        animations[name] = {
            "start_frame": int(start),
            "frame_count": int(count),
            "loop": loop == "true",
            "fps": float(fps)
        }
    return animations

def create_combined_spritesheet(entity_name, animations, frame_size=(128, 128)):
    """Create a combined horizontal strip spritesheet for an entity."""

    # Calculate total frames
    total_frames = 0
    anim_order = []
    for anim_name, info in animations.items():
        if info["frame_count"] > 0:
            anim_order.append((anim_name, info["frame_count"]))
            total_frames += info["frame_count"]

    if total_frames == 0:
        return None

    # Create combined image
    combined_width = frame_size[0] * total_frames
    combined_height = frame_size[1]
    combined = Image.new("RGBA", (combined_width, combined_height), (0, 0, 0, 0))

    frame_index = 0
    new_animations = {}

    for anim_name, frame_count in anim_order:
        # Load individual animation strip
        strip_path = f"{ASSET_DIR}/{entity_name}_{anim_name}.png"
        if not os.path.exists(strip_path):
            print(f"  Missing strip: {strip_path}")
            continue

        strip = Image.open(strip_path).convert("RGBA")

        # The individual strip has frame_count frames horizontally
        # Extract each frame and paste into combined
        strip_frame_width = strip.width // frame_count
        for i in range(frame_count):
            frame = strip.crop((
                i * strip_frame_width, 0,
                (i + 1) * strip_frame_width, strip.height
            ))
            # Resize to standard frame size if needed
            if frame.size != frame_size:
                frame = frame.resize(frame_size, Image.LANCZOS)
            combined.paste(frame, (frame_index * frame_size[0], 0), frame)
            frame_index += 1

        new_animations[anim_name] = {
            "start_frame": frame_index - frame_count,
            "frame_count": frame_count,
            "loop": animations[anim_name]["loop"],
            "fps": animations[anim_name]["fps"]
        }

    # Save combined spritesheet
    output_path = f"{OUTPUT_DIR}/{entity_name}_combined.png"
    combined.save(output_path)
    print(f"Created: {output_path} ({total_frames} frames, {combined_width}x{combined_height})")

    return new_animations

def main():
    print("Creating combined spritesheets...")

    # Process character spritesheets
    character_colors = ["beige", "green", "pink", "purple", "yellow"]
    for color in character_colors:
        tres_path = f"{ANIM_DIR}/character_{color}.tres"
        if os.path.exists(tres_path):
            animations = parse_tres(tres_path)
            entity_name = f"character_{color}"
            new_anims = create_combined_spritesheet(entity_name, animations, (128, 128))
            if new_anims:
                # Update the .tres file with new frame positions
                update_tres(tres_path, new_anims)

    # Process enemy spritesheets
    enemy_types = ["barnacle", "bee", "fish_blue", "fly", "frog", "ladybug",
                   "mouse", "slime_normal", "slime_fire", "slime_spike", "snail", "worm_normal"]
    for enemy in enemy_types:
        tres_path = f"{ANIM_DIR}/enemy_{enemy}.tres"
        if os.path.exists(tres_path):
            animations = parse_tres(tres_path)
            entity_name = f"enemy_{enemy}"
            new_anims = create_combined_spritesheet(entity_name, animations, (64, 64))
            if new_anims:
                update_tres(tres_path, new_anims)

    print("\nDone! Combined spritesheets saved to:", OUTPUT_DIR)

def update_tres(tres_path, new_animations):
    """Update .tres file with new animation frame positions."""
    with open(tres_path, "r") as f:
        content = f.read()

    # Replace animation entries
    import re
    lines = content.split('\n')
    new_lines = []
    in_animations = False

    for line in lines:
        if 'animations = {' in line:
            in_animations = True
            new_lines.append(line)
            # Add updated animations
            for name, info in new_animations.items():
                new_lines.append(f'    "{name}": {{')
                new_lines.append(f'        "start_frame": {info["start_frame"]},')
                new_lines.append(f'        "frame_count": {info["frame_count"]},')
                new_lines.append(f'        "loop": {str(info["loop"]).lower()},')
                new_lines.append(f'        "fps": {info["fps"]}')
                new_lines.append('    },')
            continue
        if in_animations and '}' in line and 'default_fps' in lines[lines.index(line)+1] if lines.index(line)+1 < len(lines) else False:
            in_animations = False
            new_lines.append(line)
            continue
        if not in_animations or not line.strip().startswith('"'):
            if not in_animations:
                new_lines.append(line)

    # This is getting complex, let me use a simpler approach - rewrite the whole file
    # Actually, let me just regenerate the entire .tres
    new_content = '[gd_resource type="AnimationSetResource" format=3]\n\n'
    new_content += 'animations = {\n'
    for name, info in new_animations.items():
        new_content += f'    "{name}": {{\n'
        new_content += f'        "start_frame": {info["start_frame"]},\n'
        new_content += f'        "frame_count": {info["frame_count"]},\n'
        new_content += f'        "loop": {str(info["loop"]).lower()},\n'
        new_content += f'        "fps": {info["fps"]}\n'
        new_content += '    },\n'
    new_content += '}\n'
    new_content += 'default_fps = 8.0\n'

    with open(tres_path, "w") as f:
        f.write(new_content)
    print(f"Updated: {tres_path}")

if __name__ == "__main__":
    main()