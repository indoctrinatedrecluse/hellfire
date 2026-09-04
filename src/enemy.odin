package hellfire

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"

MAX_ENEMIES :: 6

Wave_Definition :: struct {
    enemy_count: int,
    enemies:     [MAX_ENEMIES]Enemy,
}

create_enemy :: proc(name: string, elem: Element, norm_x: f32, depth_z: f32, base_hp: int, base_radius: f32) -> Enemy {
    // Calculate 2D position based on depth Z and normalized horizontal span
    y := ARENA_TOP + depth_z * (ARENA_BOTTOM - ARENA_TOP - 160.0)
    half_w := arena_half_width_at_y(y) - 60.0
    x := ARENA_CENTER_X + (norm_x * 2.0 - 1.0) * half_w

    scale := 0.7 + 0.45 * depth_z
    r := base_radius * scale

    return Enemy{
        pos         = {x, y},
        depth_z     = depth_z,
        radius      = r,
        max_hp      = base_hp,
        current_hp  = base_hp,
        element     = elem,
        name        = name,
        weak_offset = {0.0, -r * 0.28}, // Weak point placed higher (head/eye)
        weak_radius = r * 0.42,
        hurt_timer  = 0.0,
        alive       = true,
        pulse_phase = depth_z * 3.0,
    }
}

get_wave :: proc(wave_num: int) -> Wave_Definition {
    wave: Wave_Definition

    switch wave_num % 3 {
    case 1:
        // Wave 1: 2 Elemental Scouts
        wave.enemy_count = 2
        wave.enemies[0] = create_enemy("Magma Imp", .FIRE, 0.28, 0.35, 160, 48)
        wave.enemies[1] = create_enemy("Bramble Hound", .EARTH, 0.72, 0.35, 180, 48)

    case 2:
        // Wave 2: 3 Vanguard Beasts
        wave.enemy_count = 3
        wave.enemies[0] = create_enemy("Tide Serpent", .WATER, 0.2, 0.50, 220, 44)
        wave.enemies[1] = create_enemy("Abyssal Stalker", .CHAOS, 0.5, 0.30, 300, 52)
        wave.enemies[2] = create_enemy("Infernal Fiend", .FIRE, 0.8, 0.50, 220, 44)

    case 0:
        // Wave 3: Dungeon Boss
        wave.enemy_count = 3
        wave.enemies[0] = create_enemy("Sunstone Sentinel", .LIGHT, 0.22, 0.60, 250, 45)
        wave.enemies[1] = create_enemy("MALPHAS, HELLFIRE LORD", .CHAOS, 0.5, 0.25, 800, 75)
        wave.enemies[2] = create_enemy("Glacial Wyrm", .WATER, 0.78, 0.60, 250, 45)
    }

    return wave
}

update_enemies :: proc(enemies: ^[MAX_ENEMIES]Enemy, count: int, dt: f32) {
    for i in 0..<count {
        e := &enemies[i]
        if !e.alive do continue

        e.pulse_phase += dt * 2.5
        if e.hurt_timer > 0.0 {
            e.hurt_timer -= dt
        }
    }
}

draw_enemy :: proc(e: Enemy, time: f32) {
    if !e.alive do return

    pulse := math.sin(e.pulse_phase) * 0.05 + 1.0
    r := e.radius * pulse
    pos := e.pos

    elem_col1 := element_primary_color(e.element)
    elem_col2 := element_secondary_color(e.element)

    // Shadow on the dungeon floor
    shadow_w := r * 1.3
    shadow_h := r * 0.45
    rl.DrawEllipse(i32(pos.x), i32(pos.y + r * 0.85), shadow_w, shadow_h, rl.Color{0, 0, 0, 110})

    // Hurt Flash White or Base Demon Color
    body_fill := rl.Color{26, 20, 32, 255}
    if e.hurt_timer > 0.0 {
        body_fill = rl.Color{240, 230, 230, 255}
    }

    // Outer Aura / Armor Ring
    rl.DrawCircleV(pos, r + 4, elem_col1)
    rl.DrawCircleV(pos, r, body_fill)
    rl.DrawCircleLinesV(pos, r, elem_col2)

    // Demon Horns / Silhouette Accents
    horn_offset := r * 0.85
    horn_size   := r * 0.35
    p_horn_l1   := [2]f32{pos.x - horn_offset * 0.7, pos.y - horn_offset * 0.5}
    p_horn_l2   := [2]f32{pos.x - horn_offset * 1.1, pos.y - horn_offset * 1.2}
    p_horn_l3   := [2]f32{pos.x - horn_offset * 0.3, pos.y - horn_offset * 0.9}
    rl.DrawTriangle(p_horn_l1, p_horn_l2, p_horn_l3, elem_col1)

    p_horn_r1   := [2]f32{pos.x + horn_offset * 0.7, pos.y - horn_offset * 0.5}
    p_horn_r2   := [2]f32{pos.x + horn_offset * 0.3, pos.y - horn_offset * 0.9}
    p_horn_r3   := [2]f32{pos.x + horn_offset * 1.1, pos.y - horn_offset * 1.2}
    rl.DrawTriangle(p_horn_r1, p_horn_r2, p_horn_r3, elem_col1)

    // Inner Core / Weak Point (Glowing Head / Eye)
    weak_center := pos + e.weak_offset
    weak_pulse  := math.sin(time * 5.0 + e.depth_z) * 0.15 + 0.85
    rl.DrawCircleV(weak_center, e.weak_radius * weak_pulse, elem_col2)
    rl.DrawCircleV(weak_center, e.weak_radius * 0.6 * weak_pulse, rl.WHITE)
    rl.DrawCircleLinesV(weak_center, e.weak_radius, rl.GOLD)

    // Elemental Icon / Sigil on chest
    sigil_pos := pos + [2]f32{0.0, r * 0.35}
    rl.DrawCircleV(sigil_pos, r * 0.22, elem_col1)
    rl.DrawCircleLinesV(sigil_pos, r * 0.22, rl.WHITE)

    // --- HP Bar ---
    bar_w : f32 = math.max(r * 2.2, 90.0)
    bar_h : f32 = 10.0
    bar_x := pos.x - bar_w / 2.0
    bar_y := pos.y - r - 28.0

    // HP background
    rl.DrawRectangle(i32(bar_x), i32(bar_y), i32(bar_w), i32(bar_h), rl.Color{15, 12, 18, 220})
    rl.DrawRectangleLines(i32(bar_x), i32(bar_y), i32(bar_w), i32(bar_h), COLOR_WALL_TRIM)

    // HP fill
    hp_pct := math.clamp(f32(e.current_hp) / f32(e.max_hp), 0.0, 1.0)
    fill_color := elem_col1
    if hp_pct < 0.3 do fill_color = rl.RED
    rl.DrawRectangle(i32(bar_x + 1), i32(bar_y + 1), i32((bar_w - 2) * hp_pct), i32(bar_h - 2), fill_color)

    // Name & Element Label
    name_cstr := strings.clone_to_cstring(e.name)
    defer delete(name_cstr)
    font_size : i32 = 15
    name_w := rl.MeasureText(name_cstr, font_size)
    rl.DrawText(name_cstr, i32(pos.x) - name_w / 2, i32(bar_y - 18), font_size, rl.RAYWHITE)
}

