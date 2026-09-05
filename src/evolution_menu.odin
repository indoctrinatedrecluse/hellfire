package hellfire

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Evolution_Menu_State :: struct {
    selected_element: Element,
    ascend_anim_timer: f32, // Flash animation on evolve
    ascend_banner:    string,
}

evo_menu: Evolution_Menu_State

init_evolution_menu :: proc() {
    evo_menu.selected_element = .FIRE
    evo_menu.ascend_anim_timer = 0.0
    evo_menu.ascend_banner = ""
}

update_evolution_menu :: proc(dt: f32, mouse_pos: [2]f32, mouse_pressed: bool) {
    if evo_menu.ascend_anim_timer > 0.0 {
        evo_menu.ascend_anim_timer -= dt
    }

    // Keyboard shortcuts
    if rl.IsKeyPressed(.ONE)   do evo_menu.selected_element = .FIRE
    if rl.IsKeyPressed(.TWO)   do evo_menu.selected_element = .WATER
    if rl.IsKeyPressed(.THREE) do evo_menu.selected_element = .EARTH
    if rl.IsKeyPressed(.FOUR)  do evo_menu.selected_element = .CHAOS
    if rl.IsKeyPressed(.FIVE)  do evo_menu.selected_element = .LIGHT

    if rl.IsKeyPressed(.E) || rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.BACKSPACE) {
        game.state = .BATTLE_AIMING
        return
    }

    elem := evo_menu.selected_element
    elem_idx := int(elem)
    cur_stage := game.card_stages[elem_idx]

    // Element Tabs Click Detection
    tab_w : f32 = 132.0
    tab_h : f32 = 46.0
    tab_y : f32 = 90.0
    for e in Element {
        idx := int(e)
        tx := 15.0 + f32(idx) * 140.0
        rect := rl.Rectangle{tx, tab_y, tab_w, tab_h}
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, rect) {
            evo_menu.selected_element = e
            return
        }
    }

    // EVOLVE Button
    btn_evolve_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) * 0.5 - 160.0, 930.0, 320.0, 60.0}
    if cur_stage < MAX_EVO_STAGES - 1 {
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_evolve_rect) {
            // Evolve!
            game.card_stages[elem_idx] += 1
            new_stage := game.card_stages[elem_idx]
            next_data := get_card_stage_data(elem, new_stage)

            evo_menu.ascend_anim_timer = 1.2
            evo_menu.ascend_banner = fmt.tprintf("%s ASCENDED!", strings.to_upper(next_data.name, context.temp_allocator))

            // Ascension VFX
            emit_burst([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 520.0}, element_primary_color(elem), rl.GOLD, 55)
            add_shockwave([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 520.0}, 120.0, rl.GOLD, 0.45)
            add_screen_shake(7.0, 0.25)
            return
        }
    }

    // RESET TO BASE Button (For testing)
    btn_reset_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) * 0.5 - 120.0, 1005.0, 240.0, 42.0}
    if cur_stage > 0 {
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_reset_rect) {
            game.card_stages[elem_idx] = 0
            emit_sparks([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 520.0}, rl.LIGHTGRAY, 20, 200.0)
            add_screen_shake(3.0, 0.1)
            return
        }
    }

    // RETURN TO DUNGEON Button
    btn_back_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) * 0.5 - 150.0, 1075.0, 300.0, 52.0}
    if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_back_rect) {
        game.state = .BATTLE_AIMING
        return
    }
}

