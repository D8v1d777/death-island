"""Boundary checks without allocating disk space or deleting files."""

from types import SimpleNamespace
import unittest
from unittest.mock import patch

import storage


class StorageTest(unittest.TestCase):
    def test_floor_and_pause_boundaries(self):
        self.assertEqual(storage.MIN_FREE, 15 * 1024**3)
        for amount in (15 * 1024**3 - 1, 15 * 1024**3, 18 * 1024**3):
            with self.subTest(amount=amount):
                with patch("storage.shutil.disk_usage", return_value=SimpleNamespace(free=amount)):
                    with self.assertRaises(SystemExit):
                        storage.require_space()

    def test_above_pause_threshold(self):
        with patch("storage.shutil.disk_usage", return_value=SimpleNamespace(free=18 * 1024**3 + 1)):
            storage.require_space()


if __name__ == "__main__":
    unittest.main()
