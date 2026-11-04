#!/usr/bin/env python3
"""
Fix .tres files to include proper script reference for AnimationSetResource.
"""

import os
import re

ANIM_DIR = "/root/death-island-art-overhaul/src/resources/definitions/animations"

def fix_tres(tres_path):
    """Fix .tres file to include script reference."""
    with open(tres_path, "r") as f:
        content = f.read()

    # Check if already has script reference
    if 'ext_resource type="Script"' in content and 'script = ExtResource' in content:
        print(f"Already fixed: {tres_path}")
        return

    # Find the animations dictionary
    # Replace the first line with proper header
    lines = content.split('\n')

    # Find where animations dict starts
    anim_start = None
    for i, line in enumerate(lines):
        if 'animations = {' in line:
            anim_start = i
            break

    if anim_start is None:
        print(f"Could not find animations dict in {tres_path}")
        return

    # Build new content
    new_content = '[gd_resource type="Resource" script_class="AnimationSetResource" load_steps=2 format=3]\n'
    new_content += '[ext_resource type="Script" path="res://scripts/data/AnimationSetResource.gd" id="script"]\n'
    new_content += '[resource]\n'
    new_content += 'script = ExtResource("script")\n\n'
    new_content += '\n'.join(lines[anim_start:])

    with open(tres_path, "w") as f:
        f.write(new_content)
    print(f"Fixed: {tres_path}")

def main():
    for filename in os.listdir(ANIM_DIR):
        if filename.endswith('.tres'):
            fix_tres(os.path.join(ANIM_DIR, filename))
    print("Done fixing .tres files")

if __name__ == "__main__":
    main()