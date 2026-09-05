package hellfire

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

Game :: struct {
    state:              Game_State,
    current_wave:       int,
    score:              int,
    total_turns:        int,
    game_time:          f32,

    // Battle Entities
    orb:                Orb,
    enemies:            [MAX_ENEMIES]Enemy,
    enemy_count:        int,

    // Aiming State
    is_aiming:          bool,
    aim_pos:            [2]f32,
    aim_preview:        Trajectory_Preview,

    // Player Deck / Summoner Elements
    selected_element:   Element,

    // Transitions
    wave_clear_timer:   f32,
    banner_timer:       f32,

    // Evolution Stages (0 to 4 for all 15 elements)
    card_stages:        [TOTAL_ELEMENTS]int,

    // Active Floor Offerings (2 randomly rolled dual elements on each floor)
    active_floor_duals: [2]Element,
    floor_reveal_timer: f32,
}

game: Game

roll_floor_dual_cards :: proc(wave: int, theme_type: Environment_Type) -> [2]Element {
    duals := [10]Element{
        .STEAM, .MAGMA, .NETHERFLAME, .SOLAR, .MIRE,
        .ABYSS, .GLACIER, .OBSIDIAN, .CRYSTAL, .ECLIPSE,
    }

    weights := [10]f32{
        10.0, 10.0, 9.0, 8.0, 10.0,
        9.0,  9.0,  9.0, 8.0, 7.0,
    }

    // Boost weights based on Environment Theme affinity (+65%)
    switch theme_type {
    case .MAGMA_CAVERNS:
        weights[1] += 6.5 // MAGMA
        weights[2] += 6.5 // NETHERFLAME
        weights[0] += 5.0 // STEAM

    case .SUNKEN_TEMPLE:
        weights[0] += 6.0 // STEAM
        weights[4] += 6.5 // MIRE
        weights[5] += 6.5 // ABYSS
        weights[6] += 6.0 // GLACIER

    case .ABYSSAL_CRYPT:
        weights[2] += 6.0 // NETHERFLAME
        weights[5] += 6.5 // ABYSS
        weights[7] += 6.5 // OBSIDIAN
        weights[9] += 5.0 // ECLIPSE

    case .VERDANT_CATACOMBS:
        weights[4] += 7.0 // MIRE
        weights[7] += 5.5 // OBSIDIAN
        weights[8] += 6.5 // CRYSTAL

    case .ASTRAL_SPIRE:
        weights[3] += 7.0 // SOLAR
        weights[6] += 5.5 // GLACIER
        weights[8] += 6.5 // CRYSTAL
        weights[9] += 7.0 // ECLIPSE
    }

    // Higher floors slightly favor higher rarity dual elements
    if wave >= 3 {
        weights[3] += f32(wave) * 0.8 // SOLAR
        weights[8] += f32(wave) * 0.8 // CRYSTAL
        weights[9] += f32(wave) * 1.0 // ECLIPSE
    }

    // Sample first element
    total_w : f32 = 0.0
    for w in weights do total_w += w

    pick1_val := rand.float32() * total_w
    acc : f32 = 0.0
    idx1 := 0
    for i in 0..<10 {
        acc += weights[i]
        if pick1_val <= acc {
            idx1 = i
            break
        }
    }

    // Sample second distinct element without replacement
    weights2 := weights
    weights2[idx1] = 0.0
    total_w2 : f32 = 0.0
    for w in weights2 do total_w2 += w

    pick2_val := rand.float32() * total_w2
    acc2 : f32 = 0.0
    idx2 := (idx1 + 1) % 10
    for i in 0..<10 {
        acc2 += weights2[i]
        if pick2_val <= acc2 {
            idx2 = i
            break
        }
    }

    return [2]Element{duals[idx1], duals[idx2]}
}