draw_evolution_menu :: proc(time: f32) {
    // Dim background void
    rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{12, 10, 18, 250})

    elem := evo_menu.selected_element
    elem_idx := int(elem)
    cur_stage := game.card_stages[elem_idx]
    cur_data := get_card_stage_data(elem, cur_stage)

    elem_col1 := element_primary_color(elem)
    elem_col2 := element_secondary_color(elem)

    // --- Header Title ---
    header_rect := rl.Rectangle{0, 0, f32(VIRTUAL_WIDTH), 75}
    rl.DrawRectangleRec(header_rect, rl.Color{18, 14, 26, 255})
    rl.DrawRectangleLinesEx(header_rect, 2, current_theme.wall_trim)

    title_text : cstring : "ALTAR OF ASCENSION"
    tw := rl.MeasureText(title_text, 30)
    rl.DrawText(title_text, VIRTUAL_WIDTH / 2 - tw / 2, 22, 30, COLOR_TEXT_GOLD)

    // --- Element Navigation Tabs [1] - [5] ---
    tab_w : f32 = 132.0
    tab_h : f32 = 46.0
    tab_y : f32 = 90.0

    for e in Element {
        idx := int(e)
        tx := 15.0 + f32(idx) * 140.0
        rect := rl.Rectangle{tx, tab_y, tab_w, tab_h}
        is_sel := (e == elem)

        bg := is_sel ? rl.Color{32, 24, 44, 255} : rl.Color{18, 15, 24, 230}
        rl.DrawRectangleRounded(rect, 0.15, 4, bg)
        rl.DrawRectangleRoundedLinesEx(rect, 0.15, 4, is_sel ? 2.5 : 1.0, is_sel ? COLOR_TEXT_GOLD : current_theme.wall_border)

        // Tab label & hotkey
        t_name := element_name(e)
        t_label := fmt.tprintf("[%d] %s", idx + 1, strings.to_upper(t_name, context.temp_allocator))
        t_cstr := strings.clone_to_cstring(t_label)
        defer delete(t_cstr)
        lw := rl.MeasureText(t_cstr, 16)
        c := is_sel ? element_secondary_color(e) : rl.LIGHTGRAY
        rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(tab_y + 14), 16, c)
    }

    // --- Tier Stepper Progress Bar ---
    stepper_y : f32 = 160.0
    stepper_w : f32 = 520.0
    stepper_x : f32 = (f32(VIRTUAL_WIDTH) - stepper_w) * 0.5

    // Connecting line
    rl.DrawLineEx([2]f32{stepper_x, stepper_y}, [2]f32{stepper_x + stepper_w, stepper_y}, 3.0, current_theme.wall_border)

    for s in 0..<MAX_EVO_STAGES {
        sx := stepper_x + (f32(s) / 4.0) * stepper_w
        is_reached := (s <= cur_stage)
        is_active  := (s == cur_stage)

        node_r : f32 = is_active ? 16.0 : 12.0
        node_col := is_reached ? elem_col1 : rl.DARKGRAY
        if is_active do node_col = rl.GOLD

        rl.DrawCircleV([2]f32{sx, stepper_y}, node_r, node_col)
        rl.DrawCircleLinesV([2]f32{sx, stepper_y}, node_r + 2, is_active ? rl.WHITE : current_theme.wall_trim)

        roman_str := fmt.tprintf("%d", s + 1)
        r_cstr := strings.clone_to_cstring(roman_str)
        defer delete(r_cstr)
        rw := rl.MeasureText(r_cstr, 14)
        rl.DrawText(r_cstr, i32(sx) - rw / 2, i32(stepper_y) - 6, 14, is_reached ? rl.WHITE : rl.BLACK)
    }

    // --- Main Card Display Showcase ---
    if cur_stage < MAX_EVO_STAGES - 1 {
        // Dual Card Comparison Showcase: Current -> Next Evolved
        next_data := get_card_stage_data(elem, cur_stage + 1)

        card_w : f32 = 230.0
        card_h : f32 = 308.0

        // Current Card (Left)
        left_card_x : f32 = 90.0
        card_y : f32 = 210.0
        draw_card(
            rect       = rl.Rectangle{left_card_x, card_y, card_w, card_h},
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
            rect       = rl.Rectangle{right_card_x, card_y, card_w, card_h},
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

        // Middle Evolution Indicator Arrow & Particle Rune
        mid_x : f32 = f32(VIRTUAL_WIDTH) * 0.5
        arrow_pulse := math.sin(time * 5.0) * 0.2 + 0.8
        rl.DrawCircleV([2]f32{mid_x, card_y + card_h * 0.5}, 28.0 * arrow_pulse, rl.Color{elem_col2.r, elem_col2.g, elem_col2.b, 80})
        arrow_text : cstring : ">>>"
        aw := rl.MeasureText(arrow_text, 28)
        rl.DrawText(arrow_text, i32(mid_x) - aw / 2, i32(card_y + card_h * 0.5) - 14, 28, COLOR_TEXT_GOLD)

        // --- Stat Increase Banner ---
        stat_box_y : f32 = 540.0
        stat_rect := rl.Rectangle{80, stat_box_y, f32(VIRTUAL_WIDTH) - 160, 160}
        rl.DrawRectangleRounded(stat_rect, 0.12, 4, rl.Color{20, 16, 28, 240})
        rl.DrawRectangleRoundedLinesEx(stat_rect, 0.12, 4, 2.0, COLOR_TEXT_GOLD)

        // Power comparison
        p_text := rl.TextFormat("BASE HIT POWER:  %.0f%%  >>>  %.0f%% DMG", cur_data.power_mult * 100.0, next_data.power_mult * 100.0)
        pw := rl.MeasureText(p_text, 20)
        rl.DrawText(p_text, VIRTUAL_WIDTH / 2 - pw / 2, i32(stat_box_y + 18), 20, rl.GOLD)

        // Rarity comparison
        r_text := rl.TextFormat("RARITY:  %d STARS  >>>  %d STARS", cur_data.rarity, next_data.rarity)
        rw := rl.MeasureText(r_text, 18)
        rl.DrawText(r_text, VIRTUAL_WIDTH / 2 - rw / 2, i32(stat_box_y + 54), 18, rl.WHITE)

        // Epithet / Lore snippet
        desc_cstr := strings.clone_to_cstring(next_data.description)
        defer delete(desc_cstr)
        dw := rl.MeasureText(desc_cstr, 16)
        rl.DrawText(desc_cstr, VIRTUAL_WIDTH / 2 - dw / 2, i32(stat_box_y + 92), 16, elem_col2)

        p_gain := rl.TextFormat("+%.0f%% DAMAGE MULTIPLIER ON HIT!", (next_data.power_mult - cur_data.power_mult) * 100.0)
        pg_w := rl.MeasureText(p_gain, 17)
        rl.DrawText(p_gain, VIRTUAL_WIDTH / 2 - pg_w / 2, i32(stat_box_y + 125), 17, elem_col1)

    } else {
        // Supreme Goddess Final Form Showcase (Center)
        card_w : f32 = 300.0
        card_h : f32 = 400.0
        card_x : f32 = (f32(VIRTUAL_WIDTH) - card_w) * 0.5
        card_y : f32 = 200.0

        draw_card(
            rect       = rl.Rectangle{card_x, card_y, card_w, card_h},
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

        stat_box_y : f32 = 630.0
        stat_rect := rl.Rectangle{80, stat_box_y, f32(VIRTUAL_WIDTH) - 160, 110}
        rl.DrawRectangleRounded(stat_rect, 0.12, 4, rl.Color{24, 18, 32, 245})
        rl.DrawRectangleRoundedLinesEx(stat_rect, 0.12, 4, 2.5, rl.GOLD)

        max_title : cstring : "SUPREME GODDESS ASCENSION COMPLETE"
        mw := rl.MeasureText(max_title, 20)
        rl.DrawText(max_title, VIRTUAL_WIDTH / 2 - mw / 2, i32(stat_box_y + 18), 20, rl.GOLD)

        m_text := rl.TextFormat("500%% MAXIMUM DIVINE DAMAGE MULTIPLIER", cur_data.power_mult * 100.0)
        mtw := rl.MeasureText(m_text, 18)
        rl.DrawText(m_text, VIRTUAL_WIDTH / 2 - mtw / 2, i32(stat_box_y + 50), 18, rl.WHITE)

        desc_cstr := strings.clone_to_cstring(cur_data.description)
        defer delete(desc_cstr)
        dw := rl.MeasureText(desc_cstr, 15)
        rl.DrawText(desc_cstr, VIRTUAL_WIDTH / 2 - dw / 2, i32(stat_box_y + 80), 15, elem_col2)
    }

    // --- Interactive Action Buttons ---
    // 1. EVOLVE BUTTON
    if cur_stage < MAX_EVO_STAGES - 1 {
        btn_y : f32 = 930.0
        btn_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) * 0.5 - 160.0, btn_y, 320.0, 60.0}
        pulse := math.sin(time * 6.0) * 0.1 + 0.9

        rl.DrawRectangleRounded(btn_rect, 0.2, 4, rl.Color{40, 28, 52, 255})
        rl.DrawRectangleRoundedLinesEx(btn_rect, 0.2, 4, 3.0 * pulse, COLOR_TEXT_GOLD)

        evo_label := rl.TextFormat("ASCEND TO TIER %d >>>", cur_stage + 2)
        ew := rl.MeasureText(evo_label, 22)
        rl.DrawText(evo_label, VIRTUAL_WIDTH / 2 - ew / 2, i32(btn_y + 18), 22, rl.GOLD)
    }

    // 2. RESET TIER BUTTON
    if cur_stage > 0 {
        rbtn_y : f32 = 1005.0
        rbtn_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) * 0.5 - 120.0, rbtn_y, 240.0, 42.0}
        rl.DrawRectangleRounded(rbtn_rect, 0.2, 4, rl.Color{24, 18, 28, 220})
        rl.DrawRectangleRoundedLinesEx(rbtn_rect, 0.2, 4, 1.5, rl.GRAY)

        rst_text : cstring : "RESET TO TIER I"
        rw := rl.MeasureText(rst_text, 16)
        rl.DrawText(rst_text, VIRTUAL_WIDTH / 2 - rw / 2, i32(rbtn_y + 12), 16, rl.LIGHTGRAY)
    }

    // 3. RETURN TO DUNGEON BUTTON
    back_y : f32 = 1075.0
    back_rect := rl.Rectangle{f32(VIRTUAL_WIDTH) * 0.5 - 150.0, back_y, 300.0, 52.0}
    rl.DrawRectangleRounded(back_rect, 0.2, 4, rl.Color{18, 14, 24, 240})
    rl.DrawRectangleRoundedLinesEx(back_rect, 0.2, 4, 2.0, current_theme.wall_trim)

    back_text : cstring : "RETURN TO DUNGEON [ESC]"
    bw := rl.MeasureText(back_text, 18)
    rl.DrawText(back_text, VIRTUAL_WIDTH / 2 - bw / 2, i32(back_y + 16), 18, rl.WHITE)

    // Ascension Complete Popup Banner
    if evo_menu.ascend_anim_timer > 0.0 {
        b_alpha := math.clamp(evo_menu.ascend_anim_timer / 0.3, 0.0, 1.0)
        pop_rect := rl.Rectangle{0, 440, f32(VIRTUAL_WIDTH), 110}
        rl.DrawRectangleRec(pop_rect, rl.Color{22, 16, 32, u8(b_alpha * 240.0)})
        rl.DrawRectangleLinesEx(pop_rect, 3, rl.GOLD)

        top_t : cstring : "✦ DIVINE ASCENSION COMPLETE ✦"
        pop_tw := rl.MeasureText(top_t, 26)
        rl.DrawText(top_t, VIRTUAL_WIDTH / 2 - pop_tw / 2, 455, 26, rl.GOLD)

        sub_cstr := strings.clone_to_cstring(evo_menu.ascend_banner)
        defer delete(sub_cstr)
        sw := rl.MeasureText(sub_cstr, 22)
        rl.DrawText(sub_cstr, VIRTUAL_WIDTH / 2 - sw / 2, 495, 22, elem_col2)
    }
}
