# Rune Cast Godot and mobile setup

## Development baseline

Use Godot 4.7.2 Standard with GDScript and the Compatibility renderer. The pinned Windows x64 editor is installed locally by tools/bootstrap-godot.ps1. Its archive is checked against the official SHA-512 sums before extraction.

The project uses a 720 by 1600 portrait design canvas and a 450 by 1000 desktop preview. Canvas scaling preserves aspect ratio. Shorter windows can scroll the prototype controls; final safe-area behaviour remains a device-testing task.

The editor's self-contained marker keeps editor settings beside the portable executable. Runtime sound preferences use Godot's normal user data directory. Launch scripts put verification logs in output/qa.

## Windows commands

```powershell
.\tools\bootstrap-godot.ps1
.\tools\godot.ps1 -Action editor
.\tools\godot.ps1 -Action run
.\tools\godot.ps1 -Action test
.\tools\godot.ps1 -Action smoke
.\tools\godot.ps1 -Action capture
```

Editor import scans are available with -Action import. An alternate editor can be supplied through GODOT_BIN. The bootstrap is Windows x64-specific; on another operating system download the matching Standard editor and import project.godot.

## Android

The Android preset targets arm64 and uses the development identifier com.example.runecast. This is a placeholder; replace it before distribution.

To build for a device:

1. Install export templates matching Godot 4.7.2.
2. Install the JDK and Android SDK versions required by this engine's exporter.
3. Set Java SDK Path and Android SDK Path in Godot Editor Settings.
4. Verify the Android preset's package identifier and version.
5. Export a debug APK for local testing.
6. Configure the release keystore and Gradle/AAB path when preparing distribution.

The foundation does not install Android Studio, the Android SDK, or signing credentials. Do not commit private keystores or credentials.

## iOS

The iOS preset is included with placeholder bundle identifier com.example.runecast and an empty signing team. A real team is required for signing.

Godot iOS export requires **macOS with Xcode**. Open this same project on the Mac, install the matching export templates, configure the bundle identifier and Apple team, then export the Xcode project. Build and test from Xcode. Windows preview checks do not verify iOS builds.

## Packaging boundaries

Export includes the runtime JSON definitions explicitly. Documentation, tests, tools, and reference images are excluded. No paid assets, platform accounts, external services, analytics, or backend are required by the foundation.

No installable Android or iOS build has been produced. The export presets prepare the project structure; they do not supply missing SDKs, signing identities, or device validation.

## Official references

- [Godot Windows download](https://godotengine.org/download/windows/)
- [Godot Android export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Godot iOS export requirements](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [Godot scalable UI textures](https://docs.godotengine.org/en/stable/classes/class_styleboxtexture.html)

