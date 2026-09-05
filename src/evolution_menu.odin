package hellfire

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Evolution_Category :: enum {
    BASIC,
    DUAL,
}

Evolution_Menu_State :: struct {
    category:          Evolution_Category,
    selected_element:  Element,
    ascend_anim_timer: f32, // Flash animation on evolve
    ascend_banner:     string,
}

evo_menu: Evolution_Menu_State

init_evolution_menu :: proc() {
    evo_menu.category = .BASIC
    evo_menu.selected_element = .FIRE
    evo_menu.ascend_anim_timer = 0.0
    evo_menu.ascend_banner = ""
}

basic_advantage_target :: proc(elem: Element) -> string {
    #partial switch elem {
    case .WATER: return "Fire"
    case .FIRE:  return "Earth"
    case .EARTH: return "Light"
    case .LIGHT: return "Chaos"
    case .CHAOS: return "Water"
    }
    return ""
}

update_evolution_menu :: proc(dt: f32, mouse_pos: [2]f32, mouse_pressed: bool) {
    if evo_menu.ascend_anim_timer > 0.0 {
        evo_menu.ascend_anim_timer -= dt
    }

    // Tab toggles category between Basic and Dual
    if rl.IsKeyPressed(.TAB) {
        if evo_menu.category == .BASIC {
            evo_menu.category = .DUAL
            evo_menu.selected_element = game.active_floor_duals[0]
        } else {
            evo_menu.category = .BASIC
            evo_menu.selected_element = .FIRE
        }
    }

    // Keyboard Shortcuts:
    // [1-5] for elements in active category
    if evo_menu.category == .BASIC {
        if rl.IsKeyPressed(.ONE)   do evo_menu.selected_element = .FIRE
        if rl.IsKeyPressed(.TWO)   do evo_menu.selected_element = .WATER
        if rl.IsKeyPressed(.THREE) do evo_menu.selected_element = .EARTH
        if rl.IsKeyPressed(.FOUR)  do evo_menu.selected_element = .CHAOS
        if rl.IsKeyPressed(.FIVE)  do evo_menu.selected_element = .LIGHT
    } else {
        if rl.IsKeyPressed(.ONE)   do evo_menu.selected_element = .STEAM
        if rl.IsKeyPressed(.TWO)   do evo_menu.selected_element = .MAGMA
        if rl.IsKeyPressed(.THREE) do evo_menu.selected_element = .NETHERFLAME
        if rl.IsKeyPressed(.FOUR)  do evo_menu.selected_element = .SOLAR
        if rl.IsKeyPressed(.FIVE)  do evo_menu.selected_element = .MIRE
    }

    // [6] and [7] directly select the active floor dual cards and switch category to DUAL
    if rl.IsKeyPressed(.SIX) {
        evo_menu.category = .DUAL
        evo_menu.selected_element = game.active_floor_duals[0]
    }
    if rl.IsKeyPressed(.SEVEN) {
        evo_menu.category = .DUAL
        evo_menu.selected_element = game.active_floor_duals[1]
    }

    // [E], [ESCAPE], or [BACKSPACE] to exit
    if rl.IsKeyPressed(.E) || rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.BACKSPACE) {
        game.state = .BATTLE_AIMING
        return
    }

    elem := evo_menu.selected_element
    elem_idx := int(elem)
    cur_stage := game.card_stages[elem_idx]

    // [SPACE] or [ENTER] to Evolve
    if (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER)) && cur_stage < MAX_EVO_STAGES - 1 {
        game.card_stages[elem_idx] += 1
        new_stage := game.card_stages[elem_idx]
        next_data := get_card_stage_data(elem, new_stage)

        evo_menu.ascend_anim_timer = 1.2
        evo_menu.ascend_banner = fmt.tprintf("%s ASCENDED!", strings.to_upper(next_data.name, context.temp_allocator))

        emit_burst([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 410.0}, element_primary_color(elem), rl.GOLD, 55)
        add_shockwave([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 410.0}, 120.0, rl.GOLD, 0.45)
        add_screen_shake(7.0, 0.25)
        return
    }

    // [R] to Reset
    if rl.IsKeyPressed(.R) && cur_stage > 0 {
        game.card_stages[elem_idx] = 0
        emit_sparks([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 410.0}, rl.LIGHTGRAY, 20, 200.0)
        add_screen_shake(3.0, 0.1)
        return
    }

    // Category Selector Clicks
    cat_basic_rect := rl.Rectangle{20.0, 74.0, 332.0, 34.0}
    cat_dual_rect  := rl.Rectangle{368.0, 74.0, 332.0, 34.0}
    if mouse_pressed {
        if rl.CheckCollisionPointRec(mouse_pos, cat_basic_rect) {
            evo_menu.category = .BASIC
            if is_dual_element(evo_menu.selected_element) {
                evo_menu.selected_element = .FIRE
            }
            return
        }
        if rl.CheckCollisionPointRec(mouse_pos, cat_dual_rect) {
            evo_menu.category = .DUAL
            if !is_dual_element(evo_menu.selected_element) {
                evo_menu.selected_element = game.active_floor_duals[0]
            }
            return
        }
    }

    // Element Tabs Click Detection
    if evo_menu.category == .BASIC {
        tab_w : f32 = 132.0
        tab_h : f32 = 38.0
        tab_y : f32 = 114.0
        for i in 0..<5 {
            e := Element(i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, tab_y, tab_w, tab_h}
            if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, rect) {
                evo_menu.selected_element = e
                return
            }
        }
    } else {
        // Dual Elements in 2 Rows of 5
        tab_w : f32 = 132.0
        tab_h : f32 = 34.0
        // Row 1: Steam, Magma, Netherflame, Solar, Mire
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 112.0, tab_w, tab_h}
            if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, rect) {
                evo_menu.selected_element = e
                return
            }
        }
        // Row 2: Abyss, Glacier, Obsidian, Crystal, Eclipse
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + 5 + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 150.0, tab_w, tab_h}
            if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, rect) {
                evo_menu.selected_element = e
                return
            }
        }
    }

    // EVOLVE Button
    btn_evolve_rect := rl.Rectangle{180.0, 830.0, 360.0, 56.0}
    if cur_stage < MAX_EVO_STAGES - 1 {
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_evolve_rect) {
            game.card_stages[elem_idx] += 1
            new_stage := game.card_stages[elem_idx]
            next_data := get_card_stage_data(elem, new_stage)

            evo_menu.ascend_anim_timer = 1.2
            evo_menu.ascend_banner = fmt.tprintf("%s ASCENDED!", strings.to_upper(next_data.name, context.temp_allocator))

            emit_burst([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 410.0}, element_primary_color(elem), rl.GOLD, 55)
            add_shockwave([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 410.0}, 120.0, rl.GOLD, 0.45)
            add_screen_shake(7.0, 0.25)
            return
        }
    }

    // RESET TO BASE Button (For testing)
    btn_reset_rect := rl.Rectangle{220.0, 900.0, 280.0, 40.0}
    if cur_stage > 0 {
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_reset_rect) {
            game.card_stages[elem_idx] = 0
            emit_sparks([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 410.0}, rl.LIGHTGRAY, 20, 200.0)
            add_screen_shake(3.0, 0.1)
            return
        }
    }

    // RETURN TO DUNGEON Button
    btn_back_rect := rl.Rectangle{200.0, 955.0, 320.0, 48.0}
    if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_back_rect) {
        game.state = .BATTLE_AIMING
        return
    }
}

