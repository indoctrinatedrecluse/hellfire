package hellfire

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"

Game :: struct {
    state:             Game_State,
    current_wave:      int,
    score:             int,
    total_turns:       int,
    game_time:         f32,

    // Battle Entities
    orb:               Orb,
    enemies:           [MAX_ENEMIES]Enemy,
    enemy_count:       int,

    // Aiming State
    is_aiming:         bool,
    aim_pos:           [2]f32,
    aim_preview:       Trajectory_Preview,

    // Player Deck / Summoner Elements
    selected_element:  Element,

    // Transitions
    wave_clear_timer:  f32,
}

game: Game

game_init :: proc() {
    game.state = .TITLE
    game.current_wave = 1
    game.score = 0
    game.total_turns = 0
    game.game_time = 0.0
    game.selected_element = .FIRE

    reset_orb(&game.orb, game.selected_element)
    spawn_current_wave()
}

reset_orb :: proc(orb: ^Orb, elem: Element) {
    orb.pos = LAUNCH_PAD_POS
    orb.vel = {0.0, 0.0}
    orb.radius = BALL_BASE_RADIUS
    orb.element = elem
    orb.active = false
    orb.bounces = 0
    orb.combo = 0
    orb.trail_count = 0
    orb.trail_timer = 0.0
}

spawn_current_wave :: proc() {
    w := get_wave(game.current_wave)
    game.enemy_count = w.enemy_count
    for i in 0..<w.enemy_count {
        game.enemies[i] = w.enemies[i]
    }
}

game_update :: proc(dt: f32, mouse_pos: [2]f32, mouse_pressed, mouse_down, mouse_released: bool) {
    game.game_time += dt

    // Screen shake update
    _ = update_screen_shake(dt)

    // Particles and floating text update
    update_particles(dt)
    update_damage_numbers(dt)

    switch game.state {
    case .TITLE:
        if mouse_released || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER) {
            game.state = .BATTLE_AIMING
            reset_orb(&game.orb, game.selected_element)
            spawn_current_wave()
        }

    case .BATTLE_AIMING:
        // Hotkeys for switching elements: 1=Fire, 2=Water, 3=Earth, 4=Chaos, 5=Light
        if rl.IsKeyPressed(.ONE)   do select_element(.FIRE)
        if rl.IsKeyPressed(.TWO)   do select_element(.WATER)
        if rl.IsKeyPressed(.THREE) do select_element(.EARTH)
        if rl.IsKeyPressed(.FOUR)  do select_element(.CHAOS)
        if rl.IsKeyPressed(.FIVE)  do select_element(.LIGHT)

        // Check if player clicked an elemental summoning stone at the bottom
        if mouse_pressed {
            deck_y : f32 = 1170.0
            for elem in Element {
                idx := int(elem)
                slot_x := f32(110 + idx * 125)
                if linalg.distance(mouse_pos, [2]f32{slot_x, deck_y}) < 36.0 {
                    select_element(elem)
                    return
                }
            }
        }

        // Slingshot Aiming Drag
        if !game.is_aiming {
            if mouse_pressed && linalg.distance(mouse_pos, LAUNCH_PAD_POS) < 70.0 {
                game.is_aiming = true
                game.aim_pos = mouse_pos
            }
        } else {
            if mouse_down {
                game.aim_pos = mouse_pos
                pull := LAUNCH_PAD_POS - mouse_pos
                pull_len := math.min(linalg.length(pull), MAX_PULL_DISTANCE)
                if pull_len > 15.0 {
                    dir := linalg.normalize0(pull)
                    game.aim_preview = calculate_trajectory(LAUNCH_PAD_POS, dir, 750.0)
                }
            }

            if mouse_released {
                game.is_aiming = false
                pull := LAUNCH_PAD_POS - mouse_pos
                pull_len := math.min(linalg.length(pull), MAX_PULL_DISTANCE)

                if pull_len > 25.0 {
                    dir := linalg.normalize0(pull)
                    speed := pull_len * LAUNCH_SPEED_MULT
                    game.orb.vel = dir * speed
                    game.orb.active = true
                    game.orb.bounces = 0
                    game.orb.combo = 0
                    game.state = .BATTLE_FLYING
                    game.total_turns += 1

                    // Launch sparks & screen thump
                    emit_sparks(LAUNCH_PAD_POS, element_primary_color(game.orb.element), 18, 300.0)
                    add_screen_shake(3.0, 0.1)
                }
            }
        }

        update_enemies(&game.enemies, game.enemy_count, dt)

    case .BATTLE_FLYING:
        orb_alive := update_orb_physics(&game.orb, &game.enemies, game.enemy_count, dt)
        update_enemies(&game.enemies, game.enemy_count, dt)

        // Check if all enemies defeated
        all_dead := true
        for i in 0..<game.enemy_count {
            if game.enemies[i].alive {
                all_dead = false
                break
            }
        }

        if all_dead {
            game.state = .WAVE_CLEARED
            game.wave_clear_timer = 2.0
            game.score += 500 * game.current_wave + (game.orb.combo * 50)
            add_screen_shake(7.0, 0.3)
            return
        }

        // If orb finished its flight, reset to aiming
        if !orb_alive {
            reset_orb(&game.orb, game.selected_element)
            game.state = .BATTLE_AIMING
        }

    case .WAVE_CLEARED:
        update_enemies(&game.enemies, game.enemy_count, dt)
        game.wave_clear_timer -= dt
        if game.wave_clear_timer <= 0.0 || (mouse_released && game.wave_clear_timer < 1.4) {
            game.current_wave += 1
            spawn_current_wave()
            reset_orb(&game.orb, game.selected_element)
            game.state = .BATTLE_AIMING
        }

    case .GAME_OVER:
        if mouse_released {
            game_init()
        }
    }
}

