package hellfire

import rl "vendor:raylib"

Element :: enum {
    // Basic 5 Elements (0..4)
    FIRE,
    WATER,
    EARTH,
    CHAOS,
    LIGHT,

    // Dual / Compound Elements 5C2 (5..14)
    STEAM,       // Fire + Water
    MAGMA,       // Fire + Earth
    NETHERFLAME, // Fire + Chaos
    SOLAR,       // Fire + Light
    MIRE,        // Water + Earth
    ABYSS,       // Water + Chaos
    GLACIER,     // Water + Light
    OBSIDIAN,    // Earth + Chaos
    CRYSTAL,     // Earth + Light
    ECLIPSE,     // Chaos + Light
}

TOTAL_BASIC_ELEMENTS :: 5
TOTAL_DUAL_ELEMENTS  :: 10
TOTAL_ELEMENTS       :: 15
DUAL_ELEMENT_START   :: 5

Game_State :: enum {
    TITLE,
    BATTLE_AIMING,
    BATTLE_FLYING,
    WAVE_CLEARED,
    GAME_OVER,
    EVOLUTION_MENU,
}

MAX_EVO_STAGES :: 5

Environment_Type :: enum {
    ABYSSAL_CRYPT,
    MAGMA_CAVERNS,
    SUNKEN_TEMPLE,
    VERDANT_CATACOMBS,
    ASTRAL_SPIRE,
}

Environment_Theme :: struct {
    type:           Environment_Type,
    name:           string,
    title_name:     cstring,
    bg_void:        rl.Color,
    floor_color:    rl.Color,
    floor_grid:     rl.Color,
    wall_color:     rl.Color,
    wall_border:    rl.Color,
    wall_trim:      rl.Color,
    arch_color:     rl.Color,
    gate_glow:      rl.Color,
    gate_ring:      rl.Color,
    torch_core:     rl.Color,
    torch_outer:    rl.Color,
    torch_halo:     rl.Color,
    ambient_color1: rl.Color,
    ambient_color2: rl.Color,
    particle_glyph: string,
}

MAX_TRAIL_POINTS   :: 24
MAX_PARTICLES      :: 320
MAX_AMBIENT        :: 48
MAX_DAMAGE_TEXTS   :: 32
MAX_COMBO_POPUPS   :: 8
MAX_SHOCKWAVES     :: 8
MAX_BLOCKS         :: 6

Orb :: struct {
    pos:         [2]f32,
    vel:         [2]f32,
    radius:      f32,
    element:     Element,
    active:      bool,
    bounces:     int,
    combo:       int,
    trail:       [MAX_TRAIL_POINTS][2]f32,
    trail_count: int,
    trail_timer: f32,
}

Enemy :: struct {
    pos:         [2]f32,
    depth_z:     f32,     // 0.0 (deepest) to 1.0 (closest)
    radius:      f32,
    max_hp:      int,
    current_hp:  int,
    element:     Element,
    name:        string,
    weak_offset: [2]f32,  // Local offset from pos
    weak_radius: f32,
    hurt_timer:  f32,
    alive:       bool,
    pulse_phase: f32,
}

Dungeon_Block :: struct {
    pos:        [2]f32,
    size:       [2]f32,
    depth_z:    f32,
    max_hp:     int,
    current_hp: int,
    element:    Element,
    active:     bool,
    hurt_timer: f32,
}

Particle :: struct {
    pos:      [2]f32,
    vel:      [2]f32,
    color:    rl.Color,
    size:     f32,
    life:     f32,
    max_life: f32,
}

Ambient_Particle :: struct {
    pos:      [2]f32,
    vel:      [2]f32,
    color:    rl.Color,
    size:     f32,
    life:     f32,
    max_life: f32,
    phase:    f32,
}

Damage_Number :: struct {
    pos:      [2]f32,
    vel:      [2]f32,
    text:     string,
    color:    rl.Color,
    is_crit:  bool,
    life:     f32,
    max_life: f32,
}

Combo_Popup :: struct {
    pos:         [2]f32,
    combo_count: int,
    multiplier:  f32,
    title:       string,
    life:        f32,
    max_life:    f32,
    scale:       f32,
    color:       rl.Color,
}

Shockwave :: struct {
    pos:        [2]f32,
    radius:     f32,
    max_radius: f32,
    color:      rl.Color,
    life:       f32,
    max_life:   f32,
}

