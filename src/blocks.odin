package hellfire

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

blocks: [MAX_BLOCKS]Dungeon_Block
block_count: int

create_block :: proc(norm_x: f32, depth_z: f32, elem: Element, hp: int) -> Dungeon_Block {
    y := ARENA_TOP + depth_z * (ARENA_BOTTOM - ARENA_TOP - 160.0)
    half_w := arena_half_width_at_y(y) - 60.0
    x := ARENA_CENTER_X + (norm_x * 2.0 - 1.0) * half_w

    scale := 0.75 + 0.4 * depth_z
    base_size : f32 = 46.0 * scale

    return Dungeon_Block{
        pos        = {x, y},
        size       = {base_size, base_size},
        depth_z    = depth_z,
        max_hp     = hp,
        current_hp = hp,
        element    = elem,
        active     = true,
        hurt_timer = 0.0,
    }
}

spawn_blocks_for_wave :: proc(wave_num: int) {
    block_count = 0

    switch wave_num % 3 {
    case 1:
        // Wave 1: 2 ancient pillars flanking
        blocks[0] = create_block(0.30, 0.55, .EARTH, 90)
        blocks[1] = create_block(0.70, 0.55, .FIRE, 90)
        block_count = 2

    case 2:
        // Wave 2: 3 elemental barriers
        blocks[0] = create_block(0.20, 0.70, .WATER, 120)
        blocks[1] = create_block(0.50, 0.60, .CHAOS, 140)
        blocks[2] = create_block(0.80, 0.70, .LIGHT, 120)
        block_count = 3

    case 0:
        // Wave 3: 4 guardian pillars
        blocks[0] = create_block(0.18, 0.45, .CHAOS, 150)
        blocks[1] = create_block(0.38, 0.45, .EARTH, 150)
        blocks[2] = create_block(0.62, 0.45, .FIRE, 150)
        blocks[3] = create_block(0.82, 0.45, .LIGHT, 150)
        block_count = 4
    }
}

update_blocks :: proc(dt: f32) {
    for i in 0..<block_count {
        b := &blocks[i]
        if !b.active do continue
        if b.hurt_timer > 0.0 {
            b.hurt_timer -= dt
        }
    }
}

draw_blocks :: proc(time: f32) {
    for i in 0..<block_count {
        b := blocks[i]
        if !b.active do continue

        pos := b.pos
        hw := b.size.x * 0.5
        hh := b.size.y * 0.5
        rect := rl.Rectangle{pos.x - hw, pos.y - hh, b.size.x, b.size.y}

        elem_col1 := element_primary_color(b.element)
        elem_col2 := element_secondary_color(b.element)

        // Drop shadow
        shadow_rect := rl.Rectangle{pos.x - hw * 1.1, pos.y + hh * 0.7, b.size.x * 1.1, hh * 0.6}
        rl.DrawEllipse(i32(pos.x), i32(pos.y + hh * 0.85), hw * 1.2, hh * 0.4, rl.Color{0, 0, 0, 120})

        // Stone Block Body
        block_fill := rl.Color{36, 30, 44, 255}
        if b.hurt_timer > 0.0 {
            block_fill = rl.Color{240, 230, 230, 255} // Flash white
        }

        rl.DrawRectangleRec(rect, block_fill)
        rl.DrawRectangleLinesEx(rect, 2.5, elem_col1)

        // Inner beveled stone border
        inner_rect := rl.Rectangle{rect.x + 3, rect.y + 3, rect.width - 6, rect.height - 6}
        rl.DrawRectangleLinesEx(inner_rect, 1.5, COLOR_WALL_TRIM)

        // Glowing elemental rune icon in the center
        rune_pulse := math.sin(time * 3.5 + b.depth_z * 2.0) * 0.15 + 0.85
        rl.DrawCircleV(pos, hw * 0.38 * rune_pulse, elem_col2)
        rl.DrawCircleV(pos, hw * 0.20 * rune_pulse, rl.WHITE)

        // Cracks based on HP lost
        hp_pct := f32(b.current_hp) / f32(b.max_hp)
        if hp_pct < 0.7 {
            rl.DrawLineEx([2]f32{pos.x - hw * 0.5, pos.y - hh * 0.4}, [2]f32{pos.x - 2, pos.y}, 2, rl.BLACK)
        }
        if hp_pct < 0.4 {
            rl.DrawLineEx([2]f32{pos.x, pos.y}, [2]f32{pos.x + hw * 0.6, pos.y + hh * 0.5}, 2, rl.BLACK)
        }

        // Tiny HP bar
        bar_w := b.size.x
        bar_h : f32 = 5.0
        bar_x := pos.x - bar_w * 0.5
        bar_y := pos.y - hh - 8.0

        rl.DrawRectangle(i32(bar_x), i32(bar_y), i32(bar_w), i32(bar_h), rl.Color{15, 12, 20, 200})
        rl.DrawRectangle(i32(bar_x), i32(bar_y), i32(bar_w * hp_pct), i32(bar_h), elem_col1)
    }
}

