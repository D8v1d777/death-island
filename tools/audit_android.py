"""Report APK release blockers without extracting libraries or modifying an artifact.

This screens ELF/ZIP alignment, not full GNU_RELRO/runtime/Play compliance.
Use --require-release to fail on known blockers; report mode is not certification.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import zipfile

PAGE_SIZE = 16384


def elf_segments(stream) -> list[dict]:
    header = stream.read(64)
    if len(header) != 64 or header[:6] != b"\x7fELF\x02\x01":
        raise ValueError("Expected little-endian ELF64")
    offset = struct.unpack_from("<Q", header, 32)[0]
    size, count = struct.unpack_from("<HH", header, 54)
    if size < 56 or count == 0 or count > 128 or offset > 1024 * 1024:
        raise ValueError("Invalid ELF program-header table")
    stream.seek(offset)
    table = stream.read(size * count)
    if len(table) != size * count:
        raise ValueError("Truncated ELF program-header table")
    loads = []
    for index in range(count):
        kind, _, file_offset, address, _, _, _, alignment = struct.unpack_from("<IIQQQQQQ", table, size * index)
        if kind == 1:
            loads.append({"alignment": alignment, "offset": file_offset, "address": address,
                          "aligned_16k": alignment >= PAGE_SIZE and (address - file_offset) % PAGE_SIZE == 0})
    if not loads:
        raise ValueError("ELF contains no LOAD segments")
    return loads


def audit(apk: Path) -> dict:
    libraries = []
    with zipfile.ZipFile(apk) as archive, apk.open("rb") as raw:
        bad = archive.testzip()
        if bad:
            raise ValueError("Corrupt ZIP entry: " + bad)
        for info in archive.infolist():
            if not info.filename.endswith(".so"):
                continue
            raw.seek(info.header_offset)
            name_length, extra_length = struct.unpack_from("<HH", raw.read(30), 26)
            data_offset = info.header_offset + 30 + name_length + extra_length
            with archive.open(info) as stream:
                segments = elf_segments(stream)
            libraries.append({
                "path": info.filename, "load_segments": segments,
                "elf_16k": all(segment["aligned_16k"] for segment in segments),
                "zip_16k": info.compress_type != zipfile.ZIP_STORED or data_offset % PAGE_SIZE == 0,
                "zip_data_offset": data_offset,
            })
    aapt = shutil.which("aapt") or str(
        Path(os.environ.get("ANDROID_HOME", str(Path.home() / "Android"))) / "build-tools/34.0.0/aapt"
    )
    badging = subprocess.check_output([aapt, "dump", "badging", str(apk)], text=True)
    target = int(re.search(r"targetSdkVersion:'(\d+)'", badging)[1])
    debuggable = "application-debuggable" in badging
    blockers = []
    if target < 36:
        blockers.append("Target API is below the current API36 new-app/update requirement")
    if debuggable:
        blockers.append("APK is debuggable")
    if not libraries or not all(lib["elf_16k"] and lib["zip_16k"] for lib in libraries):
        blockers.append("Native ELF/ZIP 16KiB alignment requirements fail")
    blockers.extend([
        "Release certificate identity and signed AAB not validated by this screen",
        "GNU_RELRO, 16KiB execution and physical-device acceptance require separate verification",
        "Play Console declarations, testing eligibility and store review remain external gates",
    ])
    with apk.open("rb") as stream:
        checksum = hashlib.file_digest(stream, "sha256").hexdigest()
    return {"apk": apk.name, "sha256": checksum, "target_sdk": target,
            "debuggable": debuggable, "libraries": libraries, "release_blockers": blockers,
            "release_ready": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--require-release", action="store_true")
    args = parser.parse_args()
    report = audit(args.apk)
    text = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")
    if args.require_release and not report["release_ready"]:
        raise SystemExit(1)
