package hellfire

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

Arena_Wall :: struct {
    p1:     [2]f32,
    p2:     [2]f32,
    normal: [2]f32, // Unit normal pointing toward the interior of the arena
}

arena_get_walls :: proc() -> (left: Arena_Wall, right: Arena_Wall, top: Arena_Wall) {
    p_top_left     := [2]f32{ARENA_CENTER_X - ARENA_TOP_HALF_W, ARENA_TOP}
    p_top_right    := [2]f32{ARENA_CENTER_X + ARENA_TOP_HALF_W, ARENA_TOP}
    p_bottom_left  := [2]f32{ARENA_CENTER_X - ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}
    p_bottom_right := [2]f32{ARENA_CENTER_X + ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}

    // Left wall from top to bottom
    left_dir := p_bottom_left - p_top_left
    // Normal pointing inward (right)
    left_n := linalg.normalize0([2]f32{left_dir.y, -left_dir.x})
    left = Arena_Wall{p1 = p_top_left, p2 = p_bottom_left, normal = left_n}

    // Right wall from top to bottom
    right_dir := p_bottom_right - p_top_right
    // Normal pointing inward (left)
    right_n := linalg.normalize0([2]f32{-right_dir.y, right_dir.x})
    right = Arena_Wall{p1 = p_top_right, p2 = p_bottom_right, normal = right_n}

    // Top wall from left to right
    top = Arena_Wall{p1 = p_top_left, p2 = p_top_right, normal = [2]f32{0.0, 1.0}}

    return
}

arena_half_width_at_y :: proc(y: f32) -> f32 {
    t := math.clamp((y - ARENA_TOP) / (ARENA_BOTTOM - ARENA_TOP), 0.0, 1.0)
    return ARENA_TOP_HALF_W + t * (ARENA_BOTTOM_HALF_W - ARENA_TOP_HALF_W)
}

arena_depth_z_at_y :: proc(y: f32) -> f32 {
    return math.clamp((y - ARENA_TOP) / (ARENA_BOTTOM - ARENA_TOP), 0.0, 1.0)
}

draw_arena :: proc(time: f32) {
    p_top_left     := [2]f32{ARENA_CENTER_X - ARENA_TOP_HALF_W, ARENA_TOP}
    p_top_right    := [2]f32{ARENA_CENTER_X + ARENA_TOP_HALF_W, ARENA_TOP}
    p_bottom_left  := [2]f32{ARENA_CENTER_X - ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}
    p_bottom_right := [2]f32{ARENA_CENTER_X + ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}

    // --- Void Background ---
    rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, COLOR_BG_VOID)

    // --- Dungeon Floor (Trapezoid) ---
    // In Raylib, we can draw trapezoid using two triangles
    rl.DrawTriangle(p_top_left, p_bottom_left, p_top_right, COLOR_DUNGEON_FLOOR)
    rl.DrawTriangle(p_top_right, p_bottom_left, p_bottom_right, COLOR_DUNGEON_FLOOR)

    // --- Floor Perspective Lines ---
    vanishing_point := [2]f32{ARENA_CENTER_X, 30.0}
    floor_line_color := rl.Color{42, 35, 52, 120}

    // Receding perspective grid lines
    line_count :: 7
    for i in 0..<line_count {
        t := f32(i) / f32(line_count - 1)
        bottom_x := (ARENA_CENTER_X - ARENA_BOTTOM_HALF_W) + t * (ARENA_BOTTOM_HALF_W * 2.0)
        dir := linalg.normalize0([2]f32{bottom_x, ARENA_BOTTOM} - vanishing_point)

        // Find intersection with top wall
        start_y := ARENA_TOP
        start_t := (start_y - vanishing_point.y) / dir.y
        start_pos := vanishing_point + dir * start_t

        end_pos := [2]f32{bottom_x, ARENA_BOTTOM}
        rl.DrawLineV(start_pos, end_pos, floor_line_color)
    }

    // Horizontal flagstone lines (perspective spaced)
    flagstone_rows :: 10
    for i in 1..=flagstone_rows {
        norm := f32(i) / f32(flagstone_rows)
        // Non-linear depth distribution for perspective feel
        t := math.pow(norm, 1.7)
        y := ARENA_TOP + t * (ARENA_BOTTOM - ARENA_TOP)
        hw := arena_half_width_at_y(y)
        p1 := [2]f32{ARENA_CENTER_X - hw, y}
        p2 := [2]f32{ARENA_CENTER_X + hw, y}
        rl.DrawLineEx(p1, p2, 1.5, floor_line_color)
    }

    // --- Back Wall / Demon Archway ---
    arch_color := rl.Color{32, 26, 40, 255}
    rl.DrawRectangle(i32(p_top_left.x), 50, i32(ARENA_TOP_HALF_W * 2.0), i32(ARENA_TOP - 50), arch_color)
    rl.DrawRectangleLinesEx(rl.Rectangle{p_top_left.x, 50, ARENA_TOP_HALF_W * 2.0, ARENA_TOP - 50}, 3, COLOR_WALL_BORDER)

    // Archway opening
    gate_w : f32 = 180.0
    gate_h : f32 = 110.0
    gate_rect := rl.Rectangle{ARENA_CENTER_X - gate_w / 2.0, ARENA_TOP - gate_h, gate_w, gate_h}
    rl.DrawRectangleRec(gate_rect, rl.Color{12, 10, 16, 255})
    rl.DrawRectangleLinesEx(gate_rect, 2, COLOR_WALL_TRIM)

    // Glowing gate eye / portal rune
    portal_glow := f32(math.sin(time * 2.5) * 0.2 + 0.8)
    portal_color := rl.Color{255, 80, 40, u8(portal_glow * 140)}
    rl.DrawCircleV([2]f32{ARENA_CENTER_X, ARENA_TOP - gate_h * 0.5}, 22 * portal_glow, portal_color)
    rl.DrawCircleLinesV([2]f32{ARENA_CENTER_X, ARENA_TOP - gate_h * 0.5}, 26, rl.Color{255, 180, 50, 200})

    // --- Dungeon Side Walls & Pillars ---
    wall_thickness : f32 = 18.0
    rl.DrawLineEx(p_top_left, p_bottom_left, wall_thickness, COLOR_DUNGEON_WALL)
    rl.DrawLineEx(p_top_left, p_bottom_left, 3.0, COLOR_WALL_TRIM)

    rl.DrawLineEx(p_top_right, p_bottom_right, wall_thickness, COLOR_DUNGEON_WALL)
    rl.DrawLineEx(p_top_right, p_bottom_right, 3.0, COLOR_WALL_TRIM)

    // Top wall border
    rl.DrawLineEx(p_top_left, p_top_right, 6.0, COLOR_WALL_TRIM)

    // Wall Pillars / Brackets
    draw_pillar([2]f32{p_top_left.x, ARENA_TOP + 120}, 16)
    draw_pillar([2]f32{p_top_right.x, ARENA_TOP + 120}, 16)
    draw_pillar([2]f32{p_top_left.x - 30, ARENA_TOP + 400}, 20)
    draw_pillar([2]f32{p_top_right.x + 30, ARENA_TOP + 400}, 20)
    draw_pillar([2]f32{p_bottom_left.x, ARENA_BOTTOM - 80}, 24)
    draw_pillar([2]f32{p_bottom_right.x, ARENA_BOTTOM - 80}, 24)

    // --- Wall Sconces & Animated Torches ---
    draw_torch([2]f32{p_top_left.x + 14, ARENA_TOP + 80}, time)
    draw_torch([2]f32{p_top_right.x - 14, ARENA_TOP + 80}, time + 1.2)
    draw_torch([2]f32{p_top_left.x - 10, ARENA_TOP + 320}, time + 0.5)
    draw_torch([2]f32{p_top_right.x + 10, ARENA_TOP + 320}, time + 1.8)

    // --- Summoning Circle / Launch Pad ---
    draw_summoning_pad(LAUNCH_PAD_POS, time)
}

