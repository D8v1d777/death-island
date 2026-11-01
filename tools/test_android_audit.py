import io
import struct
import unittest

from audit_android import elf_segments


def elf_fixture(alignment=16384, address=0):
    header = bytearray(64)
    header[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<Q", header, 32, 64)
    struct.pack_into("<HH", header, 54, 56, 1)
    return bytes(header) + struct.pack("<IIQQQQQQ", 1, 5, 0, address, 0, 1024, 1024, alignment)


class AndroidAlignmentTest(unittest.TestCase):
    def test_valid_16k_load(self):
        self.assertTrue(elf_segments(io.BytesIO(elf_fixture()))[0]["aligned_16k"])

    def test_old_or_incongruent_load(self):
        for data in (elf_fixture(4096), elf_fixture(16384, 4096)):
            self.assertFalse(elf_segments(io.BytesIO(data))[0]["aligned_16k"])

    def test_malformed_or_truncated_binary(self):
        for data in (b"not an elf", elf_fixture()[:-1]):
            with self.assertRaises(ValueError):
                elf_segments(io.BytesIO(data))
