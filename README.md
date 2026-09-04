# Hellfire

A dark fantasy dungeon crawler inspired by *Hellfire: The Summoning*, featuring a card/orb flick ballistics mechanic, 2.5D perspective arena, ricochet physics, elemental weaknesses, and turn-based wave progression. Written in [Odin](https://odin-lang.org/) using `vendor:raylib`.

## Features
- **2.5D Dungeon Arena**: Receding perspective stone chamber with animated flickering torches, perspective flagstones, and demon gates.
- **Card/Orb Flick Ballistics**: Touch/drag slingshot aiming with real-time predictive trajectory and angled wall ricochets.
- **Weak Point Targeting**: Strike monster glowing cores/heads for 2.2x critical strikes and screen shake.
- **Elemental Affinity Wheel**: Fire > Earth > Water > Fire, Chaos <-> Light.
- **Combo System**: Multi-bounce ricochets amplify damage and score.
- **Wave Progression**: Descent through deeper dungeon chambers with boss encounters.

## Building & Running

### Requirements
- [Odin compiler](https://odin-lang.org/) (nightly / recent release with `vendor:raylib`)

### Quick Build (Windows)
```powershell
.\build.bat
```

To build and immediately launch:
```powershell
.\build.bat run
```

Or build directly with Odin:
```powershell
odin build src -out:bin\hellfire.exe -debug
```

## Controls
- **Left Click & Drag** (from bottom circle): Aim slingshot trajectory
- **Release Left Click**: Launch orb into dungeon
- **Keys `[1]` to `[5]`** or **Click bottom stones**: Switch active element (Fire, Water, Earth, Chaos, Light)
- **Space / Enter**: Start game from title screen
