package hellfire

import "core:math"
import "core:math/linalg"
import "core:math/rand"
import rl "vendor:raylib"

Arena_Wall :: struct {
    p1:     [2]f32,
    p2:     [2]f32,
    normal: [2]f32, // Unit normal pointing toward the interior of the arena
}

current_theme: Environment_Theme

arena_get_walls :: proc() -> (left: Arena_Wall, right: Arena_Wall, top: Arena_Wall) {
    p_top_left     := [2]f32{ARENA_CENTER_X - ARENA_TOP_HALF_W, ARENA_TOP}
    p_top_right    := [2]f32{ARENA_CENTER_X + ARENA_TOP_HALF_W, ARENA_TOP}
    p_bottom_left  := [2]f32{ARENA_CENTER_X - ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}
    p_bottom_right := [2]f32{ARENA_CENTER_X + ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}

    // Left wall from top to bottom
    left_dir := p_bottom_left - p_top_left
    left_n := linalg.normalize0([2]f32{left_dir.y, -left_dir.x})
    left = Arena_Wall{p1 = p_top_left, p2 = p_bottom_left, normal = left_n}

    // Right wall from top to bottom
    right_dir := p_bottom_right - p_top_right
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

get_environment_theme :: proc(env_type: Environment_Type) -> Environment_Theme {
    switch env_type {
    case .ABYSSAL_CRYPT:
        return Environment_Theme{
            type           = .ABYSSAL_CRYPT,
            name           = "Abyssal Crypt",
            title_name     = "ABYSSAL CRYPT",
            bg_void        = rl.Color{10, 8, 15, 255},
            floor_color    = rl.Color{24, 20, 32, 255},
            floor_grid     = rl.Color{45, 36, 56, 120},
            wall_color     = rl.Color{42, 34, 52, 255},
            wall_border    = rl.Color{75, 60, 92, 255},
            wall_trim      = rl.Color{135, 110, 75, 255},
            arch_color     = rl.Color{32, 26, 42, 255},
            gate_glow      = rl.Color{185, 60, 240, 200},
            gate_ring      = rl.Color{220, 130, 255, 220},
            torch_core     = rl.Color{245, 220, 255, 255},
            torch_outer    = rl.Color{170, 45, 235, 230},
            torch_halo     = rl.Color{130, 30, 200, 30},
            ambient_color1 = rl.Color{190, 75, 255, 180},
            ambient_color2 = rl.Color{110, 45, 210, 140},
            particle_glyph = "Wisp",
        }

    case .MAGMA_CAVERNS:
        return Environment_Theme{
            type           = .MAGMA_CAVERNS,
            name           = "Magma Caverns",
            title_name     = "MAGMA CAVERNS",
            bg_void        = rl.Color{14, 6, 6, 255},
            floor_color    = rl.Color{36, 16, 16, 255},
            floor_grid     = rl.Color{85, 30, 20, 140},
            wall_color     = rl.Color{55, 24, 20, 255},
            wall_border    = rl.Color{110, 48, 35, 255},
            wall_trim      = rl.Color{210, 120, 45, 255},
            arch_color     = rl.Color{45, 18, 18, 255},
            gate_glow      = rl.Color{255, 75, 20, 220},
            gate_ring      = rl.Color{255, 195, 45, 230},
            torch_core     = rl.Color{255, 245, 200, 255},
            torch_outer    = rl.Color{255, 80, 25, 230},
            torch_halo     = rl.Color{255, 110, 20, 35},
            ambient_color1 = rl.Color{255, 120, 30, 200},
            ambient_color2 = rl.Color{255, 200, 50, 160},
            particle_glyph = "Ember",
        }

    case .SUNKEN_TEMPLE:
        return Environment_Theme{
            type           = .SUNKEN_TEMPLE,
            name           = "Sunken Temple",
            title_name     = "SUNKEN TEMPLE",
            bg_void        = rl.Color{6, 12, 18, 255},
            floor_color    = rl.Color{14, 28, 40, 255},
            floor_grid     = rl.Color{28, 62, 85, 130},
            wall_color     = rl.Color{22, 45, 62, 255},
            wall_border    = rl.Color{45, 90, 125, 255},
            wall_trim      = rl.Color{80, 175, 210, 255},
            arch_color     = rl.Color{16, 36, 50, 255},
            gate_glow      = rl.Color{35, 150, 255, 210},
            gate_ring      = rl.Color{90, 225, 255, 230},
            torch_core     = rl.Color{220, 250, 255, 255},
            torch_outer    = rl.Color{30, 140, 255, 220},
            torch_halo     = rl.Color{20, 120, 240, 30},
            ambient_color1 = rl.Color{70, 190, 255, 180},
            ambient_color2 = rl.Color{40, 140, 220, 140},
            particle_glyph = "Bubble",
        }

    case .VERDANT_CATACOMBS:
        return Environment_Theme{
            type           = .VERDANT_CATACOMBS,
            name           = "Verdant Catacombs",
            title_name     = "VERDANT CATACOMBS",
            bg_void        = rl.Color{6, 14, 10, 255},
            floor_color    = rl.Color{16, 32, 22, 255},
            floor_grid     = rl.Color{32, 70, 45, 130},
            wall_color     = rl.Color{26, 50, 35, 255},
            wall_border    = rl.Color{50, 105, 70, 255},
            wall_trim      = rl.Color{125, 180, 75, 255},
            arch_color     = rl.Color{18, 40, 26, 255},
            gate_glow      = rl.Color{45, 215, 80, 210},
            gate_ring      = rl.Color{145, 250, 110, 230},
            torch_core     = rl.Color{230, 255, 210, 255},
            torch_outer    = rl.Color{45, 195, 75, 220},
            torch_halo     = rl.Color{35, 180, 60, 30},
            ambient_color1 = rl.Color{110, 240, 95, 180},
            ambient_color2 = rl.Color{60, 180, 70, 140},
            particle_glyph = "Spore",
        }

    case .ASTRAL_SPIRE:
        return Environment_Theme{
            type           = .ASTRAL_SPIRE,
            name           = "Astral Spire",
            title_name     = "ASTRAL SPIRE",
            bg_void        = rl.Color{10, 10, 18, 255},
            floor_color    = rl.Color{26, 24, 40, 255},
            floor_grid     = rl.Color{60, 56, 95, 130},
            wall_color     = rl.Color{44, 40, 68, 255},
            wall_border    = rl.Color{85, 78, 130, 255},
            wall_trim      = rl.Color{230, 195, 95, 255},
            arch_color     = rl.Color{34, 30, 52, 255},
            gate_glow      = rl.Color{255, 220, 100, 220},
            gate_ring      = rl.Color{255, 255, 210, 240},
            torch_core     = rl.Color{255, 255, 240, 255},
            torch_outer    = rl.Color{240, 190, 70, 230},
            torch_halo     = rl.Color{235, 180, 50, 35},
            ambient_color1 = rl.Color{255, 230, 130, 190},
            ambient_color2 = rl.Color{200, 180, 255, 150},
            particle_glyph = "Stardust",
        }
    }

    return get_environment_theme(.ABYSSAL_CRYPT)
}

set_random_environment :: proc() {
    // Pick from all 5 environments randomly, different from current
    next_idx := int(rand.uint32() % 5)
    if Environment_Type(next_idx) == current_theme.type {
        next_idx = (next_idx + 1) % 5
    }
    current_theme = get_environment_theme(Environment_Type(next_idx))
    init_ambient_particles(current_theme.ambient_color1, current_theme.ambient_color2)
}

draw_arena :: proc(time: f32) {
    p_top_left     := [2]f32{ARENA_CENTER_X - ARENA_TOP_HALF_W, ARENA_TOP}
    p_top_right    := [2]f32{ARENA_CENTER_X + ARENA_TOP_HALF_W, ARENA_TOP}
    p_bottom_left  := [2]f32{ARENA_CENTER_X - ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}
    p_bottom_right := [2]f32{ARENA_CENTER_X + ARENA_BOTTOM_HALF_W, ARENA_BOTTOM}

    // --- Void Background ---
    rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, current_theme.bg_void)

    // --- Dungeon Floor (Trapezoid) ---
    rl.DrawTriangle(p_top_left, p_bottom_left, p_top_right, current_theme.floor_color)
    rl.DrawTriangle(p_top_right, p_bottom_left, p_bottom_right, current_theme.floor_color)

    // --- Floor Perspective Lines ---
    vanishing_point := [2]f32{ARENA_CENTER_X, 30.0}

    line_count :: 7
    for i in 0..<line_count {
        t := f32(i) / f32(line_count - 1)
        bottom_x := (ARENA_CENTER_X - ARENA_BOTTOM_HALF_W) + t * (ARENA_BOTTOM_HALF_W * 2.0)
        dir := linalg.normalize0([2]f32{bottom_x, ARENA_BOTTOM} - vanishing_point)

        start_y := ARENA_TOP
        start_t := (start_y - vanishing_point.y) / dir.y
        start_pos := vanishing_point + dir * start_t

        end_pos := [2]f32{bottom_x, ARENA_BOTTOM}
        rl.DrawLineV(start_pos, end_pos, current_theme.floor_grid)
    }

    // Horizontal flagstone lines (perspective spaced)
    flagstone_rows :: 10
    for i in 1..=flagstone_rows {
        norm := f32(i) / f32(flagstone_rows)
        t := math.pow(norm, 1.7)
        y := ARENA_TOP + t * (ARENA_BOTTOM - ARENA_TOP)
        hw := arena_half_width_at_y(y)
        p1 := [2]f32{ARENA_CENTER_X - hw, y}
        p2 := [2]f32{ARENA_CENTER_X + hw, y}
        rl.DrawLineEx(p1, p2, 1.5, current_theme.floor_grid)
    }

    // --- Ambient Environment Particles (Atmospheric depth) ---
    draw_ambient_particles()

    // --- Back Wall / Demon Archway ---
    rl.DrawRectangle(i32(p_top_left.x), 50, i32(ARENA_TOP_HALF_W * 2.0), i32(ARENA_TOP - 50), current_theme.arch_color)
    rl.DrawRectangleLinesEx(rl.Rectangle{p_top_left.x, 50, ARENA_TOP_HALF_W * 2.0, ARENA_TOP - 50}, 3, current_theme.wall_border)

    // Archway opening
    gate_w : f32 = 180.0
    gate_h : f32 = 110.0
    gate_rect := rl.Rectangle{ARENA_CENTER_X - gate_w / 2.0, ARENA_TOP - gate_h, gate_w, gate_h}
    rl.DrawRectangleRec(gate_rect, rl.Color{8, 6, 12, 255})
    rl.DrawRectangleLinesEx(gate_rect, 2, current_theme.wall_trim)

    // Glowing gate eye / portal rune
    portal_glow := f32(math.sin(time * 2.5) * 0.2 + 0.8)
    portal_color := current_theme.gate_glow
    portal_color.a = u8(portal_glow * 160)
    rl.DrawCircleV([2]f32{ARENA_CENTER_X, ARENA_TOP - gate_h * 0.5}, 24 * portal_glow, portal_color)
    rl.DrawCircleLinesV([2]f32{ARENA_CENTER_X, ARENA_TOP - gate_h * 0.5}, 28, current_theme.gate_ring)

    // --- Dungeon Side Walls & Pillars ---
    wall_thickness : f32 = 18.0
    rl.DrawLineEx(p_top_left, p_bottom_left, wall_thickness, current_theme.wall_color)
    rl.DrawLineEx(p_top_left, p_bottom_left, 3.0, current_theme.wall_trim)

    rl.DrawLineEx(p_top_right, p_bottom_right, wall_thickness, current_theme.wall_color)
    rl.DrawLineEx(p_top_right, p_bottom_right, 3.0, current_theme.wall_trim)

    rl.DrawLineEx(p_top_left, p_top_right, 6.0, current_theme.wall_trim)

    // Wall Pillars / Brackets
    draw_pillar([2]f32{p_top_left.x, ARENA_TOP + 120}, 16)
    draw_pillar([2]f32{p_top_right.x, ARENA_TOP + 120}, 16)
    draw_pillar([2]f32{p_top_left.x - 30, ARENA_TOP + 400}, 20)
    draw_pillar([2]f32{p_top_right.x + 30, ARENA_TOP + 400}, 20)
    draw_pillar([2]f32{p_bottom_left.x, ARENA_BOTTOM - 80}, 24)
    draw_pillar([2]f32{p_bottom_right.x, ARENA_BOTTOM - 80}, 24)

    // --- Wall Sconces & Animated Themed Torches ---
    draw_torch([2]f32{p_top_left.x + 14, ARENA_TOP + 80}, time)
    draw_torch([2]f32{p_top_right.x - 14, ARENA_TOP + 80}, time + 1.2)
    draw_torch([2]f32{p_top_left.x - 10, ARENA_TOP + 320}, time + 0.5)
    draw_torch([2]f32{p_top_right.x + 10, ARENA_TOP + 320}, time + 1.8)

    // --- Summoning Circle / Launch Pad ---
    draw_summoning_pad(LAUNCH_PAD_POS, time)
}

