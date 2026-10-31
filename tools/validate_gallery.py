"""Validate gallery evidence/README links; raster decoding is handled by Godot."""

import argparse
import hashlib
import json
from pathlib import Path
import re

FILES = [
    "01-wreckshore-walk.webp", "02-jungle-gather.webp", "03-boar-combat.webp",
    "04-campfire-cooking.webp", "05-inventory-crafting.webp", "06-shelter-building.webp",
]


def validate_manifest(manifest: dict) -> list[dict]:
    captures = manifest.get("captures", [])
    if [entry.get("file") for entry in captures] != FILES:
        raise ValueError("Gallery must contain exactly the six ordered current scenarios")
    if not manifest.get("source_revision") or not manifest.get("engine"):
        raise ValueError("Missing source revision or engine evidence")
    for entry in captures:
        if entry.get("validated") is not True or entry.get("character_id") not in ("dave", "marie"):
            raise ValueError("Unvalidated gameplay or character identity")
        if entry.get("dimensions") != [1280, 720] or not re.fullmatch(r"[a-f0-9]{64}", entry.get("sha256", "")):
            raise ValueError("Invalid dimensions or image digest")
    return captures


def validate(folder: Path, readme: Path | None = None) -> None:
    captures = validate_manifest(json.loads((folder / "gallery.json").read_text()))
    digests = set()
    for entry in captures:
        data = (folder / entry["file"]).read_bytes()
        if data[:4] != b"RIFF" or data[8:12] != b"WEBP" or int.from_bytes(data[4:8], "little") + 8 != len(data):
            raise ValueError("Malformed WebP container: " + entry["file"])
        digest = hashlib.sha256(data).hexdigest()
        if digest != entry["sha256"] or digest in digests:
            raise ValueError("Stale or duplicate capture: " + entry["file"])
        digests.add(digest)
    if readme:
        links = re.findall(r"!\[[^\]]*\]\((docs/images/[^)]+)\)", readme.read_text())
        if links != ["docs/images/" + name for name in FILES]:
            raise ValueError("README does not reference exactly the six current captures")
        for link in links:
            if not (readme.parent / link).is_file():
                raise ValueError("Broken README image link: " + link)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--readme", type=Path)
    args = parser.parse_args()
    validate(args.folder, args.readme)
    print("GALLERY FILES: six distinct files, validated evidence and links")