draw_pillar :: proc(pos: [2]f32, width: f32) {
    rect := rl.Rectangle{pos.x - width / 2.0, pos.y - 15, width, 30}
    rl.DrawRectangleRec(rect, COLOR_DUNGEON_WALL)
    rl.DrawRectangleLinesEx(rect, 2, COLOR_WALL_BORDER)
}

draw_torch :: proc(pos: [2]f32, time: f32) {
    // Torch bracket
    rl.DrawRectangle(i32(pos.x - 4), i32(pos.y), 8, 16, rl.DARKGRAY)
    rl.DrawRectangleLines(i32(pos.x - 4), i32(pos.y), 8, 16, rl.BLACK)

    // Flame flicker
    flicker := math.sin(time * 9.0) * 2.0 + math.cos(time * 14.0) * 1.5
    flicker_r := 10.0 + math.sin(time * 7.0) * 2.0

    // Ambient light halo
    halo_color := rl.Color{255, 120, 20, 25}
    rl.DrawCircleV([2]f32{pos.x, pos.y - 4}, flicker_r * 4.5, halo_color)

    // Fire core
    rl.DrawCircleV([2]f32{pos.x + flicker * 0.4, pos.y - 6 + flicker * 0.3}, flicker_r, rl.Color{255, 80, 20, 220})
    rl.DrawCircleV([2]f32{pos.x + flicker * 0.2, pos.y - 8}, flicker_r * 0.6, rl.Color{255, 200, 50, 240})
    rl.DrawCircleV([2]f32{pos.x, pos.y - 9}, flicker_r * 0.25, rl.WHITE)
}

draw_summoning_pad :: proc(pos: [2]f32, time: f32) {
    // Outer rune circle
    pulse := math.sin(time * 2.0) * 0.1 + 0.9
    radius := LAUNCH_PAD_RADIUS

    rl.DrawCircleLinesV(pos, radius * 1.15, rl.Color{120, 95, 55, 160})
    rl.DrawCircleLinesV(pos, radius, COLOR_WALL_TRIM)
    rl.DrawCircleV(pos, radius - 2, rl.Color{28, 22, 38, 200})

    // Glowing archaic runes on the circle
    runes_count :: 8
    for i in 0..<runes_count {
        angle := (f32(i) / f32(runes_count)) * math.TAU + (time * 0.4)
        rx := pos.x + math.cos(angle) * (radius * 0.72)
        ry := pos.y + math.sin(angle) * (radius * 0.72)
        rune_alpha := u8((math.sin(time * 3.0 + f32(i)) * 0.3 + 0.7) * 220)
        rl.DrawCircleV([2]f32{rx, ry}, 3.0, rl.Color{255, 185, 60, rune_alpha})
    }

    // Inner sigil diamond
    inner_r := radius * 0.42 * pulse
    p1 := [2]f32{pos.x, pos.y - inner_r}
    p2 := [2]f32{pos.x + inner_r, pos.y}
    p3 := [2]f32{pos.x, pos.y + inner_r}
    p4 := [2]f32{pos.x - inner_r, pos.y}
    rl.DrawLineV(p1, p2, COLOR_RUNE_GLOW)
    rl.DrawLineV(p2, p3, COLOR_RUNE_GLOW)
    rl.DrawLineV(p3, p4, COLOR_RUNE_GLOW)
    rl.DrawLineV(p4, p1, COLOR_RUNE_GLOW)
}

