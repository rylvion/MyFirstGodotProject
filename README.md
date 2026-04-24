# Tiny Quest

Tiny Quest is a small Godot 4 2D survival-action game where you fight waves, collect gold, level up, and survive long enough to deal with elite waves and boss fights.

It started from a tutorial base and has been expanded with wave progression, scaling, boss encounters, pooling, HUD systems, and save/load support.

## Play

Windows build: https://github.com/rylvion/MyFirstGodotProject/releases/

## Core Loop

- Survive waves of slimes and frogs.
- Collect gold from enemies and cherries.
- Spend gold to level up and increase your max HP.
- Use stomps and fireballs to stay alive as waves get harder.
- Fight a boss every 10 waves.

## Controls

- Move: `A/D` or Left/Right Arrow
- Jump / Climb Up: `W`, Up Arrow, or `Space`
- Climb Down: `S` or Down Arrow
- Fireball: `X`, `F`, or `Enter`
- Quick Level-Up: `R`
- Quit: `Esc`

After wave 5, pressing `Esc` opens a confirmation dialog before leaving the run.

## Current Features

- Wave-based spawning with delays and wave banners
- Grounded enemy AI with patrol + chase behavior
- Fireball combat with pooled projectiles
- Stomp kills with bounce-back feedback
- Gold and cherry collectables
- Level-up button and hotkey
- Save/load persistence
- Boss header UI with boss health bar
- Elite waves and boss waves
- Tutorial hint flow for first-time actions

## Enemies

### Slime

- Base Speed: `50`
- Base Damage: `3`
- Base Gold: `5`
- Behavior: patrols, then chases on detection

### Frog

- Base Speed: `80`
- Base Damage: `5`
- Base Gold: `10`
- Behavior: faster patrol/chase pressure than slime

### Boss Dragon

- Appears every `10` waves
- Multi-hit enemy with boss HP UI
- Grounded heavyweight movement
- Leap-slam attack with ground impact stun
- Summons elite support enemies at low HP
- Variants:
  - Wave 10: `Dragon`
  - Wave 20: `Corrupted Dragon`
  - Wave 30+: `Corrupted Elite Dragon`

## Scaling

### Player progression

- Max HP:
  - `max_hp(level) = round(10 + 2*(level-1) + 0.05*(level-1)^2)`
- HP upgrade cost:
  - `cost(level) = round(10 + 4*(level-1) + 0.25*(level-1)^2)`
- New runs always start with HP restored to max.

### Fireball cooldown

- `cooldown(level) = max(0.25, 3.0 / (1.0 + 0.12*(level-1)))`

### Normal wave scaling

- Enemies per wave:
  - `min(4 + floor((wave - 1) * 1.0), 18, available_spawn_slots)`
- Frog chance:
  - `clamp(0.30 + 0.035*(wave - 1), 0.30, 0.65)`
- Enemy speed scale:
  - `1.0 + min(0.06*(wave - 1), 1.10)`
- Enemy damage scale:
  - `1.0 + min(0.08*(wave - 1), 2.00)`
- Enemy gold scale:
  - `1.0 + 0.05*(wave - 1)`

### Elite waves

Every 5th non-boss wave is elite.

- Speed: `x1.15`
- Damage: `x1.35`
- Gold: `x1.75`

### Boss scaling

- Boss hits:
  - Wave 10: `10`
  - Wave 20: `12`
  - Wave 30+: `14`
- Boss speed scale:
  - `1.0 + min(0.04*(boss_index - 1), 0.40)`
- Boss damage scale:
  - `1.0 + min(0.10*(boss_index - 1), 0.60)`
- Boss phases:
  - Phase 2 at `65%` HP: faster chase, first elite summon
  - Phase 3 at `30%` HP: faster slam cadence, second elite summon
- Boss stomp rules:
  - Stomps only work during grounded chase windows
  - Boss stomp bounce is intentionally much weaker than normal enemies

## Performance/Tech Notes

- Fireballs are pooled instead of spawned endlessly.
- HUD is signal-driven for HP, gold, level, and boss state.
- Save spam on enemy kills was removed.
- Enemy tracking is wave-counter based instead of frame-polled scans.
- Renderer is set to `Mobile` for lighter 2D performance.

## Project Notes

- Built with Godot 4
- Solo-dev friendly architecture
- Systems are still being tuned, especially wave pacing and boss feel

## Credits

- Sunny Land pixel assets by @ansimuz:
  https://ansimuz.itch.io/sunny-land-pixel-game-art
- freeCodeCamp tutorial inspiration:
  https://www.youtube.com/watch?v=S8lMTwSRoRg