game_init :: proc() {
    game.state = .TITLE
    game.current_wave = 1
    game.score = 0
    game.total_turns = 0
    game.game_time = 0.0
    game.selected_element = .FIRE
    game.banner_timer = 2.5
    game.floor_reveal_timer = 3.0

    for i in 0..<TOTAL_ELEMENTS {
        game.card_stages[i] = 0
    }
    init_evolution_menu()

    set_random_environment()
    game.active_floor_duals = roll_floor_dual_cards(game.current_wave, current_theme.type)
    reset_orb(&game.orb, game.selected_element)
    spawn_current_wave()
    spawn_blocks_for_wave(game.current_wave)
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

    if game.banner_timer > 0.0 {
        game.banner_timer -= dt
    }
    if game.floor_reveal_timer > 0.0 {
        game.floor_reveal_timer -= dt
    }

    // Screen shake update
    _ = update_screen_shake(dt)

    // Particles, shockwaves, ambient environment and combo popups
    update_particles(dt)
    update_ambient_particles(dt, current_theme.ambient_color1, current_theme.ambient_color2)
    update_shockwaves(dt)
    update_combo_popups(dt)
    update_damage_numbers(dt)
    update_blocks(dt)

    switch game.state {
    case .TITLE:
        if mouse_released || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER) {
            game.state = .BATTLE_AIMING
            reset_orb(&game.orb, game.selected_element)
            set_random_environment()
            spawn_current_wave()
            spawn_blocks_for_wave(game.current_wave)
            game.banner_timer = 2.5
        }

    case .BATTLE_AIMING:
        // Hotkeys for switching basic elements: 1=Fire, 2=Water, 3=Earth, 4=Chaos, 5=Light
        if rl.IsKeyPressed(.ONE)   do select_element(.FIRE)
        if rl.IsKeyPressed(.TWO)   do select_element(.WATER)
        if rl.IsKeyPressed(.THREE) do select_element(.EARTH)
        if rl.IsKeyPressed(.FOUR)  do select_element(.CHAOS)
        if rl.IsKeyPressed(.FIVE)  do select_element(.LIGHT)

        // Hotkeys for chamber dual elements: 6=Dual 1, 7=Dual 2
        if rl.IsKeyPressed(.SIX)   do select_element(game.active_floor_duals[0])
        if rl.IsKeyPressed(.SEVEN) do select_element(game.active_floor_duals[1])

        // Open Evolution Altar Menu with [E]
        if rl.IsKeyPressed(.E) {
            game.state = .EVOLUTION_MENU
            evo_menu.selected_element = game.selected_element
            return
        }

        // Check if player clicked the EVOLVE button on the battle HUD
        btn_evo_hud := rl.Rectangle{f32(VIRTUAL_WIDTH) - 170.0, f32(VIRTUAL_HEIGHT) - 235.0, 150.0, 34.0}
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_evo_hud) {
            game.state = .EVOLUTION_MENU
            evo_menu.selected_element = game.selected_element
            return
        }

        // Check if player clicked a card in the 7-slot bottom deck
        if mouse_pressed {
            card_w : f32 = 94.0
            card_h : f32 = 148.0
            base_y : f32 = f32(VIRTUAL_HEIGHT) - 162.0

            // 5 Basic Cards
            for i in 0..<5 {
                elem := Element(i)
                cx := 8.0 + f32(i) * 99.0
                cy := (elem == game.selected_element) ? (base_y - 10.0) : base_y
                card_rect := rl.Rectangle{cx, cy, card_w, card_h}
                if rl.CheckCollisionPointRec(mouse_pos, card_rect) {
                    select_element(elem)
                    return
                }
            }

            // 2 Active Chamber Dual Cards
            for i in 0..<2 {
                elem := game.active_floor_duals[i]
                cx := 516.0 + f32(i) * 100.0
                cy := (elem == game.selected_element) ? (base_y - 10.0) : base_y
                card_rect := rl.Rectangle{cx, cy, card_w, card_h}
                if rl.CheckCollisionPointRec(mouse_pos, card_rect) {
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
                    add_shockwave(LAUNCH_PAD_POS, 45.0, element_primary_color(game.orb.element))
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
            set_random_environment()
            game.active_floor_duals = roll_floor_dual_cards(game.current_wave, current_theme.type)
            spawn_current_wave()
            spawn_blocks_for_wave(game.current_wave)
            reset_orb(&game.orb, game.selected_element)
            game.state = .BATTLE_AIMING
            game.banner_timer = 2.5
            game.floor_reveal_timer = 3.5
        }

    case .GAME_OVER:
        if mouse_released {
            game_init()
        }

    case .EVOLUTION_MENU:
        update_evolution_menu(dt, mouse_pos, mouse_pressed)
    }
}

select_element :: proc(elem: Element) {
    game.selected_element = elem
    game.orb.element = elem
    emit_sparks(LAUNCH_PAD_POS, element_secondary_color(elem), 14, 200.0)
    add_shockwave(LAUNCH_PAD_POS, 32.0, element_secondary_color(elem), 0.25)
}

