# Android release readiness — 2026-10-31

**Status: stabilization / debug testing only. Not release-ready or Play-certified.**

## Verified current artifact

`build/death-island-debug.apk`, 73.0MiB, `org.deathisland.game`, version code **3**,
version **0.3.0-dev**, min API **24**, target API **35**, compile API **34**, ARM64,
OpenGL ES 3.0 requirement. VIBRATE and WAKE_LOCK are the only requested permissions.
The v2 APK signature verifies; it is the debug build, not an approved release identity.
Both current character textures are present; reference boards are absent.

```text
SHA-256: 1060c0d68f513eccb68702962a72d4ba8dac9bf0c0d61bc196d311688e23caa2
```

The build uses Godot 4.3 and matching retained templates, JDK21, Gradle8.5 and
AGP8.2.2. No release-signed APK or AAB was produced. The built artifact is generated
under ignored `build/` and distributed as a CI artifact, not committed binary junk.

## Concrete release blockers

| Gate | Actual evidence / next requirement |
|---|---|
| Target API | Current artifact targets 35. The current Play policy requires API36 for new phone/tablet apps and updates from August 31, 2026. No app-specific extension was verified |
| Native page-size support | Both ARM64 `libgodot_android.so` and `libc++_shared.so` have 4096-byte ELF LOAD alignment, failing the 16384-byte screen |
| ZIP page alignment | Uncompressed `libc++_shared.so` starts at offset 2306048 (12288 modulo 16384), failing; Godot starts at 9240576 and passes ZIP alignment, but still fails ELF alignment |
| Toolchain migration | API36 needs a coherent newer AGP/toolchain (official table: AGP8.9.1 minimum). Godot4.3 is EOL. Compatible editor/native templates and actual 16KiB execution must be qualified together; setting an NDK/SDK field cannot rebuild precompiled AAR libraries |
| Signing/AAB | Provision an app-owned upload/release key through private local/CI secret storage, validate certificate identity, non-debuggable release output and a signed AAB plus its generated split APKs. Never use the shared debug identity for production |
| Store/account gates | Play App Signing, Data safety/privacy declarations, account-specific closed testing/production-access eligibility and store review are unverified |
| Runtime/device gates | No connected handset. Native GPU, multitouch, cutouts, lifecycle, low storage, 30-minute thermals and battery are unverified |
| Art/content/licenses | Original Dave/Marie references, full production animation/content and a complete runtime notice bundle remain outstanding |

`tools/audit_android.py` performs a read-only ZIP/ELF/manifest screen, with malformed
ELF and alignment regression tests. Its report mode intentionally records blockers
without certifying a release. `--require-release` exits 1. The script does not claim
complete GNU_RELRO checking, 16KiB runtime support, AAB validation or external store
approval. CI publishes its JSON alongside the debug APK.

The current Godot4.3 requirement is retained for this stabilization PR. Upgrading or
rebuilding native templates is a coordinated migration with its own import/render/
save/device matrix; a speculative targetSdk bump would leave known native failures.

## Official policy / technical sources checked

- [Play target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Android page-size guide](https://developer.android.com/guide/practices/page-sizes)
- [2025 page-size announcement](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)
- [AGP / API support table](https://developer.android.com/studio/releases#api-level-support)
- [Godot supported-release timeline](https://docs.godotengine.org/en/stable/about/release_policy.html#release-support-timeline)
- [Godot4.5 Android 16KiB support announcement](https://godotengine.org/article/dev-snapshot-godot-4-5-beta-1/#android)
- [App bundles](https://developer.android.com/guide/app-bundle), [app signing](https://developer.android.com/studio/publish/app-signing)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Personal-account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)

The page-size sources contain different enforcement dates: the 2025 announcement
states November 1, 2025; the guide updated October 16, 2026 names February 1, 2027
for incompatible updates. Neither establishes an exemption for this new game.
The artifact's technical ELF/ZIP failures are direct evidence regardless of deadline.

## Exact short physical-device checklist (NOT RUN)

1. Connect the test phone and record model, Android/API, ABI, display dimensions and
   `adb shell getconf PAGE_SIZE`. Install with `adb install -r build/death-island-debug.apk`.
2. Time a cold title launch and New voyage separately; choose each character and
   confirm texture/HUD identity. Retain crash/logcat evidence if startup fails.
3. Play movement + camera + action simultaneously with real multitouch. Exercise
   text scale, handedness, gesture navigation/cutouts and pause menus.
4. Gather, craft, fight, complete quests, save, exit, relaunch and load. Save again
   after resource respawn. Use disposable test saves for recovery/corruption tests.
5. Background/resume and interrupt sessions; test low-storage failure without
   risking personal saves. Verify a failed save never silently discards progress.
6. Play for 30 minutes; record frame percentiles, memory trend, start/end battery,
   thermal state and stalls. Export the local frame CSV. A 4KiB phone result does
   not replace a separate 16KiB environment test.

Required release thresholds remain in `docs/QUALITY_GATES.md`. No synthetic or
software-rendered measurement is substituted for these device checks.
