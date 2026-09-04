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

MAX_TRAIL_POINTS :: 24
MAX_PARTICLES    :: 256
MAX_DAMAGE_TEXTS :: 32

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

Particle :: struct {
    pos:      [2]f32,
    vel:      [2]f32,
    color:    rl.Color,
    size:     f32,
    life:     f32,
    max_life: f32,
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

// Elemental advantage multiplier: 1.5x for advantage, 0.75x for disadvantage, 1.0x neutral
element_multiplier :: proc(attacker, defender: Element) -> f32 {
    if attacker == .FIRE && defender == .EARTH  do return 1.5
    if attacker == .EARTH && defender == .WATER do return 1.5
    if attacker == .WATER && defender == .FIRE  do return 1.5

    if attacker == .EARTH && defender == .FIRE  do return 0.75
    if attacker == .WATER && defender == .EARTH do return 0.75
    if attacker == .FIRE && defender == .WATER  do return 0.75

    if (attacker == .CHAOS && defender == .LIGHT) || (attacker == .LIGHT && defender == .CHAOS) {
        return 1.5 // Opposing dark & holy
    }

    return 1.0
}