game_draw :: proc() {
    time := game.game_time

    if game.state == .EVOLUTION_MENU {
        draw_evolution_menu(time)
        return
    }

    // 2.5D Perspective Dungeon Arena & Environment Theme
    draw_arena(time)

    // Destructible Runic Blocks on Dungeon Floor
    draw_blocks(time)

    // Enemies on Dungeon Floor
    for i in 0..<game.enemy_count {
        draw_enemy(game.enemies[i], time)
    }

    // Shockwaves & Particles
    draw_shockwaves()
    draw_particles()

    // Orb & Trajectory Drawing
    if game.state == .BATTLE_AIMING {
        if game.is_aiming {
            pull := LAUNCH_PAD_POS - game.aim_pos
            pull_len := math.min(linalg.length(pull), MAX_PULL_DISTANCE)
            if pull_len > 15.0 {
                draw_aim_guide(game.aim_preview, game.orb.element)

                col := element_primary_color(game.orb.element)
                rl.DrawLineEx(LAUNCH_PAD_POS, game.aim_pos, 4.0, col)
                rl.DrawCircleV(game.aim_pos, game.orb.radius, col)
                rl.DrawCircleV(game.aim_pos, game.orb.radius * 0.5, rl.WHITE)
            }
        } else {
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

        // In-flight Orb
        rl.DrawCircleV(game.orb.pos, game.orb.radius + 3.0, element_secondary_color(game.orb.element))
        rl.DrawCircleV(game.orb.pos, game.orb.radius, element_primary_color(game.orb.element))
        rl.DrawCircleV(game.orb.pos, game.orb.radius * 0.45, rl.WHITE)
    }

    // Damage numbers and Flashy Combo Popups
    draw_damage_numbers()
    draw_combo_popups()

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
    // --- Top Bar (Dungeon Depth, Environment Name, Score, Combo) ---
    top_bar_rect := rl.Rectangle{0, 0, f32(VIRTUAL_WIDTH), 74}
    rl.DrawRectangleRec(top_bar_rect, rl.Color{16, 12, 22, 240})
    rl.DrawRectangleLinesEx(top_bar_rect, 2, current_theme.wall_trim)

    // Floor / Chamber Banner & Environment Name
    floor_text := rl.TextFormat("CHAMBER B%d", game.current_wave)
    rl.DrawText(floor_text, 24, 16, 24, COLOR_TEXT_GOLD)

    env_cstr := strings.clone_to_cstring(current_theme.name)
    defer delete(env_cstr)
    rl.DrawText(env_cstr, 24, 44, 15, current_theme.ambient_color1)

    // Score
    score_text := rl.TextFormat("SOULS: %d", game.score)
    rl.DrawText(score_text, 270, 24, 22, rl.RAYWHITE)

    // Turns
    turn_text := rl.TextFormat("FLICKS: %d", game.total_turns)
    rl.DrawText(turn_text, 540, 24, 20, rl.LIGHTGRAY)

    // Active in-flight combo badge
    if game.orb.combo > 1 {
        combo_mult := combo_multiplier_for_count(game.orb.combo)
        badge_text := rl.TextFormat("%dx COMBO (+%.0f%%)", game.orb.combo, (combo_mult - 1.0) * 100.0)
        badge_w := rl.MeasureText(badge_text, 22)

        badge_x := VIRTUAL_WIDTH / 2 - badge_w / 2
        badge_y : i32 = 84
        rl.DrawRectangle(badge_x - 12, badge_y - 4, badge_w + 24, 30, rl.Color{20, 15, 28, 220})
        rl.DrawRectangleLines(badge_x - 12, badge_y - 4, badge_w + 24, 30, rl.GOLD)
        rl.DrawText(badge_text, badge_x, badge_y + 1, 22, rl.GOLD)
    }

    // Chamber Entrance Banner Notification
    if game.banner_timer > 0.0 && game.state != .TITLE {
        banner_alpha := math.clamp(game.banner_timer / 0.5, 0.0, 1.0)
        c := current_theme.title_name
        tw := rl.MeasureText(c, 32)
        b_x := VIRTUAL_WIDTH / 2 - tw / 2
        b_y : i32 = 120

        bg_c := rl.Color{15, 10, 22, u8(banner_alpha * 220.0)}
        rl.DrawRectangle(b_x - 20, b_y - 6, tw + 40, 44, bg_c)
        rl.DrawRectangleLines(b_x - 20, b_y - 6, tw + 40, 44, current_theme.wall_trim)

        txt_c := current_theme.ambient_color1
        txt_c.a = u8(banner_alpha * 255.0)
        rl.DrawText(c, b_x, b_y, 32, txt_c)
    }

    // --- Elemental Affinity Quick Reference Mini-Wheel ---
    draw_elemental_wheel([2]f32{660.0, 120.0})

    // --- Bottom Elemental Summoning Deck ---
    tray_h : f32 = 198.0
    deck_tray := rl.Rectangle{0, f32(VIRTUAL_HEIGHT) - tray_h, f32(VIRTUAL_WIDTH), tray_h}
    rl.DrawRectangleRec(deck_tray, rl.Color{16, 12, 22, 245})
    rl.DrawRectangleLinesEx(deck_tray, 2, current_theme.wall_trim)

    deck_title : cstring : "SUMMON DECK  |  [1-5] Basic Elements  |  [6-7] Chamber Ascended Duals"
    dt_w := rl.MeasureText(deck_title, 14)
    rl.DrawText(deck_title, VIRTUAL_WIDTH / 2 - dt_w / 2, VIRTUAL_HEIGHT - 188, 14, current_theme.wall_trim)

    card_w : f32 = 94.0
    card_h : f32 = 148.0
    base_y : f32 = f32(VIRTUAL_HEIGHT) - 162.0

    // EVOLVE Sanctuary Button on Battle HUD
    btn_evo_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) - 170.0, f32(VIRTUAL_HEIGHT) - 235.0, 150.0, 34.0}
    rl.DrawRectangleRounded(btn_evo_rect, 0.25, 4, rl.Color{32, 22, 44, 230})
    rl.DrawRectangleRoundedLinesEx(btn_evo_rect, 0.25, 4, 2.0, COLOR_TEXT_GOLD)
    evo_btn_text : cstring : "EVOLVE [E] >>>"
    ebw := rl.MeasureText(evo_btn_text, 15)
    rl.DrawText(evo_btn_text, i32(btn_evo_rect.x + btn_evo_rect.width * 0.5) - ebw / 2, i32(btn_evo_rect.y + 9), 15, rl.GOLD)

    // Render 5 Basic Cards
    for i in 0..<5 {
        elem := Element(i)
        cx := 8.0 + f32(i) * 99.0
        is_selected := (elem == game.selected_element)
        cy := is_selected ? (base_y - 10.0) : base_y
        card_rect := rl.Rectangle{cx, cy, card_w, card_h}

        c_stage := game.card_stages[i]
        c_data := get_card_stage_data(elem, c_stage)

        draw_card(
            rect       = card_rect,
            elem       = elem,
            name       = c_data.name,
            rarity     = c_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = is_selected,
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = c_stage,
        )

        // Hotkey & Multiplier Badge above card
        key_str := fmt.tprintf("[%d]  %.0fx", i + 1, c_data.power_mult)
        k_cstr := strings.clone_to_cstring(key_str)
        defer delete(k_cstr)
        kw := rl.MeasureText(k_cstr, 12)
        rl.DrawRectangle(i32(cx + card_w * 0.5) - kw / 2 - 3, i32(cy - 15), kw + 6, 15, rl.Color{18, 14, 24, 230})
        rl.DrawRectangleLines(i32(cx + card_w * 0.5) - kw / 2 - 3, i32(cy - 15), kw + 6, 15, is_selected ? COLOR_TEXT_GOLD : current_theme.wall_trim)
        rl.DrawText(k_cstr, i32(cx + card_w * 0.5) - kw / 2, i32(cy - 14), 12, is_selected ? rl.GOLD : rl.WHITE)
    }

    // Vertical Runic Divider between Basic & Dual slots
    div_x : f32 = 507.0
    rl.DrawLineEx([2]f32{div_x, base_y - 8.0}, [2]f32{div_x, base_y + card_h + 4.0}, 2.0, rl.Color{140, 115, 75, 160})
    rl.DrawCircleV([2]f32{div_x, base_y + card_h * 0.5}, 4.0, rl.GOLD)

    // Render 2 Active Chamber Ascended Dual Cards
    for i in 0..<2 {
        elem := game.active_floor_duals[i]
        elem_idx := int(elem)
        cx := 516.0 + f32(i) * 100.0
        is_selected := (elem == game.selected_element)
        cy := is_selected ? (base_y - 10.0) : base_y
        card_rect := rl.Rectangle{cx, cy, card_w, card_h}

        c_stage := game.card_stages[elem_idx]
        c_data := get_card_stage_data(elem, c_stage)

        draw_card(
            rect       = card_rect,
            elem       = elem,
            name       = c_data.name,
            rarity     = c_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = is_selected,
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = c_stage,
        )

        // Hotkey & Multiplier Badge above card
        key_str := fmt.tprintf("[%d]  %.1fx", 6 + i, c_data.power_mult)
        k_cstr := strings.clone_to_cstring(key_str)
        defer delete(k_cstr)
        kw := rl.MeasureText(k_cstr, 12)
        rl.DrawRectangle(i32(cx + card_w * 0.5) - kw / 2 - 3, i32(cy - 15), kw + 6, 15, rl.Color{24, 18, 30, 240})
        rl.DrawRectangleLines(i32(cx + card_w * 0.5) - kw / 2 - 3, i32(cy - 15), kw + 6, 15, rl.GOLD)
        rl.DrawText(k_cstr, i32(cx + card_w * 0.5) - kw / 2, i32(cy - 14), 12, rl.GOLD)
    }

    // Chamber Ascended Duals Discovery Banner
    if game.floor_reveal_timer > 0.0 && game.state == .BATTLE_AIMING {
        alpha := math.clamp(game.floor_reveal_timer / 0.6, 0.0, 1.0)
        pop_y : f32 = 230.0
        pop_rect := rl.Rectangle{0, pop_y, f32(VIRTUAL_WIDTH), 52.0}
        rl.DrawRectangleRec(pop_rect, rl.Color{18, 14, 28, u8(alpha * 235.0)})
        rl.DrawRectangleLinesEx(pop_rect, 2.0, rl.GOLD)

        d1_name := strings.to_upper(element_name(game.active_floor_duals[0]), context.temp_allocator)
        d2_name := strings.to_upper(element_name(game.active_floor_duals[1]), context.temp_allocator)
        reveal_str := fmt.tprintf("✦ CHAMBER ASCENDED DUALS: [%s] & [%s] (1.5x POWER) ✦", d1_name, d2_name)
        r_cstr := strings.clone_to_cstring(reveal_str)
        defer delete(r_cstr)
        rw := rl.MeasureText(r_cstr, 17)
        rl.DrawText(r_cstr, VIRTUAL_WIDTH / 2 - rw / 2, i32(pop_y + 17), 17, rl.GOLD)
    }

    // --- State-Specific Overlays ---
    if game.state == .TITLE {
        rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{0, 0, 0, 195})

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

        guide_text : cstring : "Flick elemental orbs to chain combos & strike monster weak points!"
        gw := rl.MeasureText(guide_text, 17)
        rl.DrawText(guide_text, VIRTUAL_WIDTH / 2 - gw / 2, 760, 17, rl.LIGHTGRAY)
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

