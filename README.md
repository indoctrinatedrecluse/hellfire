# Hellfire

A dark fantasy dungeon crawler and tactical orb-battler inspired by *Hellfire: The Summoning*. Featuring a slingshot card/orb ballistics engine, 2.5D receding perspective arena, ricochet physics, monster weak-point targeting, and an extensive **Evolution System** spanning 15 elements and 75 unique card forms.

Engineered from scratch in [Odin](https://odin-lang.org/) utilizing `vendor:raylib`.

---

## Features

### 1. 2.5D Dungeon Arena & Ballistics Engine
- **Receding Perspective Arena**: Deep dungeon chambers rendered with perspective flagstones, animated flickering wall torches, ambient mist, and demon gates.
- **Slingshot Trajectory Aiming**: Drag-to-aim slingshot controls with real-time predictive trajectory lines and wall ricochet previews.
- **Weak Point Targeting**: Strike glowing monster cores, eyes, and heads for **2.2x Critical Hits**, heavy screen shake, and explosive impact particles.
- **Multi-Bounce Combo Multiplier**: Consecutive ricochets and bounces escalate hit damage dynamically.
- **Turn-Based Waves**: Enemies advance and retaliate with elemental projectiles, breath weapons, and boss abilities upon turn completion.
- **5 Thematic Dungeon Environments**: *Magma Caverns*, *Sunken Temple*, *Abyssal Crypt*, *Verdant Catacombs*, and *Astral Spire*.

---

### 2. Comprehensive Evolution System (Principal Mechanic)
The core progression system empowers players to ascend their elemental cards across 5 distinct tiers of power and appearance:

- **5 Basic Elements** (Always available in deck):
  - **Fire**: Ignis Drake &rarr; Flame Valkyrie &rarr; Infernal Sorceress &rarr; Pyromancer Queen &rarr; Ignis, Hellfire Goddess
  - **Water**: Abyssal Leviathan &rarr; Coral Siren &rarr; Tide Empress &rarr; Oceanic Nereid &rarr; Tiamat, Sea Queen
  - **Earth**: Gaea Titan &rarr; Bramble Dryad &rarr; Verdant Huntress &rarr; Sylvan Matriarch &rarr; Gaea, Sovereign Mother
  - **Chaos**: Malphas Fiend &rarr; Shadow Succubus &rarr; Void Temptress &rarr; Abyssal Archduchess &rarr; Lilith, Queen of Abyss
  - **Light**: Sunstone Guard &rarr; Dawn Maiden &rarr; Seraph Valkyrie &rarr; Solar Archangel &rarr; Aurora, Light Goddess

- **10 Dual Compound Elements** ($\binom{5}{2}$ Elemental Fusions):
  - **Steam** (*Fire + Water*): Scalding vapor and hydrothermal fury.
  - **Magma** (*Fire + Earth*): Molten mantle and basalt cataclysms.
  - **Netherflame** (*Fire + Chaos*): Unholy soul-devouring purple fire.
  - **Solar** (*Fire + Light*): Blinding coronal flares and holy sunfire.
  - **Mire** (*Water + Earth*): Toxic bog blossoms and marsh decay.
  - **Abyss** (*Water + Chaos*): Crushing oceanic hadal depths and abyssal sirens.
  - **Glacier** (*Water + Light*): Sacred eternal permafrost and polar auroras.
  - **Obsidian** (*Earth + Chaos*): Sharp mirrored glass blades and necrotic fractures.
  - **Crystal** (*Earth + Light*): Diamond prism reflections and divine gemstones.
  - **Eclipse** (*Chaos + Light*): Dual-aspected balance of celestial dawn and infinite void.

- **Dynamic Floor Offerings**:
  - Each floor randomly rolls **2 Dual Element Cards** into the player's active offering pool.
  - Weighted probabilities dynamically favor elements aligned with the active dungeon theme (+65% affinity boost).
  - Once offered, dual elements can be evolved and wielded directly in combat.

- **Power Scaling & Multipliers**:
  - **Basic Cards**: $1.0\times \to 2.0\times \to 3.0\times \to 4.0\times \to 5.0\times$ base hit damage.
  - **Dual Cards**: Innate **$1.5\times$ power multiplier baseline**, scaling from $1.5\times \to 3.0\times \to 4.5\times \to 6.0\times \to 7.5\times$ base hit damage!

- **100% Unique Artwork (75 Cards Total)**:
  - Every single tier of all 15 elements features dedicated, custom character artwork (zero duplicate or shared textures across cards).

---

### 3. Dedicated Evolution Screen & Card Codex
- **Responsive Comparative View**: Large $326 \times 540$ cards comparing current stage vs. preview of next ascension form.
- **On-Card Stats & Lore**: Cards render names, epithets, base power multipliers, rarity stars (3★ to 8★), and lore directly on the card face.
- **Full-Screen Inspection Mode**: Click either card to open an expansive **$660 \times 980$** full-screen view (covering 92% screen width and 77% screen height) with detailed stat breakdowns.
- **Ascension Animation Sequence**: Multi-stage golden pulse, element-tinted radiant God Rays, flash bursts, and floating stat floats upon evolving.

---

### 4. Elemental Affinity Wheel
- **Trinity**: $\text{Fire} > \text{Earth} > \text{Water} > \text{Fire}$ ($1.5\times$ damage).
- **Polarity**: $\text{Chaos} \iff \text{Light}$ ($2.0\times$ mutual weakness).
- **Dual Coverage**: Dual elements retain the offensive advantages of both parent elements.

---

## Controls

### Combat & Dungeon
| Action | Input |
| :--- | :--- |
| **Aim Slingshot** | Left Click & Drag from bottom orb zone |
| **Fire Orb** | Release Left Click |
| **Select Basic Element** | Keys `[1]` to `[5]` (Fire, Water, Earth, Chaos, Light) |
| **Select Floor Dual Elements** | Keys `[6]` & `[7]` (Active Floor Offerings) |
| **Click Element Orbs** | Click the elemental HUD runes at the bottom of the screen |
| **Open Evolution Screen** | Key `[E]` |
| **Pause / Menu** | Key `[P]` or `[ESC]` |

### Evolution Menu
| Action | Input |
| :--- | :--- |
| **Toggle Basic / Dual Cards** | `[TAB]` |
| **Switch Selected Element** | Keys `[1]` through `[5]`, or `[6]` / `[7]` for active offerings |
| **Ascend / Evolve Card** | `[SPACE]`, `[ENTER]`, or click **ASCEND** |
| **Full-Screen Card Inspection** | Click either card (Left Click) |
| **Dismiss Inspection** | Click anywhere or press `[ESC]`, `[SPACE]`, `[E]`, `[ENTER]` |
| **Reset Stage (Testing)** | Key `[R]` or click **RESET** |
| **Return to Dungeon** | `[ESC]`, `[E]`, `[BACKSPACE]`, or click **RETURN TO DUNGEON** |

---

## Building & Running

### Requirements
- [Odin compiler](https://odin-lang.org/) (recent dev/nightly release with built-in `vendor:raylib`).

### Quick Build (Windows)
```powershell
.\build.bat
```

To compile and launch immediately:
```powershell
.\build.bat run
```

### Direct Odin Build
```powershell
odin build src -out:bin\hellfire.exe -debug
```

---

## Project Structure

```
hellfire/
├── assets/                  # High-res sprites, backgrounds, sound FX, and card textures
│   └── cards/               # 75 dedicated, distinct card textures (15 elements x 5 tiers)
├── bin/                     # Output binaries and copied runtime assets
│   └── hellfire.exe
├── src/
│   ├── main.odin            # Game loop, window initialization, frame rate management
│   ├── game.odin            # Game state controller, floor rolling, combat lifecycle
│   ├── evolution_menu.odin  # Evolution screen UI, comparison cards, inspection modal
│   ├── evolution_data.odin  # Evolution database, card lore, power multipliers, names
│   ├── card_renderer.odin   # Dynamic card canvas, wrapped typography, frames, zoom
│   ├── arena.odin           # 2.5D perspective dungeon rendering, flagstones, torches
│   ├── physics.odin         # Slingshot ballistics, raycast trajectory, wall ricochets
│   ├── monster.odin         # Monster stats, AI attacks, hitboxes, weak points, animations
│   ├── particles.odin       # Visual FX: fire embers, holy rays, sparks, hit impacts
│   ├── element.odin         # Elemental definitions, dual combinations, weakness wheel
│   ├── config.odin          # Screen resolution (720x1280), physics constants, UI sizing
│   └── sound.odin           # Audio effects, impact sounds, ascension chimes
├── build.bat                # Automated asset sync and Odin build script
├── ols.json                 # Odin Language Server configuration
└── README.md                # Project documentation
```

---

## License
Proprietary / All rights reserved.
