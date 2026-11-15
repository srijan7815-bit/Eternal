# ETERNAL

**A winter survival platformer. It's really hard, duh.**

ETERNAL is a pixel-art, side-view action platformer built with Godot. Play as Rowan, fight off waves of ghosts, and try to survive long enough to restore Larkspur.

## Features

- Five escalating ghost waves: **3, 5, 7, 9, and 11 enemies**.
- Ghost speed, health, and contact damage ramp up in later waves.
- Rowan's close-range attacks use animated slash effects; ghosts face Rowan as they chase.
- A one-time **BOUNCE BACK** revive with a breathing button on the game-over screen.
- Pixel-font HUD and start menu, with the ETERNAL logo as the menu background.
- Victory screen with a five-second confetti celebration.

## Controls

| Action | Controls |
| --- | --- |
| Move | **A / D** or **Left / Right Arrow** |
| Jump | **Space** |
| Attack | **J** or **Left Mouse Button** |
| Start from menu | **Start Game** button or **Enter** |
| Retry from a result screen | **R** or the on-screen button |

## Requirements

- Godot Engine **4.x** (the project was developed with Godot 4.7.x).

## Getting the project running

1. Clone or download this repository.
2. Extract `assets.zip` **into an `assets/` folder at the project root**. For example, the logo should end up at `assets/ui/eternal_logo.png` and the pixel font at `assets/fonts/PressStart2P-Regular.ttf`.
3. Open the project in Godot and set **Project Settings → Application → Run → Main Scene** to `res://scenes/main_menu.tscn`.
4. Press **F5** to run the game. Godot will import the assets the first time the project opens.

### Repository setup note

The current GitHub repository contains the scenes, scripts, and `assets.zip`, but does **not** include a root-level `project.godot`. A complete Godot project needs that file at its root. If it is not added separately, create/open a Godot project in the repository folder before running these scenes and set its main scene to `res://scenes/main_menu.tscn`.

Also check the ghost scene's script reference when assembling the project: the current `scenes/monster.tscn` points to `res://monster.gd`, while the script in this repository is under `scenes/monster.gd`. Make those paths match (or include the referenced script at the root) before running.

## Project layout

```text
scenes/       Game, player, monster, HUD, and main-menu scenes/scripts
scripts/      Shared animated-effects helper
assets.zip    Art, sprites, audio, logo, and pixel font
```

## Asset credits and licenses

The Press Start 2P font is distributed under the SIL Open Font License; its license is included in `assets.zip`. Keep the attribution and license files supplied with the other bundled assets when redistributing them. Check each asset pack's own license for its usage terms.
