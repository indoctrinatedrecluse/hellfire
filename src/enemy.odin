package hellfire

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
        weak_offset = {0.0, -r * 0.28},
        weak_radius = r * 0.38,
        hurt_timer  = 0.0,
        alive       = true,
        pulse_phase = depth_z * 3.0,
    }
}

get_wave :: proc(wave_num: int) -> Wave_Definition {
    wave: Wave_Definition

    switch wave_num % 3 {
    case 1:
        // Wave 1: 2 Elemental Scout Cards
        wave.enemy_count = 2
        wave.enemies[0] = create_enemy("Magma Drake", .FIRE, 0.28, 0.35, 180, 50)
        wave.enemies[1] = create_enemy("Bramble Titan", .EARTH, 0.72, 0.35, 200, 50)

    case 2:
        // Wave 2: 3 Vanguard Beast Cards
        wave.enemy_count = 3
        wave.enemies[0] = create_enemy("Tide Serpent", .WATER, 0.2, 0.50, 240, 46)
        wave.enemies[1] = create_enemy("Abyssal Demon", .CHAOS, 0.5, 0.30, 320, 54)
        wave.enemies[2] = create_enemy("Sun Valkyrie", .LIGHT, 0.8, 0.50, 240, 46)

    case 0:
        // Wave 3: Dungeon Boss Card
        wave.enemy_count = 3
        wave.enemies[0] = create_enemy("Seraph Guard", .LIGHT, 0.22, 0.60, 260, 48)
        wave.enemies[1] = create_enemy("MALPHAS, HELLFIRE LORD", .CHAOS, 0.5, 0.25, 850, 78)
        wave.enemies[2] = create_enemy("Glacial Wyrm", .WATER, 0.78, 0.60, 260, 48)
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

    pos := e.pos
    r := e.radius

    // Card Dimensions scaled with 2.5D depth
    card_w := r * 1.85
    card_h := r * 2.55
    card_x := pos.x - card_w * 0.5
    card_y := pos.y - card_h * 0.5

    // Card shadow on the dungeon floor
    shadow_w := card_w * 1.15
    shadow_h := card_w * 0.35
    rl.DrawEllipse(i32(pos.x), i32(card_y + card_h + 4.0), shadow_w * 0.5, shadow_h * 0.5, rl.Color{0, 0, 0, 140})

    // Rarity determination
    rarity := 3
    if e.max_hp > 500 {
        rarity = 5
    } else if e.max_hp > 220 {
        rarity = 4
    }

    // Render as authentic Hellfire Creature Card
    card_rect := rl.Rectangle{card_x, card_y, card_w, card_h}
    is_boss := (e.max_hp > 500)
    is_hurt := (e.hurt_timer > 0.0)

    draw_card(
        rect        = card_rect,
        elem        = e.element,
        name        = e.name,
        rarity      = rarity,
        hp_cur      = e.current_hp,
        hp_max      = e.max_hp,
        selected    = is_boss,
        hurt_flash  = is_hurt,
        is_monster  = true,
        time        = time,
    )

    // Inner Glowing Weak Point Reticle on the Card
    weak_center := pos + e.weak_offset
    weak_pulse  := math.sin(time * 5.0 + e.depth_z) * 0.15 + 0.85
    elem_col2   := element_secondary_color(e.element)

    rl.DrawCircleV(weak_center, e.weak_radius * weak_pulse, elem_col2)
    rl.DrawCircleV(weak_center, e.weak_radius * 0.55 * weak_pulse, rl.WHITE)
    rl.DrawCircleLinesV(weak_center, e.weak_radius, rl.GOLD)

    // Crosshair ticks
    ch_len := e.weak_radius * 1.35
    rl.DrawLineV([2]f32{weak_center.x - ch_len, weak_center.y}, [2]f32{weak_center.x + ch_len, weak_center.y}, rl.Color{255, 215, 80, 180})
    rl.DrawLineV([2]f32{weak_center.x, weak_center.y - ch_len}, [2]f32{weak_center.x, weak_center.y + ch_len}, rl.Color{255, 215, 80, 180})
}
