# ADR 001: Repair the prototype and build a compact authored island

The initial M1 commit contains invalid Godot scenes/resources and disconnected
gameplay. Keep Godot 4.3, the Compatibility renderer, component APIs and resource
definitions, but replace the broken implementations with a testable game loop.

* `Main.tscn` remains a logic-free bootstrap. GameManager owns a persistent
  `/root/GameWorld` and `/root/UILayer`; tests can start these without replacing
  their runner scene. Loading is threaded and errors leave a usable menu.
* Content packs contain typed item, recipe and enemy subresources. The island
  layout is hand-authored in a resource, instantiated using shared low-poly
  primitive meshes. This is a fixed map, not procedural world generation.
* Keep pre-existing lowercase script paths to preserve references; new scripts
  use PascalCase. Use gdformat's standard tab indentation consistently rather
  than the contradictory four-space rule in CONTRIBUTING.
* Inventory is an aggregate dictionary with stack-aware slot accounting. All
  exchanges validate the complete post-transaction inventory before committing.
* Save v2 retains the 18-byte v1 header and CRC32 JSON payload. Writes use a
  verified temporary file, backups and atomic rename. Payload size and structure
  are bounded; no objects/scripts are deserialized. Save I/O is bounded to 2 MiB
  and synchronous at pause/milestone boundaries; device latency must be measured
  before claiming the main-thread performance gate passes.
* UI emits requests to GameManager/gameplay systems. Content is read-only.
  Player actions are shared by touch, keyboard and gamepad.
* Runtime logging is centralized in LoggerGlobal; its console output is the
  sole exception to the production print restriction. Tests may print results.
* New automated tests exercise actual components and game flow, replacing
  toy dictionary tests and runners that reported success after errors.

This is an implementation decision, not certification of device performance,
art completion or release readiness. Manual quality gates remain explicit.
