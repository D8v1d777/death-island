"""Reframe existing Dave/Marie SVG geometry; never redraw or regenerate character art."""

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SVG = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    sources = {}
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="character-cell-inspection-", dir=build) as temporary:
        for character in ("Dave", "Marie"):
            path = ROOT / "src/assets/illustrated" / (character + ".svg")
            text = path.read_text()
            root = ET.fromstring(text)
            if root.get("data-cell-fit"):
                raise SystemExit("Already reframed; refusing to apply another transform")
            cells = root.findall(f"{{{SVG}}}g")
            if len(cells) != 8:
                raise SystemExit("Expected exactly eight original cells")
            sources[character] = (path, text, root, cells)
            for index, cell in enumerate(cells):
                expanded = ET.Element(f"{{{SVG}}}svg", {
                    "width": "512", "height": "704", "viewBox": "-128 -128 512 704"})
                expanded.append(copy.deepcopy(root.find(f"{{{SVG}}}defs")))
                drawing = copy.deepcopy(cell)
                drawing.attrib.pop("transform")
                expanded.append(drawing)
                Path(temporary, f"{character}-{index}.svg").write_text(ET.tostring(expanded, encoding="unicode"))
        result = subprocess.run([
            os.environ.get("GODOT", "godot"), "--headless", "--path", str(ROOT / "src"),
            "--script", str(ROOT / "tools/InspectCharacterCells.gd"), "--", temporary,
        ], capture_output=True, text=True, timeout=60)
        if result.returncode or "ERROR:" in result.stdout + result.stderr:
            raise SystemExit(result.stdout + result.stderr)
        line = next(line for line in result.stdout.splitlines() if line.startswith("CELL_BOUNDS: "))
        bounds = json.loads(line.removeprefix("CELL_BOUNDS: "))
    # Common scale across every pose/identity; eight-pixel side/top clearance,
    # baseline at y=408 (the existing normal-pose foot anchor).
    scale = min(1.0, 240 / max(v[2] for v in bounds.values()), 400 / max(v[3] for v in bounds.values()))
    audit = {"method": "Original paths/colors unchanged; common scale and per-cell centering/baseline", "scale": scale, "original_bounds": bounds, "characters": {}}
    for character, (path, text, root, cells) in sources.items():
        for index, cell in enumerate(cells):
            left, top, width, height = bounds[f"{character}-{index}"]
            x = (256 - width * scale) / 2 - left * scale
            y = 408 - (top + height) * scale
            wrapper = ET.Element(f"{{{SVG}}}g", {"transform": f"translate({x:.6f} {y:.6f}) scale({scale:.6f})"})
            for child in list(cell):
                cell.remove(child)
                wrapper.append(child)
            cell.append(wrapper)
        root.set("data-cell-fit", "manual-rc1")
        corrected = ET.tostring(root, encoding="unicode") + "\n"
        audit["characters"][character] = {
            "before_sha256": hashlib.sha256(text.encode()).hexdigest(),
            "after_sha256": hashlib.sha256(corrected.encode()).hexdigest()}
        if args.apply:
            path.write_text(corrected)
    if args.apply:
        (build / "manual-rc1-frame-fit.json").write_text(json.dumps(audit, indent=2) + "\n")
    print(json.dumps(audit, indent=2))


if __name__ == "__main__":
    main()
