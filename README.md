# MY TOMORROW — Stage 1 Foundation

A Godot 4 project for an offline, landscape Android life simulator set in London in 2018. The first stage establishes a small procedural city block, third-person movement, a follow camera, and Persian-first touch HUD.

## Project structure

- `project.godot` — project configuration (Godot 4, landscape, mobile renderer).
- `scenes/main.tscn` — main scene.
- `scripts/main.gd` — procedural environment, city block, camera, HUD and input.
- `scripts/player.gd` — CharacterBody3D player controller and capsule collision.
- `scripts/virtual_joystick.gd` — on-screen movement joystick.

## Controls

- Android: drag the virtual joystick at bottom-left to walk; drag on the right side to rotate the camera.
- Desktop preview: WASD to walk; hold right mouse button and drag to rotate the camera.
- Escape closes the preview.

## Run

1. Install Godot 4.x.
2. Open this repository folder in Godot using **Import**.
3. Run the project (F6/F5 or the Play button).

## Stage 1 scope

This is the foundation slice, not the full life simulator. It currently aims to provide a small walkable street with simple procedural buildings, pavements, lamps, trees, a player capsule, and camera/touch controls. Jobs, home interiors, needs, economy, NPC routines, transit simulation and story systems are later stages.

## Verification status

The source files have been added to the repository, but this environment has not run the project in the Godot editor or on an Android device. No APK has been built or tested yet. The scene, GDScript parsing, touch behavior, and mobile performance remain unverified until opened and run with Godot 4.x.
