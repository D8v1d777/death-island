# ADR 003: Illustrated 2.5D presentation and storage budget

The owner requested an illustrated, fixed-angle presentation inspired by the
visual category of Mad Island, and six actual gameplay captures in the README.

Keep the tested 3D physics and gameplay coordinates. Replace visible primitive
actors/props with original illustrated, foot-anchored sprites under a fixed
orthographic camera. Direction changes flip the art; action frames are driven by
real gathering, combat, consumption, crafting and movement events. The camera
can zoom but no longer freely orbits. Saves keep their existing world coordinates.

Original SVG illustrations are generated reproducibly from `tools/illustrate.py`.
They use outlines, gradients, layered details and a coordinated palette. No Mad
Island assets are extracted, copied or included. The source assets are compact;
Godot imports them once into textures. World decor is explicitly authored in a
resource. Ground textures are small and tiled; no large downloaded asset pack.

Storage: before work, the filesystem had 21.173 GiB available. An explicit audit
reclaimed 2.986 GiB of redundant export-template downloads, unused platform
templates and reproducible Android intermediates. Source, saves, signing keys,
Android/ARM64 templates and dependency downloads were preserved. Android builds
now require an 8 GiB free reserve. `tools/storage.py` audits by default and prunes
only its explicit allowlist with `--apply`.

Screenshots must come from the running game through its real action APIs. A
reproducible capture runner may prepare scene/inventory fixtures, but images are
not composited, painted over or presented as physical-phone captures. Six WebP
images are used to keep repository and phone storage small.