select_element :: proc(elem: Element) {
    game.selected_element = elem
    game.orb.element = elem
    emit_sparks(LAUNCH_PAD_POS, element_secondary_color(elem), 14, 200.0)
}

game_draw :: proc() {
    time := game.game_time

    // 2.5D Perspective Dungeon Arena & Environment
    draw_arena(time)

    // Enemies on Dungeon Floor
    for i in 0..<game.enemy_count {
        draw_enemy(game.enemies[i], time)
    }

    // Particles & Floating Damage Numbers
    draw_particles()
    draw_damage_numbers()

    // Orb & Trajectory Drawing
    if game.state == .BATTLE_AIMING {
        if game.is_aiming {
            pull := LAUNCH_PAD_POS - game.aim_pos
            pull_len := math.min(linalg.length(pull), MAX_PULL_DISTANCE)
            if pull_len > 15.0 {
                // Aim prediction line
                draw_aim_guide(game.aim_preview, game.orb.element)

                // Slingshot elastic band
                col := element_primary_color(game.orb.element)
                rl.DrawLineEx(LAUNCH_PAD_POS, game.aim_pos, 4.0, col)
                rl.DrawCircleV(game.aim_pos, game.orb.radius, col)
                rl.DrawCircleV(game.aim_pos, game.orb.radius * 0.5, rl.WHITE)
            }
        } else {
            // Orb sitting ready on summoning pad
            draw_ready_orb(LAUNCH_PAD_POS, game.orb.element, time)
        }
    } else if game.state == .BATTLE_FLYING {
        // Draw Orb Trail
        for j in 0..<game.orb.trail_count {
            alpha := f32(game.orb.trail_count - j) / f32(MAX_TRAIL_POINTS)
            trail_r := game.orb.radius * (0.2 + 0.6 * alpha)
            c := element_secondary_color(game.orb.element)
            c.a = u8(alpha * 180.0)
            rl.DrawCircleV(game.orb.trail[j], trail_r, c)
        }

        // Draw In-flight Orb
        rl.DrawCircleV(game.orb.pos, game.orb.radius + 3.0, element_secondary_color(game.orb.element))
        rl.DrawCircleV(game.orb.pos, game.orb.radius, element_primary_color(game.orb.element))
        rl.DrawCircleV(game.orb.pos, game.orb.radius * 0.45, rl.WHITE)
    }

    // HUD / UI Overlay
    draw_hud(time)
}

