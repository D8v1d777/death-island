import copy
import unittest
from xml.etree import ElementTree
from pathlib import Path

from validate_gallery import FILES, validate_manifest


class GalleryTest(unittest.TestCase):
    def setUp(self):
        self.manifest = {
            "engine": "4.3", "source_revision": "test-fixture",
            "captures": [{"file": name, "validated": True, "character_id": "dave",
                          "dimensions": [1280, 720], "sha256": "a" * 64} for name in FILES],
        }

    def test_manifest_accepts_complete_scenarios(self):
        self.assertEqual(len(validate_manifest(self.manifest)), 6)

    def test_manifest_rejects_missing_duplicate_failed_or_stale_evidence(self):
        mutations = [
            lambda m: m["captures"].pop(),
            lambda m: m["captures"].append(m["captures"][0]),
            lambda m: m["captures"][0].update(validated=False),
            lambda m: m["captures"][0].update(sha256="invalid"),
            lambda m: m.update(source_revision=""),
        ]
        for mutate in mutations:
            data = copy.deepcopy(self.manifest)
            mutate(data)
            with self.assertRaises(ValueError):
                validate_manifest(data)

    def test_character_svg_atlas_cells(self):
        folder = Path(__file__).resolve().parents[1] / "src/assets/illustrated"
        for name in ("Dave", "Marie", "Survivor", "Mara"):
            with self.subTest(character=name):
                root = ElementTree.parse(folder / (name + ".svg")).getroot()
                self.assertEqual((root.attrib["width"], root.attrib["height"]), ("2048", "448"))
                cells = root.findall("{http://www.w3.org/2000/svg}g")
                self.assertEqual(len(cells), 8)
                for index, cell in enumerate(cells):
                    self.assertEqual(cell.attrib["transform"], f"translate({256 * index} 0)")
