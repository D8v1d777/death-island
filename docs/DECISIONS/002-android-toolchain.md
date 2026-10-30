# ADR 002: API 35 exports on an ARM64 Linux host

Godot 4.3's standard prebuilt APK template only supports its default API levels.
Use its Gradle source template to produce min SDK 24 / target SDK 35 packages.

The bundled AGP 8.2.0 / Gradle 8.2 combination is incompatible with JDK 21's image
transform. Generate the template with AGP **8.2.2**, Gradle **8.5**, Java source/target
17, and JDK **21** as the host. The wrapper distribution checksum is pinned.

Google's Linux SDK binaries are x86-only. On an ARM64 host the build tool creates
a local SDK overlay with native distro adb, zipalign and aapt2; Java SDK components
and source platforms are linked from the installed SDK. The original SDK is
preserved. Gradle uses two workers, a 1.5 GiB heap and a single-use daemon.

This is a debug build toolchain. Play publication additionally requires release
signing, a compatible AAB configuration, current platform requirements and device
validation. Do not label a debug export as a release candidate.