draw_ready_orb :: proc(pos: [2]f32, elem: Element, time: f32) {
    pulse := math.sin(time * 4.0) * 2.0
    r := BALL_BASE_RADIUS + pulse
    c1 := element_primary_color(elem)
    c2 := element_secondary_color(elem)

    rl.DrawCircleV(pos, r + 4.0, c2)
    rl.DrawCircleV(pos, r, c1)
    rl.DrawCircleV(pos, r * 0.5, rl.WHITE)
    rl.DrawCircleLinesV(pos, r + 5.0, COLOR_TEXT_GOLD)
}

draw_hud :: proc(time: f32) {
    // --- Top Bar (Dungeon Depth, Score, Combo) ---
    top_bar_rect := rl.Rectangle{0, 0, f32(VIRTUAL_WIDTH), 70}
    rl.DrawRectangleRec(top_bar_rect, rl.Color{16, 12, 22, 240})
    rl.DrawRectangleLinesEx(top_bar_rect, 2, COLOR_WALL_TRIM)

    // Floor / Chamber Banner
    floor_text := rl.TextFormat("CHAMBER B%d", game.current_wave)
    rl.DrawText(floor_text, 30, 22, 26, COLOR_TEXT_GOLD)

    // Score
    score_text := rl.TextFormat("SOULS: %d", game.score)
    rl.DrawText(score_text, 260, 24, 22, rl.RAYWHITE)

    // Turns
    turn_text := rl.TextFormat("FLICKS: %d", game.total_turns)
    rl.DrawText(turn_text, 540, 24, 20, rl.LIGHTGRAY)

    // Combo Counter (Shows during flight / combo chaining)
    if game.orb.combo > 1 {
        combo_pulse := math.sin(time * 10.0) * 0.15 + 1.0
        combo_text := rl.TextFormat("%dx COMBO!", game.orb.combo)
        combo_w := rl.MeasureText(combo_text, 34)
        rl.DrawText(combo_text, VIRTUAL_WIDTH / 2 - combo_w / 2 + 2, 90 + 2, 34, rl.BLACK)
        rl.DrawText(combo_text, VIRTUAL_WIDTH / 2 - combo_w / 2, 90, 34, rl.GOLD)
    }

    // --- Bottom Elemental Summoning Deck ---
    deck_tray := rl.Rectangle{0, f32(VIRTUAL_HEIGHT) - 170, f32(VIRTUAL_WIDTH), 170}
    rl.DrawRectangleRec(deck_tray, rl.Color{18, 14, 26, 245})
    rl.DrawRectangleLinesEx(deck_tray, 2, COLOR_WALL_TRIM)

    deck_title : cstring : "SELECT SUMMON ORB [1 - 5]"
    dt_w := rl.MeasureText(deck_title, 16)
    rl.DrawText(deck_title, VIRTUAL_WIDTH / 2 - dt_w / 2, VIRTUAL_HEIGHT - 160, 16, COLOR_WALL_TRIM)

    deck_y : f32 = 1180.0
    for elem in Element {
        idx := int(elem)
        slot_x := f32(100 + idx * 130)
        is_selected := (elem == game.selected_element)

        slot_r : f32 = is_selected ? 36.0 : 28.0
        c1 := element_primary_color(elem)
        c2 := element_secondary_color(elem)

        // Selection ring
        if is_selected {
            rl.DrawCircleLinesV([2]f32{slot_x, deck_y}, slot_r + 6.0, COLOR_TEXT_GOLD)
            rl.DrawCircleLinesV([2]f32{slot_x, deck_y}, slot_r + 8.0, rl.GOLD)
        }

        rl.DrawCircleV([2]f32{slot_x, deck_y}, slot_r, c1)
        rl.DrawCircleV([2]f32{slot_x, deck_y}, slot_r * 0.6, c2)
        rl.DrawCircleLinesV([2]f32{slot_x, deck_y}, slot_r, rl.Color{20, 15, 25, 255})

        // Element Name & Hotkey
        name_str := element_name(elem)
        key_num := fmt.tprintf("[%d]", idx + 1)
        k_cstr := strings.clone_to_cstring(key_num)
        defer delete(k_cstr)
        kw := rl.MeasureText(k_cstr, 16)
        rl.DrawText(k_cstr, i32(slot_x) - kw / 2, i32(deck_y + slot_r + 6), 16, rl.WHITE)

        n_cstr := strings.clone_to_cstring(name_str)
        defer delete(n_cstr)
        nw := rl.MeasureText(n_cstr, 14)
        rl.DrawText(n_cstr, i32(slot_x) - nw / 2, i32(deck_y - slot_r - 20), 14, c2)
    }

    // --- State-Specific Overlays ---
    if game.state == .TITLE {
        rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{0, 0, 0, 190})

        title_text : cstring : "HELLFIRE"
        sub_text   : cstring : "THE DUNGEON SUMMONING"
        prompt     : cstring : "TAP OR CLICK TO ENTER THE ABYSS"

        tw := rl.MeasureText(title_text, 68)
        sw := rl.MeasureText(sub_text, 24)
        pw := rl.MeasureText(prompt, 20)

        rl.DrawText(title_text, VIRTUAL_WIDTH / 2 - tw / 2 + 3, 360 + 3, 68, rl.BLACK)
        rl.DrawText(title_text, VIRTUAL_WIDTH / 2 - tw / 2, 360, 68, rl.Color{255, 60, 30, 255})

        rl.DrawText(sub_text, VIRTUAL_WIDTH / 2 - sw / 2, 445, 24, COLOR_TEXT_GOLD)

        pulse := math.sin(time * 4.0) * 0.3 + 0.7
        prompt_col := rl.Color{255, 220, 140, u8(pulse * 255)}
        rl.DrawText(prompt, VIRTUAL_WIDTH / 2 - pw / 2, 700, 20, prompt_col)

        guide_text : cstring : "Drag & flick elemental orbs to strike monster weak points!"
        gw := rl.MeasureText(guide_text, 18)
        rl.DrawText(guide_text, VIRTUAL_WIDTH / 2 - gw / 2, 760, 18, rl.LIGHTGRAY)
    } else if game.state == .WAVE_CLEARED {
        banner_rect := rl.Rectangle{0, 480, f32(VIRTUAL_WIDTH), 140}
        rl.DrawRectangleRec(banner_rect, rl.Color{20, 16, 28, 230})
        rl.DrawRectangleLinesEx(banner_rect, 3, COLOR_TEXT_GOLD)

        c_text : cstring : "CHAMBER PURGED!"
        cw := rl.MeasureText(c_text, 44)
        rl.DrawText(c_text, VIRTUAL_WIDTH / 2 - cw / 2, 510, 44, rl.GOLD)

        next_text : cstring : "DESCENDING TO NEXT FLOOR..."
        nw := rl.MeasureText(next_text, 22)
        rl.DrawText(next_text, VIRTUAL_WIDTH / 2 - nw / 2, 570, 22, rl.WHITE)
    } else if game.state == .BATTLE_AIMING && !game.is_aiming {
        hint : cstring : "Pull back on orb to aim & release to strike!"
        hw := rl.MeasureText(hint, 18)
        rl.DrawText(hint, VIRTUAL_WIDTH / 2 - hw / 2, 940, 18, rl.Color{230, 210, 170, 200})
    }
}