draw_evolution_menu :: proc(time: f32) {
    // Dim background void
    rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{10, 8, 16, 252})

    elem := evo_menu.selected_element
    elem_idx := int(elem)
    cur_stage := game.card_stages[elem_idx]
    cur_data := get_card_stage_data(elem, cur_stage)

    elem_col1 := element_primary_color(elem)
    elem_col2 := element_secondary_color(elem)
    is_dual := is_dual_element(elem)

    // --- Header Title ---
    header_rect := rl.Rectangle{0, 0, f32(VIRTUAL_WIDTH), 64}
    rl.DrawRectangleRec(header_rect, rl.Color{16, 12, 24, 255})
    rl.DrawRectangleLinesEx(header_rect, 2, current_theme.wall_trim)

    title_text : cstring : "ALTAR OF ASCENSION"
    tw := rl.MeasureText(title_text, 28)
    rl.DrawText(title_text, VIRTUAL_WIDTH / 2 - tw / 2, 14, 28, COLOR_TEXT_GOLD)

    sub_title : cstring : "Transcend Card Evolutions & Awaken Divine Forms"
    stw := rl.MeasureText(sub_title, 13)
    rl.DrawText(sub_title, VIRTUAL_WIDTH / 2 - stw / 2, 44, 13, rl.LIGHTGRAY)

    // --- Category Selector Tabs ---
    cat_basic_rect := rl.Rectangle{20.0, 72.0, 332.0, 34.0}
    cat_dual_rect  := rl.Rectangle{368.0, 72.0, 332.0, 34.0}

    is_cat_basic := (evo_menu.category == .BASIC)
    b_bg := is_cat_basic ? rl.Color{36, 26, 50, 255} : rl.Color{16, 14, 22, 220}
    d_bg := !is_cat_basic ? rl.Color{36, 26, 50, 255} : rl.Color{16, 14, 22, 220}

    rl.DrawRectangleRounded(cat_basic_rect, 0.18, 4, b_bg)
    rl.DrawRectangleRoundedLinesEx(cat_basic_rect, 0.18, 4, is_cat_basic ? 2.5 : 1.0, is_cat_basic ? COLOR_TEXT_GOLD : current_theme.wall_border)

    rl.DrawRectangleRounded(cat_dual_rect, 0.18, 4, d_bg)
    rl.DrawRectangleRoundedLinesEx(cat_dual_rect, 0.18, 4, !is_cat_basic ? 2.5 : 1.0, !is_cat_basic ? COLOR_TEXT_GOLD : current_theme.wall_border)

    cat_b_text : cstring : "[TAB] BASIC ELEMENTS (5)"
    cb_w := rl.MeasureText(cat_b_text, 15)
    rl.DrawText(cat_b_text, i32(cat_basic_rect.x + cat_basic_rect.width * 0.5) - cb_w / 2, i32(cat_basic_rect.y + 9), 15, is_cat_basic ? rl.GOLD : rl.GRAY)

    cat_d_text : cstring : "[TAB] DUAL ASCENSIONS (10) [1.5x PWR]"
    cd_w := rl.MeasureText(cat_d_text, 15)
    rl.DrawText(cat_d_text, i32(cat_dual_rect.x + cat_dual_rect.width * 0.5) - cd_w / 2, i32(cat_dual_rect.y + 9), 15, !is_cat_basic ? rl.GOLD : rl.GRAY)

    // --- Element Tabs ---
    if evo_menu.category == .BASIC {
        tab_w : f32 = 132.0
        tab_h : f32 = 38.0
        tab_y : f32 = 114.0

        for i in 0..<5 {
            e := Element(i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, tab_y, tab_w, tab_h}
            is_sel := (e == elem)

            bg := is_sel ? rl.Color{38, 28, 54, 255} : rl.Color{18, 15, 24, 230}
            rl.DrawRectangleRounded(rect, 0.16, 4, bg)
            rl.DrawRectangleRoundedLinesEx(rect, 0.16, 4, is_sel ? 2.5 : 1.0, is_sel ? COLOR_TEXT_GOLD : current_theme.wall_border)

            t_name := element_name(e)
            t_label := fmt.tprintf("[%d] %s", i + 1, strings.to_upper(t_name, context.temp_allocator))
            t_cstr := strings.clone_to_cstring(t_label)
            defer delete(t_cstr)
            lw := rl.MeasureText(t_cstr, 14)
            c := is_sel ? element_secondary_color(e) : rl.LIGHTGRAY
            rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(tab_y + 11), 14, c)
        }
    } else {
        // Dual Elements in 2 Rows of 5
        tab_w : f32 = 132.0
        tab_h : f32 = 34.0

        // Row 1
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 112.0, tab_w, tab_h}
            is_sel := (e == elem)
            is_floor := (e == game.active_floor_duals[0] || e == game.active_floor_duals[1])

            bg := is_sel ? rl.Color{40, 30, 58, 255} : rl.Color{18, 15, 24, 230}
            rl.DrawRectangleRounded(rect, 0.16, 4, bg)

            border_c := current_theme.wall_border
            if is_floor do border_c = rl.GOLD
            if is_sel   do border_c = rl.Color{255, 230, 120, 255}
            rl.DrawRectangleRoundedLinesEx(rect, 0.16, 4, is_sel ? 2.5 : (is_floor ? 1.8 : 1.0), border_c)

            t_name := element_name(e)
            t_label := is_floor ? fmt.tprintf("★ %s", strings.to_upper(t_name, context.temp_allocator)) : strings.to_upper(t_name, context.temp_allocator)
            t_cstr := strings.clone_to_cstring(t_label)
            defer delete(t_cstr)
            lw := rl.MeasureText(t_cstr, 13)
            c := is_sel ? element_secondary_color(e) : (is_floor ? rl.GOLD : rl.LIGHTGRAY)
            rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(112.0 + 10), 13, c)
        }

        // Row 2
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + 5 + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 150.0, tab_w, tab_h}
            is_sel := (e == elem)
            is_floor := (e == game.active_floor_duals[0] || e == game.active_floor_duals[1])

            bg := is_sel ? rl.Color{40, 30, 58, 255} : rl.Color{18, 15, 24, 230}
            rl.DrawRectangleRounded(rect, 0.16, 4, bg)

            border_c := current_theme.wall_border
            if is_floor do border_c = rl.GOLD
            if is_sel   do border_c = rl.Color{255, 230, 120, 255}
            rl.DrawRectangleRoundedLinesEx(rect, 0.16, 4, is_sel ? 2.5 : (is_floor ? 1.8 : 1.0), border_c)

            t_name := element_name(e)
            t_label := is_floor ? fmt.tprintf("★ %s", strings.to_upper(t_name, context.temp_allocator)) : strings.to_upper(t_name, context.temp_allocator)
            t_cstr := strings.clone_to_cstring(t_label)
            defer delete(t_cstr)
            lw := rl.MeasureText(t_cstr, 13)
            c := is_sel ? element_secondary_color(e) : (is_floor ? rl.GOLD : rl.LIGHTGRAY)
            rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(150.0 + 10), 13, c)
        }
    }

    // --- Compound Formula / Floor Manifestation Banner ---
    banner_y : f32 = (evo_menu.category == .BASIC) ? 160.0 : 190.0
    banner_rect := rl.Rectangle{40.0, banner_y, f32(VIRTUAL_WIDTH) - 80.0, 32.0}
    rl.DrawRectangleRounded(banner_rect, 0.2, 4, rl.Color{18, 14, 26, 230})
    rl.DrawRectangleRoundedLinesEx(banner_rect, 0.2, 4, 1.2, is_dual ? elem_col2 : current_theme.wall_border)

    if is_dual {
        p1, p2 := get_element_parents(elem)
        p1_name := strings.to_upper(element_name(p1), context.temp_allocator)
        p2_name := strings.to_upper(element_name(p2), context.temp_allocator)
        elem_n  := strings.to_upper(element_name(elem), context.temp_allocator)

        is_floor := (elem == game.active_floor_duals[0] || elem == game.active_floor_duals[1])
        slot_label := (elem == game.active_floor_duals[0]) ? "SLOT [6]" : "SLOT [7]"

        f_label: string
        if is_floor {
            f_label = fmt.tprintf("SYNTHESIS: [%s] + [%s] = %s  |  ✦ ACTIVE FLOOR SUMMON: READY IN %s ✦", p1_name, p2_name, elem_n, slot_label)
        } else {
            f_label = fmt.tprintf("SYNTHESIS: [%s] + [%s] = %s  |  ✦ DORMANT IN THIS CHAMBER (Manifests in Dungeon) ✦", p1_name, p2_name, elem_n)
        }
        
        f_cstr := strings.clone_to_cstring(f_label)
        defer delete(f_cstr)
        fw := rl.MeasureText(f_cstr, 13)
        b_col := is_floor ? rl.GOLD : elem_col2
        rl.DrawText(f_cstr, VIRTUAL_WIDTH / 2 - fw / 2, i32(banner_y + 9), 13, b_col)
    } else {
        b_label := fmt.tprintf("PRIME ELEMENT: %s  |  BASE HIT POWER: 100%% - 500%%  |  PRESS [TAB] FOR DUAL ASCENSIONS", strings.to_upper(element_name(elem), context.temp_allocator))
        b_cstr := strings.clone_to_cstring(b_label)
        defer delete(b_cstr)
        bw := rl.MeasureText(b_cstr, 13)
        rl.DrawText(b_cstr, VIRTUAL_WIDTH / 2 - bw / 2, i32(banner_y + 9), 13, elem_col2)
    }

    // --- Tier Stepper Progress Bar ---
    stepper_y : f32 = banner_y + 44.0
    stepper_w : f32 = 480.0
    stepper_x : f32 = (f32(VIRTUAL_WIDTH) - stepper_w) * 0.5

    // Connecting line
    rl.DrawLineEx([2]f32{stepper_x, stepper_y}, [2]f32{stepper_x + stepper_w, stepper_y}, 3.0, current_theme.wall_border)

    for s in 0..<MAX_EVO_STAGES {
        sx := stepper_x + (f32(s) / 4.0) * stepper_w
        is_reached := (s <= cur_stage)
        is_active  := (s == cur_stage)

        node_r : f32 = is_active ? 15.0 : 11.0
        node_col := is_reached ? elem_col1 : rl.DARKGRAY
        if is_active do node_col = rl.GOLD

        rl.DrawCircleV([2]f32{sx, stepper_y}, node_r, node_col)
        rl.DrawCircleLinesV([2]f32{sx, stepper_y}, node_r + 2, is_active ? rl.WHITE : current_theme.wall_trim)

        roman_str := fmt.tprintf("%d", s + 1)
        r_cstr := strings.clone_to_cstring(roman_str)
        defer delete(r_cstr)
        rw := rl.MeasureText(r_cstr, 13)
        rl.DrawText(r_cstr, i32(sx) - rw / 2, i32(stepper_y) - 6, 13, is_reached ? rl.WHITE : rl.BLACK)
    }

    // --- Main Card Display Showcase ---
    card_start_y : f32 = stepper_y + 24.0

    if cur_stage < MAX_EVO_STAGES - 1 {
        // Dual Card Comparison Showcase: Current -> Next Evolved
        next_data := get_card_stage_data(elem, cur_stage + 1)

        card_w : f32 = 216.0
        card_h : f32 = 286.0

        // Current Card (Left)
        left_card_x : f32 = 82.0
        draw_card(
            rect       = rl.Rectangle{left_card_x, card_start_y, card_w, card_h},
            elem       = elem,
            name       = cur_data.name,
            rarity     = cur_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = false,
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = cur_stage,
        )

        // Next Evolved Card (Right)
        right_card_x : f32 = f32(VIRTUAL_WIDTH) - left_card_x - card_w
        draw_card(
            rect       = rl.Rectangle{right_card_x, card_start_y, card_w, card_h},
            elem       = elem,
            name       = next_data.name,
            rarity     = next_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = true, // Shimmers as preview target
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = cur_stage + 1,
        )

        // Middle Evolution Indicator Arrow
        mid_x : f32 = f32(VIRTUAL_WIDTH) * 0.5
        arrow_y : f32 = card_start_y + card_h * 0.5
        arrow_pulse := math.sin(time * 5.0) * 0.2 + 0.8
        rl.DrawCircleV([2]f32{mid_x, arrow_y}, 26.0 * arrow_pulse, rl.Color{elem_col2.r, elem_col2.g, elem_col2.b, 80})
        arrow_text : cstring : ">>>"
        aw := rl.MeasureText(arrow_text, 26)
        rl.DrawText(arrow_text, i32(mid_x) - aw / 2, i32(arrow_y) - 13, 26, COLOR_TEXT_GOLD)

        // --- Stat Increase Banner ---
        stat_box_y : f32 = card_start_y + card_h + 12.0
        stat_rect := rl.Rectangle{50, stat_box_y, f32(VIRTUAL_WIDTH) - 100, 134}
        rl.DrawRectangleRounded(stat_rect, 0.12, 4, rl.Color{20, 16, 28, 240})
        rl.DrawRectangleRoundedLinesEx(stat_rect, 0.12, 4, 2.0, COLOR_TEXT_GOLD)

        // Power comparison
        p_text := rl.TextFormat("BASE HIT POWER:  %.0f%%  >>>  %.0f%% DMG", cur_data.power_mult * 100.0, next_data.power_mult * 100.0)
        pw := rl.MeasureText(p_text, 19)
        rl.DrawText(p_text, VIRTUAL_WIDTH / 2 - pw / 2, i32(stat_box_y + 14), 19, rl.GOLD)

        // Rarity comparison
        r_text := rl.TextFormat("RARITY:  %d STARS  >>>  %d STARS", cur_data.rarity, next_data.rarity)
        rw := rl.MeasureText(r_text, 17)
        rl.DrawText(r_text, VIRTUAL_WIDTH / 2 - rw / 2, i32(stat_box_y + 46), 17, rl.WHITE)

        // Description / Lore snippet
        desc_cstr := strings.clone_to_cstring(next_data.description)
        defer delete(desc_cstr)
        dw := rl.MeasureText(desc_cstr, 15)
        rl.DrawText(desc_cstr, VIRTUAL_WIDTH / 2 - dw / 2, i32(stat_box_y + 78), 15, elem_col2)

        p_gain := rl.TextFormat("+%.0f%% DAMAGE MULTIPLIER ON HIT!", (next_data.power_mult - cur_data.power_mult) * 100.0)
        pg_w := rl.MeasureText(p_gain, 16)
        rl.DrawText(p_gain, VIRTUAL_WIDTH / 2 - pg_w / 2, i32(stat_box_y + 106), 16, elem_col1)

    } else {
        // Supreme Divine Final Form Showcase (Center)
        card_w : f32 = 252.0
        card_h : f32 = 336.0
        card_x : f32 = (f32(VIRTUAL_WIDTH) - card_w) * 0.5

        draw_card(
            rect       = rl.Rectangle{card_x, card_start_y, card_w, card_h},
            elem       = elem,
            name       = cur_data.name,
            rarity     = cur_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = true,
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = 4,
        )

        stat_box_y : f32 = card_start_y + card_h + 12.0
        stat_rect := rl.Rectangle{50, stat_box_y, f32(VIRTUAL_WIDTH) - 100, 106}
        rl.DrawRectangleRounded(stat_rect, 0.12, 4, rl.Color{24, 18, 32, 245})
        rl.DrawRectangleRoundedLinesEx(stat_rect, 0.12, 4, 2.5, rl.GOLD)

        max_title : cstring : "SUPREME GODDESS ASCENSION COMPLETE"
        mw := rl.MeasureText(max_title, 19)
        rl.DrawText(max_title, VIRTUAL_WIDTH / 2 - mw / 2, i32(stat_box_y + 14), 19, rl.GOLD)

        m_text := rl.TextFormat("%.0f%% MAXIMUM DIVINE DAMAGE MULTIPLIER", cur_data.power_mult * 100.0)
        mtw := rl.MeasureText(m_text, 17)
        rl.DrawText(m_text, VIRTUAL_WIDTH / 2 - mtw / 2, i32(stat_box_y + 44), 17, rl.WHITE)

        desc_cstr := strings.clone_to_cstring(cur_data.description)
        defer delete(desc_cstr)
        dw := rl.MeasureText(desc_cstr, 14)
        rl.DrawText(desc_cstr, VIRTUAL_WIDTH / 2 - dw / 2, i32(stat_box_y + 74), 14, elem_col2)
    }

    // --- Lore & Elemental Synergy Box ---
    lore_y : f32 = 712.0
    lore_rect := rl.Rectangle{50.0, lore_y, f32(VIRTUAL_WIDTH) - 100.0, 98.0}
    rl.DrawRectangleRounded(lore_rect, 0.12, 4, rl.Color{16, 12, 22, 230})
    rl.DrawRectangleRoundedLinesEx(lore_rect, 0.12, 4, 1.2, current_theme.wall_border)

    // Title / Epithet
    epithet_label := fmt.tprintf("« %s »  —  %s", strings.to_upper(cur_data.name, context.temp_allocator), cur_data.epithet)
    ep_cstr := strings.clone_to_cstring(epithet_label)
    defer delete(ep_cstr)
    ew := rl.MeasureText(ep_cstr, 15)
    rl.DrawText(ep_cstr, VIRTUAL_WIDTH / 2 - ew / 2, i32(lore_y + 12), 15, COLOR_TEXT_GOLD)

    if is_dual {
        p1, p2 := get_element_parents(elem)
        syn_label := fmt.tprintf("Dual Synergy: Combines %s + %s affinities (Super Effective: 1.85x against foes!)", element_name(p1), element_name(p2))
        s_cstr := strings.clone_to_cstring(syn_label)
        defer delete(s_cstr)
        sw := rl.MeasureText(s_cstr, 13)
        rl.DrawText(s_cstr, VIRTUAL_WIDTH / 2 - sw / 2, i32(lore_y + 40), 13, elem_col2)

        scale_label := fmt.tprintf("Ascension Scaling: 1.5x Base Power per Tier (150%% -> 750%% Divine Cap)")
        sc_cstr := strings.clone_to_cstring(scale_label)
        defer delete(sc_cstr)
        scw := rl.MeasureText(sc_cstr, 13)
        rl.DrawText(sc_cstr, VIRTUAL_WIDTH / 2 - scw / 2, i32(lore_y + 66), 13, rl.RAYWHITE)
    } else {
        adv_target := basic_advantage_target(elem)
        adv_label := fmt.tprintf("Elemental Cycle: %s is Super Effective against %s (1.85x Damage)", element_name(elem), adv_target)
        a_cstr := strings.clone_to_cstring(adv_label)
        defer delete(a_cstr)
        aw := rl.MeasureText(a_cstr, 13)
        rl.DrawText(a_cstr, VIRTUAL_WIDTH / 2 - aw / 2, i32(lore_y + 40), 13, elem_col2)

        deck_label := fmt.tprintf("Deck Deployment: Permanent Basic Elemental Card in Slot [%d]", elem_idx + 1)
        dk_cstr := strings.clone_to_cstring(deck_label)
        defer delete(dk_cstr)
        dkw := rl.MeasureText(dk_cstr, 13)
        rl.DrawText(dk_cstr, VIRTUAL_WIDTH / 2 - dkw / 2, i32(lore_y + 66), 13, rl.RAYWHITE)
    }

    // --- Interactive Action Buttons ---
    // 1. EVOLVE BUTTON
    if cur_stage < MAX_EVO_STAGES - 1 {
        btn_y : f32 = 828.0
        btn_rect := rl.Rectangle{180.0, btn_y, 360.0, 56.0}
        pulse := math.sin(time * 6.0) * 0.1 + 0.9

        rl.DrawRectangleRounded(btn_rect, 0.2, 4, rl.Color{42, 28, 56, 255})
        rl.DrawRectangleRoundedLinesEx(btn_rect, 0.2, 4, 3.0 * pulse, COLOR_TEXT_GOLD)

        evo_label := rl.TextFormat("[SPACE] ASCEND TO TIER %d >>>", cur_stage + 2)
        ev_w := rl.MeasureText(evo_label, 20)
        rl.DrawText(evo_label, VIRTUAL_WIDTH / 2 - ev_w / 2, i32(btn_y + 17), 20, rl.GOLD)
    }

    // 2. RESET TIER BUTTON
    if cur_stage > 0 {
        rbtn_y : f32 = 898.0
        rbtn_rect := rl.Rectangle{220.0, rbtn_y, 280.0, 40.0}
        rl.DrawRectangleRounded(rbtn_rect, 0.2, 4, rl.Color{24, 18, 28, 220})
        rl.DrawRectangleRoundedLinesEx(rbtn_rect, 0.2, 4, 1.5, rl.GRAY)

        rst_text : cstring : "[R] RESET TO TIER I"
        rw := rl.MeasureText(rst_text, 15)
        rl.DrawText(rst_text, VIRTUAL_WIDTH / 2 - rw / 2, i32(rbtn_y + 12), 15, rl.LIGHTGRAY)
    }

    // 3. RETURN TO DUNGEON BUTTON
    back_y : f32 = 952.0
    back_rect := rl.Rectangle{200.0, back_y, 320.0, 48.0}
    rl.DrawRectangleRounded(back_rect, 0.2, 4, rl.Color{18, 14, 24, 240})
    rl.DrawRectangleRoundedLinesEx(back_rect, 0.2, 4, 2.0, current_theme.wall_trim)

    back_text : cstring : "[ESC / E] RETURN TO DUNGEON"
    bw := rl.MeasureText(back_text, 17)
    rl.DrawText(back_text, VIRTUAL_WIDTH / 2 - bw / 2, i32(back_y + 15), 17, rl.WHITE)

    // Ascension Complete Popup Banner
    if evo_menu.ascend_anim_timer > 0.0 {
        b_alpha := math.clamp(evo_menu.ascend_anim_timer / 0.3, 0.0, 1.0)
        pop_rect := rl.Rectangle{0, 410, f32(VIRTUAL_WIDTH), 110}
        rl.DrawRectangleRec(pop_rect, rl.Color{22, 16, 32, u8(b_alpha * 240.0)})
        rl.DrawRectangleLinesEx(pop_rect, 3, rl.GOLD)

        top_t : cstring : "✦ DIVINE ASCENSION COMPLETE ✦"
        pop_tw := rl.MeasureText(top_t, 26)
        rl.DrawText(top_t, VIRTUAL_WIDTH / 2 - pop_tw / 2, 425, 26, rl.GOLD)

        sub_cstr := strings.clone_to_cstring(evo_menu.ascend_banner)
        defer delete(sub_cstr)
        sw := rl.MeasureText(sub_cstr, 22)
        rl.DrawText(sub_cstr, VIRTUAL_WIDTH / 2 - sw / 2, 465, 22, elem_col2)
    }
}
