# Tiny Quest

Tiny Quest is a 2D wave-survival action game built in Godot 4. You clear enemy waves, collect gold, scale your stats, and push through elite and boss milestones.

Current in-project version: v0.10-alpha

## Play

Windows build:
https://github.com/rylvion/MyFirstGodotProject/releases/

## Tech Stack

- Engine: Godot 4.5
- Renderer: Mobile
- Save schema: 2
- Scene entry point: res://scenes/main/main.tscn

## Core Loop

- Clear wave encounters of slimes and frogs.
- Collect gold from kills and pickups.
- Buy level-ups to increase max HP and survivability.
- Use saber slashes, fireballs, and stomp kills to control pressure.
- Handle elite waves every 5 waves and boss waves every 10 waves (starting at wave 10).
- Finish at wave 30 to trigger run victory.

## Controls

- Move: A / D
- Jump: W
- Crouch / Fast-fall: S
- Fireball: F
- Saber Slash: Left Mouse Button
- Quick Level-Up: R
- Settings: M
- Back / Quit: Esc
- Command Bar: F1 or Backquote

Notes:
- After wave 5, Esc opens a confirmation dialog before exiting to menu.
- Command bar supports: wave <n>, boss, gold <n>, level <n>, heal, clear, help.

## Current Systems

- Wave spawner with telegraphed spawn markers.
- Normal, elite, and boss wave states with dedicated UI feedback.
- Boss header with name, HP bar, and attack callouts.
- Fireball pooling to avoid runtime spawn churn.
- Saber slash spawn container and single-active-slash guard.
- Burn stack support on player side (with HUD feedback hooks).
- Tutorial hint progression tracked in save data.
- Input block state used for UI/modal safety.
- Startup time capture and display hooks.

## Settings Menu

The settings panel is available from:
- Main menu "Settings" button
- In-game via M key

Current settings include:
- Auto Levelling (default ON)
- Disable Tutorial
- Master Volume
- Sound Scale
- Music Volume
- SFX Volume
- Auto-save Interval
- Key Rebinding (move, jump, fireball, level-up, settings toggle, quit)
- Save Now
- Reset Defaults
- Reset Progress (with danger-styled confirmation)

Behavior notes:
- Opening settings pauses gameplay simulation.
- Music and currently playing SFX keep running while settings is open.
- New SFX requests are blocked while paused.
- Background menu parallax still animates while settings is open.

## Enemy Roster

### Slime

- Base speed: 50
- Base damage: 3
- Base gold: 5

### Frog

- Base speed: 80
- Base damage: 5
- Base gold: 10

### Boss Dragon

- Spawns on boss waves (10, 20, 30).
- Uses multi-phase behavior with attack state machine.
- Summons support packs at phase thresholds.
- Variants by boss index:
  - Wave 10: Dragon
  - Wave 20: Corrupted Dragon
  - Wave 30: Corrupted Elite Dragon

## Scaling Reference

### Player progression

- Max HP formula:
  - max_hp(level) = round(10 + 2*(level-1) + 0.05*(level-1)^2)
- Level-up cost formula:
  - cost(level) = round(10 + 4*(level-1) + 0.25*(level-1)^2)
- Fireball cooldown:
  - cooldown(level) = max(0.25, 3.0 / (1.0 + 0.12*(level-1)))

### Sustain rules

- Lifesteal on kill: +1 HP
- Wave clear heal: +10 HP
- Boss wave clear heal: +25 HP

### Normal wave scaling

- Enemies per wave:
  - min(4 + floor((wave-1) * 1.0), 18, available_spawn_slots)
- Frog chance:
  - clamp(0.30 + 0.035*(wave-1), 0.30, 0.65)
- Enemy speed scale:
  - 1.0 + min(0.06*(wave-1), 1.10)
- Enemy damage scale:
  - 1.0 + min(0.08*(wave-1), 2.00)
- Enemy gold scale:
  - 1.0 + 0.05*(wave-1)

### Elite multipliers

- Speed x1.15
- Damage x1.35
- Gold x1.75

### Boss scaling

- Boss hits by index:
  - Boss 1 (wave 10): 10
  - Boss 2 (wave 20): 12
  - Boss 3 (wave 30): 14
- Boss speed scale:
  - 1.0 + min(0.04*(boss_index-1), 0.40)
- Boss damage scale:
  - 1.0 + min(0.14*(boss_index-1), 0.90)
- Boss gold scale:
  - 1.0 + 0.20*(boss_index-1)
- Phase thresholds:
  - Phase 2 at 65% HP
  - Phase 3 at 30% HP

## Save and Persistence

- Save path: user://savegame.bin
- Autosave delay: 12 seconds after dirty state changes
- Tracks HP, max HP, gold, level, wins, last victory wave, and tutorial progress.

## Audio

Audio buses:
- Master
- Music
- SFX

### Music (3 soundtrack tracks)

- main_menu: bijaybro-anime-inspiring-music-389687.ogg
- world_loop: sekuora-epic-orchestra-anime-intro-242461.ogg
- boss_soundtrack: nyxaurora-final-battle-ii-epic-cinematic-battle-music-with-intense-orchestral-361155.ogg

### SFX Keys

- slime_move
- frog
- enemy_explode
- slash
- slash_hit
- roar
- fireball
- pickup_collectable
- victory
- growl
- game_over

## Audio and Licensing

- Third-party audio licensing details are documented in res://audio/LICENSE.
- Pixabay music and SFX source files are intended to remain untracked and can be restored locally when preparing builds.

## Credits

- Sunny Land pixel assets by ansimuz:
  https://ansimuz.itch.io/sunny-land-pixel-game-art
- freeCodeCamp tutorial inspiration:
  https://www.youtube.com/watch?v=S8lMTwSRoRg