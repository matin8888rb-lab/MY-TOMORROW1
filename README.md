# MY TOMORROW — VALORA

An offline, third-person 3D life simulator for Android, set in a fictional English-inspired European town around the year 2000.

## Current source baseline

The repository starts from the existing Valora Godot project and groups development into **6 major steps** instead of 10. The six steps are development milestones, not six separate APKs.

### The 6-step development plan

1. **Playable foundation** — stable 3D town, player movement, camera, touch controls and reliable Android build.
2. **Player identity** — character creator, appearance options and persistent profile.
3. **Home and daily life** — home ownership/renting, food, energy, hunger, clock and save system.
4. **Work and economy** — jobs, work shifts, Valora Crowns (VC), shops and a balanced economy.
5. **Town and relationships** — residents, schedules, conversations, activities and meaningful quests.
6. **Complete first release** — expand the town, polish visuals/audio/UI, optimize for Android and test the full gameplay loop.

## Included in the current source

- Small walkable town with a town hall, library, cafe, shop, home and employment center.
- Third-person movement with keyboard and on-screen touch controls.
- First town-hall objective and 12 VC reward.
- In-game clock, day counter, hunger and energy.
- Food purchases, resting, studying and a basic daily job shift.
- Local JSON save/load for player progress and position.
- Android landscape export preset.

## Engine and target

- Godot 4.3
- 3D with GL Compatibility renderer
- Android landscape, arm64-v8a
- Package: `com.valora.mytomorrow`

## Controls

| Action | Keyboard | Touch |
|---|---|---|
| Move | WASD / arrows | Direction buttons |
| Jump | Space | Jump button |
| Interact | E | Interaction button |

## Build and verification

Open the folder in Godot 4.3, install matching export templates, configure Android SDK/JDK paths, then run the Android export preset.

GitHub Actions is configured to parse/import the project and export a debug APK on pushes to `main`. A build is only considered successful when that workflow completes and its APK artifact is available. The project has not been device-tested merely because source files were committed.

## Structure

- `project.godot` — project and input configuration
- `scenes/main.tscn` — main scene
- `scripts/main.gd` — world, HUD, economy, interactions and save system
- `scripts/player.gd` — player controller
- `export_presets.cfg` — Android export preset
- `.github/workflows/android-apk.yml` — automated Android build
- `docs/GAME_DESIGN.md` — six-step design roadmap