draw_pillar :: proc(pos: [2]f32, width: f32) {
    rect := rl.Rectangle{pos.x - width / 2.0, pos.y - 15, width, 30}
    rl.DrawRectangleRec(rect, current_theme.wall_color)
    rl.DrawRectangleLinesEx(rect, 2, current_theme.wall_border)
}

draw_torch :: proc(pos: [2]f32, time: f32) {
    rl.DrawRectangle(i32(pos.x - 4), i32(pos.y), 8, 16, rl.DARKGRAY)
    rl.DrawRectangleLines(i32(pos.x - 4), i32(pos.y), 8, 16, rl.BLACK)

    flicker := math.sin(time * 9.0) * 2.0 + math.cos(time * 14.0) * 1.5
    flicker_r := 10.0 + math.sin(time * 7.0) * 2.0

    // Ambient light halo using theme color
    rl.DrawCircleV([2]f32{pos.x, pos.y - 4}, flicker_r * 4.5, current_theme.torch_halo)

    // Themed flame core & outer
    rl.DrawCircleV([2]f32{pos.x + flicker * 0.4, pos.y - 6 + flicker * 0.3}, flicker_r, current_theme.torch_outer)
    rl.DrawCircleV([2]f32{pos.x + flicker * 0.2, pos.y - 8}, flicker_r * 0.6, current_theme.torch_core)
    rl.DrawCircleV([2]f32{pos.x, pos.y - 9}, flicker_r * 0.25, rl.WHITE)
}

draw_summoning_pad :: proc(pos: [2]f32, time: f32) {
    pulse := math.sin(time * 2.0) * 0.1 + 0.9
    radius := LAUNCH_PAD_RADIUS

    rl.DrawCircleLinesV(pos, radius * 1.15, current_theme.wall_border)
    rl.DrawCircleLinesV(pos, radius, current_theme.wall_trim)
    rl.DrawCircleV(pos, radius - 2, rl.Color{24, 18, 32, 210})

    runes_count :: 8
    for i in 0..<runes_count {
        angle := (f32(i) / f32(runes_count)) * math.TAU + (time * 0.4)
        rx := pos.x + math.cos(angle) * (radius * 0.72)
        ry := pos.y + math.sin(angle) * (radius * 0.72)
        rune_alpha := u8((math.sin(time * 3.0 + f32(i)) * 0.3 + 0.7) * 220)
        c := current_theme.wall_trim
        c.a = rune_alpha
        rl.DrawCircleV([2]f32{rx, ry}, 3.0, c)
    }

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