Screen_Shake :: struct {
    intensity: f32,
    timer:     f32,
}

is_dual_element :: proc(elem: Element) -> bool {
    return int(elem) >= DUAL_ELEMENT_START
}

get_element_parents :: proc(elem: Element) -> (Element, Element) {
    #partial switch elem {
    case .STEAM:       return .FIRE, .WATER
    case .MAGMA:       return .FIRE, .EARTH
    case .NETHERFLAME: return .FIRE, .CHAOS
    case .SOLAR:       return .FIRE, .LIGHT
    case .MIRE:        return .WATER, .EARTH
    case .ABYSS:       return .WATER, .CHAOS
    case .GLACIER:     return .WATER, .LIGHT
    case .OBSIDIAN:    return .EARTH, .CHAOS
    case .CRYSTAL:     return .EARTH, .LIGHT
    case .ECLIPSE:     return .CHAOS, .LIGHT
    case:              return elem, elem
    }
}

element_name :: proc(elem: Element) -> string {
    switch elem {
    case .FIRE:        return "Fire"
    case .WATER:       return "Water"
    case .EARTH:       return "Earth"
    case .CHAOS:       return "Chaos"
    case .LIGHT:       return "Light"
    case .STEAM:       return "Steam"
    case .MAGMA:       return "Magma"
    case .NETHERFLAME: return "Netherflame"
    case .SOLAR:       return "Solar"
    case .MIRE:        return "Mire"
    case .ABYSS:       return "Abyss"
    case .GLACIER:     return "Glacier"
    case .OBSIDIAN:    return "Obsidian"
    case .CRYSTAL:     return "Crystal"
    case .ECLIPSE:     return "Eclipse"
    }
    return "Unknown"
}

element_primary_color :: proc(elem: Element) -> rl.Color {
    switch elem {
    case .FIRE:        return COLOR_FIRE_PRIMARY
    case .WATER:       return COLOR_WATER_PRIMARY
    case .EARTH:       return COLOR_EARTH_PRIMARY
    case .CHAOS:       return COLOR_CHAOS_PRIMARY
    case .LIGHT:       return COLOR_LIGHT_PRIMARY
    case .STEAM:       return COLOR_STEAM_PRIMARY
    case .MAGMA:       return COLOR_MAGMA_PRIMARY
    case .NETHERFLAME: return COLOR_NETHERFLAME_PRIMARY
    case .SOLAR:       return COLOR_SOLAR_PRIMARY
    case .MIRE:        return COLOR_MIRE_PRIMARY
    case .ABYSS:       return COLOR_ABYSS_PRIMARY
    case .GLACIER:     return COLOR_GLACIER_PRIMARY
    case .OBSIDIAN:    return COLOR_OBSIDIAN_PRIMARY
    case .CRYSTAL:     return COLOR_CRYSTAL_PRIMARY
    case .ECLIPSE:     return COLOR_ECLIPSE_PRIMARY
    }
    return rl.WHITE
}

element_secondary_color :: proc(elem: Element) -> rl.Color {
    switch elem {
    case .FIRE:        return COLOR_FIRE_SECONDARY
    case .WATER:       return COLOR_WATER_SECONDARY
    case .EARTH:       return COLOR_EARTH_SECONDARY
    case .CHAOS:       return COLOR_CHAOS_SECONDARY
    case .LIGHT:       return COLOR_LIGHT_SECONDARY
    case .STEAM:       return COLOR_STEAM_SECONDARY
    case .MAGMA:       return COLOR_MAGMA_SECONDARY
    case .NETHERFLAME: return COLOR_NETHERFLAME_SECONDARY
    case .SOLAR:       return COLOR_SOLAR_SECONDARY
    case .MIRE:        return COLOR_MIRE_SECONDARY
    case .ABYSS:       return COLOR_ABYSS_SECONDARY
    case .GLACIER:     return COLOR_GLACIER_SECONDARY
    case .OBSIDIAN:    return COLOR_OBSIDIAN_SECONDARY
    case .CRYSTAL:     return COLOR_CRYSTAL_SECONDARY
    case .ECLIPSE:     return COLOR_ECLIPSE_SECONDARY
    }
    return rl.WHITE
}

Element_Effectiveness :: enum {
    SUPER_EFFECTIVE, // 1.85x
    EFFECTIVE,       // 1.45x
    NEUTRAL,         // 1.00x
    RESISTED,        // 0.65x
}