// Draw compact elemental wheel pentagram guide in the top corner
draw_elemental_wheel :: proc(center: [2]f32) {
    radius : f32 = 32.0

    // Background circle
    rl.DrawCircleV(center, radius + 8, rl.Color{16, 12, 24, 200})
    rl.DrawCircleLinesV(center, radius + 8, current_theme.wall_trim)

    // Mini elemental nodes in pentagram layout: Water -> Fire -> Earth -> Light -> Chaos -> Water
    elements := [5]Element{.WATER, .FIRE, .EARTH, .LIGHT, .CHAOS}
    pts: [5][2]f32
    for i in 0..<5 {
        ang := -math.PI * 0.5 + (f32(i) / 5.0) * math.TAU
        pts[i] = center + [2]f32{math.cos(ang) * radius, math.sin(ang) * radius}
    }

    // Connect nodes in circle
    for i in 0..<5 {
        next_i := (i + 1) % 5
        rl.DrawLineV(pts[i], pts[next_i], rl.Color{180, 160, 120, 160})
    }

    // Draw element dots
    for i in 0..<5 {
        elem := elements[i]
        c := element_primary_color(elem)
        rl.DrawCircleV(pts[i], 6.0, c)
        rl.DrawCircleLinesV(pts[i], 6.0, rl.WHITE)
    }
}

player_summon_name :: proc(elem: Element) -> (string, int) {
    #partial switch elem {
    case .FIRE:        return "Ignis Wyrm", 4
    case .WATER:       return "Leviathan", 4
    case .EARTH:       return "Gaea Titan", 4
    case .CHAOS:       return "Malphas", 5
    case .LIGHT:       return "Seraph", 5
    case .STEAM:       return "Boiling Hydra", 5
    case .MAGMA:       return "Volcano Colossus", 5
    case .NETHERFLAME: return "Nether Fiend", 6
    case .SOLAR:       return "Sun Sovereign", 6
    case .MIRE:        return "Swamp Chimera", 5
    case .ABYSS:       return "Kraken Terror", 6
    case .GLACIER:     return "Frost Empress", 6
    case .OBSIDIAN:    return "Onyx Gargoyle", 6
    case .CRYSTAL:     return "Prism Dragon", 6
    case .ECLIPSE:     return "Void Celestial", 7
    case:              return "Ascended Avatar", 5
    }
}
