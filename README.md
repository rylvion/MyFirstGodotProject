# Tiny Quest
A small 2D action-platformer made in Godot where you survive waves, stack gold, and slowly become a menace.

Built from a freeCodeCamp tutorial and then expanded with extra systems, balancing, and UI polish.

## Play
Windows build: https://github.com/rylvion/MyFirstGodotProject/releases/

## Core Idea
You are a young adventurer in a dangerous world full of slimes and frogs.

Your mission:
- Survive wave after wave.
- Farm gold from enemies and cherries.
- Buy levels to boost your Max HP.
- Keep going until the game starts fighting back hard.

## Controls
- Move: WASD or Arrow Keys
- Jump/Climb Up: W, Up Arrow, or Space
- Climb Down: S or Down Arrow
- Attack (Fireball): X, Enter, or F
- Quick Level-Up: R
- Quit to Menu: Q or Escape

## Gameplay Systems
- Wave-based enemy spawning with timed delays.
- Mixed enemy pool (Frog/Slime) with level-aware spawn weighting.
- Leveling system with exponential cost growth.
- Exponential enemy difficulty scaling. 
- Gold scaling that also increases with level. (so you can keep up with costs)
- Fireball cooldown scaling by level (early linear, late exponential slowdown).
- Fireball also resets on level-up to reward progression.
- Ladder climbing support.
- Save/load persistence. 
- HUD for HP, Gold, Level, Deaths, Wave info, and Fireball cooldown feedback.
- Jump on enemies to kill them, or use fireballs for ranged attacks.
- Enemies explode on contact, so be careful!
- Cherries spawn randomly and give gold when collected.
- Death counter to track your pain and suffering.

## Current Enemy Dictionary
### Slime
A gooey green blob that looks harmless right until it tackles you.

Rarity: Common
- Base Speed: 50
- Base Damage: 3
- Base Gold: 5

### Frog
Fast, rude, and stronger than it looks.

Rarity: Common
- Base Speed: 80
- Base Damage: 5
- Base Gold: 10

## Economy and Scaling
### Level progression
- HP upgrade cost grows by x1.15 each level.
- Max HP grows by x1.1 each level.

### Enemy scaling
- Enemy Speed and Damage scale by x1.05^(level - 1).
- Enemy Gold reward scales by x1.03^(level - 1) from each enemy's own base gold.

### Fireball cooldown scaling
- Levels 1-20: cooldown decreases linearly from 3.0s to 1.0s.
- Level 21+: cooldown decreases exponentially (slower gains).
- Hard floor: cooldown never goes below 0.05s.

## Progress / What Was Added Beyond Tutorial
- Improved death handling.
- Additional enemy balancing and scaling logic.
- Ladder detection and climb behavior.
- Wave banner + cooldown UI feedback.
- Extra quality-of-life controls (quick level-up keybind).
- Better progression pacing (cost growth, reward growth, cooldown growth).

## Roadmap
- Rebirth system implementation.
- More enemy types.
- More maps/biomes.
- Boss encounter.
- Inventory + UI improvements.
- Better audio integration and balancing.
- Mobile support experiments.

## Dev Notes
First Godot project, still actively evolving. Balance changes happen often while systems get stress-tested.

If something feels broken, overpowered, or unfair, that is not a bug.
That is a challenge.
Probably.

## Credits
- Sunny Land pixel assets by @ansimuz:
  https://ansimuz.itch.io/sunny-land-pixel-game-art
- freeCodeCamp tutorial inspiration:
  https://www.youtube.com/watch?v=S8lMTwSRoRg