// Full affinity system:
// Basic 5-element cycle & affinities:
// Water > Fire > Earth > Light > Chaos > Water (1.85x)
// Dual elements inherit both parent elements' affinities, triggering high synergy combos!
element_interaction :: proc(attacker, defender: Element) -> (mult: f32, effect: Element_Effectiveness, label: string) {
    // If attacker is a dual element, resolve synergies through its parent components
    if is_dual_element(attacker) {
        p1, p2 := get_element_parents(attacker)
        _, eff1, _ := element_interaction(p1, defender)
        _, eff2, _ := element_interaction(p2, defender)

        if eff1 == .SUPER_EFFECTIVE || eff2 == .SUPER_EFFECTIVE {
            #partial switch attacker {
            case .STEAM:       return 1.85, .SUPER_EFFECTIVE, "SCALDING BURST!"
            case .MAGMA:       return 1.85, .SUPER_EFFECTIVE, "MOLTEN ERUPTION!"
            case .NETHERFLAME: return 1.85, .SUPER_EFFECTIVE, "HELLFIRE BLAST!"
            case .SOLAR:       return 1.85, .SUPER_EFFECTIVE, "CORONA FLARE!"
            case .MIRE:        return 1.85, .SUPER_EFFECTIVE, "TOXIC QUAGMIRE!"
            case .ABYSS:       return 1.85, .SUPER_EFFECTIVE, "ABYSSAL CRUSH!"
            case .GLACIER:     return 1.85, .SUPER_EFFECTIVE, "PERMAFROST SHATTER!"
            case .OBSIDIAN:    return 1.85, .SUPER_EFFECTIVE, "OBSIDIAN CLEAVE!"
            case .CRYSTAL:     return 1.85, .SUPER_EFFECTIVE, "PRISMATIC SPLENDOR!"
            case .ECLIPSE:     return 1.85, .SUPER_EFFECTIVE, "TOTAL ECLIPSE!"
            }
            return 1.85, .SUPER_EFFECTIVE, "ASCENDED STRIKE!"
        }

        if eff1 == .EFFECTIVE || eff2 == .EFFECTIVE {
            return 1.50, .EFFECTIVE, "DUAL SYNERGY!"
        }

        // If one is resisted but the other is neutral, the dual nature cancels out resistance
        if eff1 == .RESISTED && eff2 == .RESISTED {
            return 0.70, .RESISTED, "RESISTED"
        }

        return 1.00, .NEUTRAL, ""
    }

    // Primary 5-cycle advantages (1.85x)
    if attacker == .WATER && defender == .FIRE  do return 1.85, .SUPER_EFFECTIVE, "EXTINGUISHED!"
    if attacker == .FIRE  && defender == .EARTH do return 1.85, .SUPER_EFFECTIVE, "INCINERATED!"
    if attacker == .EARTH && defender == .LIGHT do return 1.85, .SUPER_EFFECTIVE, "GROUNDED!"
    if attacker == .LIGHT && defender == .CHAOS do return 1.85, .SUPER_EFFECTIVE, "PURIFIED!"
    if attacker == .CHAOS && defender == .WATER do return 1.85, .SUPER_EFFECTIVE, "CORRUPTED!"

    // Secondary affinity: Chaos harms Earth (1.50x)
    if attacker == .CHAOS && defender == .EARTH do return 1.50, .EFFECTIVE, "BLIGHTED!"

    // Resisted hits (Attacking an element that holds advantage over you)
    if attacker == .FIRE  && defender == .WATER do return 0.65, .RESISTED, "RESISTED"
    if attacker == .EARTH && defender == .FIRE  do return 0.65, .RESISTED, "RESISTED"
    if attacker == .LIGHT && defender == .EARTH do return 0.65, .RESISTED, "RESISTED"
    if attacker == .CHAOS && defender == .LIGHT do return 0.65, .RESISTED, "RESISTED"
    if attacker == .WATER && defender == .CHAOS do return 0.65, .RESISTED, "RESISTED"
    if attacker == .EARTH && defender == .CHAOS do return 0.70, .RESISTED, "RESISTED"

    return 1.00, .NEUTRAL, ""
}

// Combo multiplier formula: 1.0x at 1 hit, +0.30x per consecutive hit
combo_multiplier_for_count :: proc(combo: int) -> f32 {
    if combo <= 1 do return 1.0
    return 1.0 + f32(combo - 1) * 0.30
}
