package hellfire

import rl "vendor:raylib"

Element :: enum {
    FIRE,
    WATER,
    EARTH,
    CHAOS,
    LIGHT,
}

Game_State :: enum {
    TITLE,
    BATTLE_AIMING,
    BATTLE_FLYING,
    WAVE_CLEARED,
    GAME_OVER,
}

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

element_name :: proc(elem: Element) -> string {
    switch elem {
    case .FIRE:  return "Fire"
    case .WATER: return "Water"
    case .EARTH: return "Earth"
    case .CHAOS: return "Chaos"
    case .LIGHT: return "Light"
    }
    return "Unknown"
}

element_primary_color :: proc(elem: Element) -> rl.Color {
    switch elem {
    case .FIRE:  return COLOR_FIRE_PRIMARY
    case .WATER: return COLOR_WATER_PRIMARY
    case .EARTH: return COLOR_EARTH_PRIMARY
    case .CHAOS: return COLOR_CHAOS_PRIMARY
    case .LIGHT: return COLOR_LIGHT_PRIMARY
    }
    return rl.WHITE
}

element_secondary_color :: proc(elem: Element) -> rl.Color {
    switch elem {
    case .FIRE:  return COLOR_FIRE_SECONDARY
    case .WATER: return COLOR_WATER_SECONDARY
    case .EARTH: return COLOR_EARTH_SECONDARY
    case .CHAOS: return COLOR_CHAOS_SECONDARY
    case .LIGHT: return COLOR_LIGHT_SECONDARY
    }
    return rl.WHITE
}

Element_Effectiveness :: enum {
    SUPER_EFFECTIVE, // 1.85x
    EFFECTIVE,       // 1.45x
    NEUTRAL,         // 1.00x
    RESISTED,        // 0.65x
}

// Full 5-element cycle & affinities:
// Water > Fire > Earth > Light > Chaos > Water (1.85x)
// Chaos > Earth (1.50x)
// Reverse interactions are resisted (0.65x)
element_interaction :: proc(attacker, defender: Element) -> (mult: f32, effect: Element_Effectiveness, label: string) {
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
