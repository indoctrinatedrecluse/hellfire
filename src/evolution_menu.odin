package hellfire

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Evolution_Category :: enum {
    BASIC,
    DUAL,
}

Ascension_Anim_Phase :: enum {
    IDLE,
    CHARGING,
    BURST,
    REVELATION,
}

Evolution_Menu_State :: struct {
    category:          Evolution_Category,
    selected_element:  Element,
    anim_phase:        Ascension_Anim_Phase,
    anim_timer:        f32,
    anim_stage_from:   int,
    anim_stage_to:     int,
    ascend_banner:     string,
    card_zoom_inspect: bool,
    zoom_stage:        int,
}

evo_menu: Evolution_Menu_State

init_evolution_menu :: proc() {
    evo_menu.category = .BASIC
    evo_menu.selected_element = .FIRE
    evo_menu.anim_phase = .IDLE
    evo_menu.anim_timer = 0.0
    evo_menu.anim_stage_from = 0
    evo_menu.anim_stage_to = 0
    evo_menu.ascend_banner = ""
    evo_menu.card_zoom_inspect = false
    evo_menu.zoom_stage = 0
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

start_card_ascension :: proc(elem: Element, cur_stage: int) {
    if cur_stage >= MAX_EVO_STAGES - 1 do return

    evo_menu.anim_phase = .CHARGING
    evo_menu.anim_timer = 1.8 // 1.8s ritual sequence
    evo_menu.anim_stage_from = cur_stage
    evo_menu.anim_stage_to = cur_stage + 1

    next_data := get_card_stage_data(elem, cur_stage + 1)
    evo_menu.ascend_banner = fmt.tprintf("%s ASCENDED!", strings.to_upper(next_data.name, context.temp_allocator))

    mid_card_pos := [2]f32{f32(VIRTUAL_WIDTH) * 0.5, 460.0}
    emit_sparks(mid_card_pos, element_primary_color(elem), 35, 180.0)
    add_screen_shake(4.0, 0.35)
}

update_evolution_menu :: proc(dt: f32, mouse_pos: [2]f32, mouse_pressed: bool) {
    elem := evo_menu.selected_element
    elem_idx := int(elem)
    cur_stage := game.card_stages[elem_idx]

    // --- Ascension Animation Sequence Update ---
    if evo_menu.anim_timer > 0.0 {
        evo_menu.anim_timer -= dt

        // Transition from CHARGING (1.8s -> 1.4s) to BURST (1.4s)
        if evo_menu.anim_phase == .CHARGING && evo_menu.anim_timer <= 1.4 {
            evo_menu.anim_phase = .BURST

            game.card_stages[elem_idx] = evo_menu.anim_stage_to

            mid_card_pos := [2]f32{f32(VIRTUAL_WIDTH) * 0.5, 460.0}
            emit_burst(mid_card_pos, element_primary_color(elem), rl.GOLD, 85)
            add_shockwave(mid_card_pos, 220.0, rl.GOLD, 0.5)
            add_shockwave(mid_card_pos, 160.0, element_secondary_color(elem), 0.4)
            add_screen_shake(10.0, 0.4)
        } else if evo_menu.anim_phase == .BURST && evo_menu.anim_timer <= 1.25 {
            evo_menu.anim_phase = .REVELATION
        }

        if evo_menu.anim_timer <= 0.0 {
            evo_menu.anim_phase = .IDLE
            evo_menu.anim_timer = 0.0
        }
    }

    // --- Full-Screen Card Zoom / Inspection Dismissal ---
    if evo_menu.card_zoom_inspect {
        if mouse_pressed || rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.E) || rl.IsKeyPressed(.ENTER) {
            evo_menu.card_zoom_inspect = false
            return
        }
        return
    }

    // --- [ESC] or [E] to Return to Dungeon (Smooth, never closes window) ---
    if rl.IsKeyPressed(.ESCAPE) || rl.IsKeyPressed(.E) || rl.IsKeyPressed(.BACKSPACE) {
        game.state = .BATTLE_AIMING
        return
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

    // Keyboard Shortcuts [1-5]
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

    // [6] and [7] directly select active floor dual cards
    if rl.IsKeyPressed(.SIX) {
        evo_menu.category = .DUAL
        evo_menu.selected_element = game.active_floor_duals[0]
    }
    if rl.IsKeyPressed(.SEVEN) {
        evo_menu.category = .DUAL
        evo_menu.selected_element = game.active_floor_duals[1]
    }

    // [SPACE] or [ENTER] to Trigger Ascension
    if (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER)) && cur_stage < MAX_EVO_STAGES - 1 && evo_menu.anim_phase == .IDLE {
        start_card_ascension(elem, cur_stage)
        return
    }

    // [R] to Reset
    if rl.IsKeyPressed(.R) && cur_stage > 0 && evo_menu.anim_phase == .IDLE {
        game.card_stages[elem_idx] = 0
        emit_sparks([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 460.0}, rl.LIGHTGRAY, 25, 200.0)
        add_screen_shake(3.0, 0.1)
        return
    }

    // --- Mouse Click Detections ---
    // 1. Category Switcher Clicks
    cat_basic_rect := rl.Rectangle{20.0, 58.0, 334.0, 34.0}
    cat_dual_rect  := rl.Rectangle{366.0, 58.0, 334.0, 34.0}
    if mouse_pressed {
        if rl.CheckCollisionPointRec(mouse_pos, cat_basic_rect) {
            evo_menu.category = .BASIC
            if is_dual_element(evo_menu.selected_element) do evo_menu.selected_element = .FIRE
            return
        }
        if rl.CheckCollisionPointRec(mouse_pos, cat_dual_rect) {
            evo_menu.category = .DUAL
            if !is_dual_element(evo_menu.selected_element) do evo_menu.selected_element = game.active_floor_duals[0]
            return
        }
    }

    // 2. Element Tabs Click Detection
    if evo_menu.category == .BASIC {
        tab_w : f32 = 134.0
        tab_h : f32 = 36.0
        tab_y : f32 = 96.0
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
        tab_w : f32 = 134.0
        tab_h : f32 = 28.0
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 96.0, tab_w, tab_h}
            if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, rect) {
                evo_menu.selected_element = e
                return
            }
        }
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + 5 + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 126.0, tab_w, tab_h}
            if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, rect) {
                evo_menu.selected_element = e
                return
            }
        }
    }

    // 3. Card Clicks for Full-Screen Inspection Zoom
    card_w : f32 = 324.0
    card_h : f32 = 440.0
    left_card_rect := rl.Rectangle{22.0, 246.0, card_w, card_h}
    right_card_rect := rl.Rectangle{374.0, 246.0, card_w, card_h}
    if cur_stage >= MAX_EVO_STAGES - 1 {
        left_card_rect = rl.Rectangle{140.0, 236.0, 440.0, 580.0}
    }

    if mouse_pressed && evo_menu.anim_phase == .IDLE {
        if rl.CheckCollisionPointRec(mouse_pos, left_card_rect) {
            evo_menu.card_zoom_inspect = true
            evo_menu.zoom_stage = cur_stage
            return
        }
        if cur_stage < MAX_EVO_STAGES - 1 && rl.CheckCollisionPointRec(mouse_pos, right_card_rect) {
            evo_menu.card_zoom_inspect = true
            evo_menu.zoom_stage = cur_stage + 1
            return
        }
    }

    // 4. EVOLVE Button Click (Y: 935)
    btn_evolve_rect := rl.Rectangle{150.0, 935.0, 420.0, 64.0}
    if cur_stage < MAX_EVO_STAGES - 1 && evo_menu.anim_phase == .IDLE {
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_evolve_rect) {
            start_card_ascension(elem, cur_stage)
            return
        }
    }

    // 5. RESET Button Click (Y: 1018)
    btn_reset_rect := rl.Rectangle{210.0, 1018.0, 300.0, 42.0}
    if cur_stage > 0 && evo_menu.anim_phase == .IDLE {
        if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_reset_rect) {
            game.card_stages[elem_idx] = 0
            emit_sparks([2]f32{f32(VIRTUAL_WIDTH) * 0.5, 460.0}, rl.LIGHTGRAY, 25, 200.0)
            add_screen_shake(3.0, 0.1)
            return
        }
    }

    // 6. RETURN TO DUNGEON Button Click (Y: 1080)
    btn_back_rect := rl.Rectangle{190.0, 1080.0, 340.0, 52.0}
    if mouse_pressed && rl.CheckCollisionPointRec(mouse_pos, btn_back_rect) {
        game.state = .BATTLE_AIMING
        return
    }
}

draw_evolution_menu :: proc(time: f32) {
    // Deep dark void background
    rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{10, 8, 16, 252})

    elem := evo_menu.selected_element
    elem_idx := int(elem)
    cur_stage := game.card_stages[elem_idx]
    cur_data := get_card_stage_data(elem, cur_stage)

    elem_col1 := element_primary_color(elem)
    elem_col2 := element_secondary_color(elem)
    is_dual := is_dual_element(elem)

    // --- Header Title (Clean ASCII, no question marks) ---
    header_rect := rl.Rectangle{0, 0, f32(VIRTUAL_WIDTH), 52}
    rl.DrawRectangleRec(header_rect, rl.Color{16, 12, 24, 255})
    rl.DrawRectangleLinesEx(header_rect, 2, current_theme.wall_trim)

    title_text : cstring : "== ALTAR OF ASCENSION =="
    tw := rl.MeasureText(title_text, 26)
    rl.DrawText(title_text, VIRTUAL_WIDTH / 2 - tw / 2, 14, 26, COLOR_TEXT_GOLD)

    // --- Category Selector Tabs ---
    cat_basic_rect := rl.Rectangle{20.0, 58.0, 334.0, 34.0}
    cat_dual_rect  := rl.Rectangle{366.0, 58.0, 334.0, 34.0}

    is_cat_basic := (evo_menu.category == .BASIC)
    b_bg := is_cat_basic ? rl.Color{42, 30, 58, 255} : rl.Color{16, 14, 22, 220}
    d_bg := !is_cat_basic ? rl.Color{42, 30, 58, 255} : rl.Color{16, 14, 22, 220}

    rl.DrawRectangleRounded(cat_basic_rect, 0.18, 4, b_bg)
    rl.DrawRectangleRoundedLinesEx(cat_basic_rect, 0.18, 4, is_cat_basic ? 2.5 : 1.0, is_cat_basic ? COLOR_TEXT_GOLD : current_theme.wall_border)

    rl.DrawRectangleRounded(cat_dual_rect, 0.18, 4, d_bg)
    rl.DrawRectangleRoundedLinesEx(cat_dual_rect, 0.18, 4, !is_cat_basic ? 2.5 : 1.0, !is_cat_basic ? COLOR_TEXT_GOLD : current_theme.wall_border)

    cat_b_text : cstring : "[TAB] BASIC CARDS (5)"
    cb_w := rl.MeasureText(cat_b_text, 16)
    rl.DrawText(cat_b_text, i32(cat_basic_rect.x + cat_basic_rect.width * 0.5) - cb_w / 2, i32(cat_basic_rect.y + 9), 16, is_cat_basic ? rl.GOLD : rl.GRAY)

    cat_d_text : cstring : "[TAB] DUAL COMPOUND (10) [1.5x]"
    cd_w := rl.MeasureText(cat_d_text, 16)
    rl.DrawText(cat_d_text, i32(cat_dual_rect.x + cat_dual_rect.width * 0.5) - cd_w / 2, i32(cat_dual_rect.y + 9), 16, !is_cat_basic ? rl.GOLD : rl.GRAY)

    // --- Element Selection Tabs ---
    if evo_menu.category == .BASIC {
        tab_w : f32 = 134.0
        tab_h : f32 = 36.0
        tab_y : f32 = 96.0

        for i in 0..<5 {
            e := Element(i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, tab_y, tab_w, tab_h}
            is_sel := (e == elem)

            bg := is_sel ? rl.Color{46, 34, 64, 255} : rl.Color{18, 15, 24, 230}
            rl.DrawRectangleRounded(rect, 0.16, 4, bg)
            rl.DrawRectangleRoundedLinesEx(rect, 0.16, 4, is_sel ? 2.5 : 1.0, is_sel ? COLOR_TEXT_GOLD : current_theme.wall_border)

            t_name := element_name(e)
            t_label := fmt.tprintf("[%d] %s", i + 1, strings.to_upper(t_name, context.temp_allocator))
            t_cstr := strings.clone_to_cstring(t_label)
            defer delete(t_cstr)
            lw := rl.MeasureText(t_cstr, 14)
            c := is_sel ? element_secondary_color(e) : rl.LIGHTGRAY
            rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(tab_y + 10), 14, c)
        }
    } else {
        tab_w : f32 = 134.0
        tab_h : f32 = 28.0

        // Row 1: Steam, Magma, Netherflame, Solar, Mire
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 96.0, tab_w, tab_h}
            is_sel := (e == elem)
            is_floor := (e == game.active_floor_duals[0] || e == game.active_floor_duals[1])

            bg := is_sel ? rl.Color{46, 34, 64, 255} : rl.Color{18, 15, 24, 230}
            rl.DrawRectangleRounded(rect, 0.16, 4, bg)

            border_c := current_theme.wall_border
            if is_floor do border_c = rl.GOLD
            if is_sel   do border_c = rl.Color{255, 230, 120, 255}
            rl.DrawRectangleRoundedLinesEx(rect, 0.16, 4, is_sel ? 2.5 : (is_floor ? 1.8 : 1.0), border_c)

            t_name := element_name(e)
            t_label := is_floor ? fmt.tprintf("* %s *", strings.to_upper(t_name, context.temp_allocator)) : strings.to_upper(t_name, context.temp_allocator)
            t_cstr := strings.clone_to_cstring(t_label)
            defer delete(t_cstr)
            lw := rl.MeasureText(t_cstr, 13)
            c := is_sel ? element_secondary_color(e) : (is_floor ? rl.GOLD : rl.LIGHTGRAY)
            rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(96.0 + 7), 13, c)
        }

        // Row 2: Abyss, Glacier, Obsidian, Crystal, Eclipse
        for i in 0..<5 {
            e := Element(DUAL_ELEMENT_START + 5 + i)
            tx := 20.0 + f32(i) * 138.0
            rect := rl.Rectangle{tx, 126.0, tab_w, tab_h}
            is_sel := (e == elem)
            is_floor := (e == game.active_floor_duals[0] || e == game.active_floor_duals[1])

            bg := is_sel ? rl.Color{46, 34, 64, 255} : rl.Color{18, 15, 24, 230}
            rl.DrawRectangleRounded(rect, 0.16, 4, bg)

            border_c := current_theme.wall_border
            if is_floor do border_c = rl.GOLD
            if is_sel   do border_c = rl.Color{255, 230, 120, 255}
            rl.DrawRectangleRoundedLinesEx(rect, 0.16, 4, is_sel ? 2.5 : (is_floor ? 1.8 : 1.0), border_c)

            t_name := element_name(e)
            t_label := is_floor ? fmt.tprintf("* %s *", strings.to_upper(t_name, context.temp_allocator)) : strings.to_upper(t_name, context.temp_allocator)
            t_cstr := strings.clone_to_cstring(t_label)
            defer delete(t_cstr)
            lw := rl.MeasureText(t_cstr, 13)
            c := is_sel ? element_secondary_color(e) : (is_floor ? rl.GOLD : rl.LIGHTGRAY)
            rl.DrawText(t_cstr, i32(tx + tab_w * 0.5) - lw / 2, i32(126.0 + 7), 13, c)
        }
    }

    // --- Formula & Floor Manifestation Banner ---
    banner_y : f32 = (evo_menu.category == .BASIC) ? 140.0 : 160.0
    banner_rect := rl.Rectangle{26.0, banner_y, f32(VIRTUAL_WIDTH) - 52.0, 26.0}
    rl.DrawRectangleRounded(banner_rect, 0.2, 4, rl.Color{18, 14, 26, 230})
    rl.DrawRectangleRoundedLinesEx(banner_rect, 0.2, 4, 1.2, is_dual ? elem_col2 : current_theme.wall_border)

    if is_dual {
        p1, p2 := get_element_parents(elem)
        p1_name := strings.to_upper(element_name(p1), context.temp_allocator)
        p2_name := strings.to_upper(element_name(p2), context.temp_allocator)
        elem_n  := strings.to_upper(element_name(elem), context.temp_allocator)

        is_floor := (elem == game.active_floor_duals[0] || elem == game.active_floor_duals[1])
        slot_label := (elem == game.active_floor_duals[0]) ? "DECK SLOT [6]" : "DECK SLOT [7]"

        f_label: string
        if is_floor {
            f_label = fmt.tprintf("COMPOUND: [%s] + [%s] = %s (1.5x POWER)  |  * ACTIVE ON FLOOR: %s *", p1_name, p2_name, elem_n, slot_label)
        } else {
            f_label = fmt.tprintf("COMPOUND: [%s] + [%s] = %s (1.5x POWER)  |  * DORMANT IN THIS CHAMBER *", p1_name, p2_name, elem_n)
        }
        f_cstr := strings.clone_to_cstring(f_label)
        defer delete(f_cstr)
        fw := rl.MeasureText(f_cstr, 13)
        rl.DrawText(f_cstr, VIRTUAL_WIDTH / 2 - fw / 2, i32(banner_y + 6), 13, is_floor ? rl.GOLD : elem_col2)
    } else {
        b_label := fmt.tprintf("PRIME ELEMENT: %s  |  PERMANENT DECK SLOTS [1-5]  |  PRESS [TAB] FOR DUALS", strings.to_upper(element_name(elem), context.temp_allocator))
        b_cstr := strings.clone_to_cstring(b_label)
        defer delete(b_cstr)
        bw := rl.MeasureText(b_cstr, 13)
        rl.DrawText(b_cstr, VIRTUAL_WIDTH / 2 - bw / 2, i32(banner_y + 6), 13, elem_col2)
    }

    // --- Progression Stepper Bar ---
    stepper_y : f32 = banner_y + 34.0
    stepper_w : f32 = 480.0
    stepper_x : f32 = (f32(VIRTUAL_WIDTH) - stepper_w) * 0.5

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

    // --- High-Visibility Cards Showcase (Huge 324x440 cards!) ---
    card_start_y : f32 = stepper_y + 20.0

    if cur_stage < MAX_EVO_STAGES - 1 {
        next_data := get_card_stage_data(elem, cur_stage + 1)

        card_w : f32 = 324.0
        card_h : f32 = 440.0

        hover_y := math.sin(time * 3.5) * 4.0

        // 1. Current Card (Left)
        left_card_x : f32 = 22.0
        rl.DrawText(rl.TextFormat("CURRENT: TIER %d", cur_stage + 1), i32(left_card_x + card_w * 0.5) - 65, i32(card_start_y - 18), 15, rl.LIGHTGRAY)
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

        // 2. Next Evolved Card (Right)
        right_card_x : f32 = 374.0
        rl.DrawText(rl.TextFormat("* PREVIEW: TIER %d *", cur_stage + 2), i32(right_card_x + card_w * 0.5) - 80, i32(card_start_y - 18 + hover_y * 0.5), 15, rl.GOLD)
        draw_card(
            rect       = rl.Rectangle{right_card_x, card_start_y + hover_y, card_w, card_h},
            elem       = elem,
            name       = next_data.name,
            rarity     = next_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = true,
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = cur_stage + 1,
        )

        // Middle Arrow & Circle
        mid_x : f32 = f32(VIRTUAL_WIDTH) * 0.5
        arrow_y : f32 = card_start_y + card_h * 0.5
        arrow_pulse := math.sin(time * 6.0) * 0.2 + 0.8
        rl.DrawCircleV([2]f32{mid_x, arrow_y}, 26.0 * arrow_pulse, rl.Color{elem_col2.r, elem_col2.g, elem_col2.b, 80})
        rl.DrawCircleLinesV([2]f32{mid_x, arrow_y}, 30.0 * arrow_pulse, COLOR_TEXT_GOLD)
        arrow_text : cstring : ">>"
        aw := rl.MeasureText(arrow_text, 24)
        rl.DrawText(arrow_text, i32(mid_x) - aw / 2, i32(arrow_y) - 12, 24, COLOR_TEXT_GOLD)

        // Inspection Hint
        hint_text : cstring : "[Click card to inspect full-screen]"
        hw := rl.MeasureText(hint_text, 13)
        rl.DrawText(hint_text, VIRTUAL_WIDTH / 2 - hw / 2, i32(card_start_y + card_h + 6), 13, rl.DARKGRAY)

        // --- Divine Ascension Codex (Spacious, bold, highly readable!) ---
        codex_y : f32 = card_start_y + card_h + 24.0
        codex_rect := rl.Rectangle{22.0, codex_y, f32(VIRTUAL_WIDTH) - 44.0, 190.0}
        rl.DrawRectangleRounded(codex_rect, 0.10, 4, rl.Color{18, 14, 26, 245})
        rl.DrawRectangleRoundedLinesEx(codex_rect, 0.10, 4, 2.0, COLOR_TEXT_GOLD)

        // Row 1: Title & Epithet (Bold 24px Gold)
        title_str := fmt.tprintf("%s  --  %s", strings.to_upper(next_data.name, context.temp_allocator), next_data.epithet)
        t_cstr := strings.clone_to_cstring(title_str)
        defer delete(t_cstr)
        tw_bold := rl.MeasureText(t_cstr, 24)
        rl.DrawText(t_cstr, VIRTUAL_WIDTH / 2 - tw_bold / 2, i32(codex_y + 14), 24, rl.GOLD)

        // Row 2: Power Transformation Banner (Bright 20px)
        p_str := fmt.tprintf("BASE HIT POWER:  %.0f%%  >>>  %.0f%% DMG  (+%.0f%% BOOST!)", cur_data.power_mult * 100.0, next_data.power_mult * 100.0, (next_data.power_mult - cur_data.power_mult) * 100.0)
        p_cstr := strings.clone_to_cstring(p_str)
        defer delete(p_cstr)
        pw := rl.MeasureText(p_cstr, 20)
        rl.DrawText(p_cstr, VIRTUAL_WIDTH / 2 - pw / 2, i32(codex_y + 50), 20, rl.WHITE)

        // Row 3: Lore Description (Crisp 17px)
        desc_cstr := strings.clone_to_cstring(next_data.description)
        defer delete(desc_cstr)
        dw := rl.MeasureText(desc_cstr, 17)
        rl.DrawText(desc_cstr, VIRTUAL_WIDTH / 2 - dw / 2, i32(codex_y + 86), 17, elem_col2)

        // Row 4: Elemental Synergy & Battle Advantage
        if is_dual {
            p1, p2 := get_element_parents(elem)
            syn_str := fmt.tprintf("AFFINITY: Combines %s & %s (Super Effective: 1.85x against their targets!)", element_name(p1), element_name(p2))
            s_cstr := strings.clone_to_cstring(syn_str)
            defer delete(s_cstr)
            sw := rl.MeasureText(s_cstr, 16)
            rl.DrawText(s_cstr, VIRTUAL_WIDTH / 2 - sw / 2, i32(codex_y + 122), 16, rl.RAYWHITE)
        } else {
            adv_target := basic_advantage_target(elem)
            adv_str := fmt.tprintf("AFFINITY: %s is Super Effective against %s (1.85x Damage Multiplier)", element_name(elem), adv_target)
            a_cstr := strings.clone_to_cstring(adv_str)
            defer delete(a_cstr)
            aw_adv := rl.MeasureText(a_cstr, 16)
            rl.DrawText(a_cstr, VIRTUAL_WIDTH / 2 - aw_adv / 2, i32(codex_y + 122), 16, rl.RAYWHITE)
        }

        // Row 5: Rarity Progression
        r_str := fmt.tprintf("RARITY: %d Stars  >>>  %d Stars", cur_data.rarity, next_data.rarity)
        r_cstr := strings.clone_to_cstring(r_str)
        defer delete(r_cstr)
        rw := rl.MeasureText(r_cstr, 16)
        rl.DrawText(r_cstr, VIRTUAL_WIDTH / 2 - rw / 2, i32(codex_y + 154), 16, rl.GOLD)

    } else {
        // Supreme Goddess Final Form Showcase (Massive 440x580 Card!)
        card_w : f32 = 440.0
        card_h : f32 = 580.0
        card_x : f32 = (f32(VIRTUAL_WIDTH) - card_w) * 0.5

        draw_card(
            rect       = rl.Rectangle{card_x, card_start_y - 10.0, card_w, card_h},
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

        hint_text : cstring : "[Click card to inspect full-screen]"
        hw := rl.MeasureText(hint_text, 13)
        rl.DrawText(hint_text, VIRTUAL_WIDTH / 2 - hw / 2, i32(card_start_y + card_h - 2), 13, rl.DARKGRAY)

        codex_y : f32 = card_start_y + card_h + 16.0
        codex_rect := rl.Rectangle{22.0, codex_y, f32(VIRTUAL_WIDTH) - 44.0, 140.0}
        rl.DrawRectangleRounded(codex_rect, 0.10, 4, rl.Color{24, 18, 34, 250})
        rl.DrawRectangleRoundedLinesEx(codex_rect, 0.10, 4, 2.5, rl.GOLD)

        max_title : cstring : "* SUPREME GODDESS ASCENSION COMPLETE *"
        mw := rl.MeasureText(max_title, 24)
        rl.DrawText(max_title, VIRTUAL_WIDTH / 2 - mw / 2, i32(codex_y + 16), 24, rl.GOLD)

        m_text := rl.TextFormat("%.0f%% MAXIMUM DIVINE DAMAGE MULTIPLIER", cur_data.power_mult * 100.0)
        mtw := rl.MeasureText(m_text, 22)
        rl.DrawText(m_text, VIRTUAL_WIDTH / 2 - mtw / 2, i32(codex_y + 54), 22, rl.WHITE)

        desc_cstr := strings.clone_to_cstring(cur_data.description)
        defer delete(desc_cstr)
        dw := rl.MeasureText(desc_cstr, 17)
        rl.DrawText(desc_cstr, VIRTUAL_WIDTH / 2 - dw / 2, i32(codex_y + 90), 17, elem_col2)
    }

    // --- Interactive Action Buttons (Using the lower canvas gracefully!) ---
    // 1. Primary ASCEND Button (Y: 935)
    if cur_stage < MAX_EVO_STAGES - 1 {
        btn_y : f32 = 935.0
        btn_rect := rl.Rectangle{150.0, btn_y, 420.0, 64.0}
        pulse := math.sin(time * 6.0) * 0.1 + 0.9

        rl.DrawRectangleRounded(btn_rect, 0.2, 4, rl.Color{48, 30, 64, 255})
        rl.DrawRectangleRoundedLinesEx(btn_rect, 0.2, 4, 3.0 * pulse, COLOR_TEXT_GOLD)

        evo_label := rl.TextFormat("[SPACE] ASCEND TO TIER %d >>>", cur_stage + 2)
        ev_w := rl.MeasureText(evo_label, 24)
        rl.DrawText(evo_label, VIRTUAL_WIDTH / 2 - ev_w / 2, i32(btn_y + 20), 24, rl.GOLD)
    }

    // 2. RESET Button (Y: 1018)
    if cur_stage > 0 {
        rbtn_y : f32 = 1018.0
        rbtn_rect := rl.Rectangle{210.0, rbtn_y, 300.0, 42.0}
        rl.DrawRectangleRounded(rbtn_rect, 0.2, 4, rl.Color{24, 18, 28, 220})
        rl.DrawRectangleRoundedLinesEx(rbtn_rect, 0.2, 4, 1.2, rl.GRAY)

        rst_text : cstring : "[R] RESET TO TIER I"
        rw := rl.MeasureText(rst_text, 16)
        rl.DrawText(rst_text, VIRTUAL_WIDTH / 2 - rw / 2, i32(rbtn_y + 12), 16, rl.LIGHTGRAY)
    }

    // 3. RETURN TO DUNGEON Button (Y: 1080)
    back_y : f32 = 1080.0
    back_rect := rl.Rectangle{190.0, back_y, 340.0, 52.0}
    rl.DrawRectangleRounded(back_rect, 0.2, 4, rl.Color{18, 14, 24, 240})
    rl.DrawRectangleRoundedLinesEx(back_rect, 0.2, 4, 2.0, current_theme.wall_trim)

    back_text : cstring : "[ESC] RETURN TO DUNGEON"
    bw := rl.MeasureText(back_text, 18)
    rl.DrawText(back_text, VIRTUAL_WIDTH / 2 - bw / 2, i32(back_y + 16), 18, rl.WHITE)

    // --- Dynamic Ascension Animation Sequence Overlay ---
    if evo_menu.anim_phase != .IDLE {
        card_center := [2]f32{f32(VIRTUAL_WIDTH) * 0.5, 460.0}

        if evo_menu.anim_phase == .CHARGING {
            charge_pct := (1.8 - evo_menu.anim_timer) / 0.4
            vortex_r := (1.0 - charge_pct) * 240.0 + 50.0
            spin := time * 8.0

            rl.DrawCircleLinesV(card_center, vortex_r, elem_col1)
            rl.DrawCircleLinesV(card_center, vortex_r * 0.7, rl.GOLD)

            for i in 0..<8 {
                ang := spin + f32(i) * (math.PI * 2.0 / 8.0)
                p_start := [2]f32{card_center.x + math.cos(ang) * vortex_r, card_center.y + math.sin(ang) * vortex_r}
                rl.DrawLineEx(p_start, card_center, 3.0, rl.Color{elem_col2.r, elem_col2.g, elem_col2.b, 180})
            }
        }

        if evo_menu.anim_phase == .BURST || evo_menu.anim_phase == .REVELATION {
            flash_alpha := math.clamp((evo_menu.anim_timer - 1.2) / 0.2, 0.0, 1.0)
            if flash_alpha > 0.0 {
                rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{255, 245, 200, u8(flash_alpha * 200.0)})
            }

            banner_alpha := math.clamp(evo_menu.anim_timer / 0.4, 0.0, 1.0)
            pop_rect := rl.Rectangle{0, 410, f32(VIRTUAL_WIDTH), 135}
            rl.DrawRectangleRec(pop_rect, rl.Color{16, 10, 24, u8(banner_alpha * 245.0)})
            rl.DrawRectangleLinesEx(pop_rect, 3, rl.GOLD)

            top_t : cstring : "* DIVINE ASCENSION COMPLETE *"
            pop_tw := rl.MeasureText(top_t, 28)
            rl.DrawText(top_t, VIRTUAL_WIDTH / 2 - pop_tw / 2, 425, 28, rl.GOLD)

            sub_cstr := strings.clone_to_cstring(evo_menu.ascend_banner)
            defer delete(sub_cstr)
            sw := rl.MeasureText(sub_cstr, 24)
            rl.DrawText(sub_cstr, VIRTUAL_WIDTH / 2 - sw / 2, 462, 24, elem_col2)

            next_data := get_card_stage_data(elem, game.card_stages[elem_idx])
            boost_t := rl.TextFormat("POWER MULTIPLIER BOOSTED TO %.0f%% DMG!", next_data.power_mult * 100.0)
            btw := rl.MeasureText(boost_t, 20)
            rl.DrawText(boost_t, VIRTUAL_WIDTH / 2 - btw / 2, 500, 20, rl.RAYWHITE)
        }
    }

    // --- Full-Screen Card Inspection Modal (Encompassing most of the screen: 580x780!) ---
    if evo_menu.card_zoom_inspect {
        // Dim background veil
        rl.DrawRectangle(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, rl.Color{5, 4, 8, 248})

        zoom_data := get_card_stage_data(elem, evo_menu.zoom_stage)
        zoom_w : f32 = 580.0
        zoom_h : f32 = 780.0
        zoom_x : f32 = (f32(VIRTUAL_WIDTH) - zoom_w) * 0.5
        zoom_y : f32 = 45.0

        draw_card(
            rect       = rl.Rectangle{zoom_x, zoom_y, zoom_w, zoom_h},
            elem       = elem,
            name       = zoom_data.name,
            rarity     = zoom_data.rarity,
            hp_cur     = 100,
            hp_max     = 100,
            selected   = true,
            hurt_flash = false,
            is_monster = false,
            time       = time,
            stage      = evo_menu.zoom_stage,
        )

        // Modal Description Box below zoomed card
        m_box_y : f32 = zoom_y + zoom_h + 20.0
        m_box_rect := rl.Rectangle{26.0, m_box_y, f32(VIRTUAL_WIDTH) - 52.0, 220.0}
        rl.DrawRectangleRounded(m_box_rect, 0.12, 4, rl.Color{20, 16, 28, 250})
        rl.DrawRectangleRoundedLinesEx(m_box_rect, 0.12, 4, 2.5, rl.GOLD)

        m_title := fmt.tprintf("%s  --  %s", strings.to_upper(zoom_data.name, context.temp_allocator), zoom_data.epithet)
        mt_cstr := strings.clone_to_cstring(m_title)
        defer delete(mt_cstr)
        mtw := rl.MeasureText(mt_cstr, 24)
        rl.DrawText(mt_cstr, VIRTUAL_WIDTH / 2 - mtw / 2, i32(m_box_y + 16), 24, rl.GOLD)

        m_pwr := rl.TextFormat("TIER %d  |  BASE HIT POWER: %.0f%% DMG  |  %d STARS", evo_menu.zoom_stage + 1, zoom_data.power_mult * 100.0, zoom_data.rarity)
        mpw := rl.MeasureText(m_pwr, 20)
        rl.DrawText(m_pwr, VIRTUAL_WIDTH / 2 - mpw / 2, i32(m_box_y + 54), 20, rl.WHITE)

        z_desc_cstr := strings.clone_to_cstring(zoom_data.description)
        defer delete(z_desc_cstr)
        zdw := rl.MeasureText(z_desc_cstr, 17)
        rl.DrawText(z_desc_cstr, VIRTUAL_WIDTH / 2 - zdw / 2, i32(m_box_y + 92), 17, elem_col2)

        if is_dual {
            p1, p2 := get_element_parents(elem)
            syn_str := fmt.tprintf("DUAL SYNERGY: Combines %s & %s (Super Effective: 1.85x Damage)", element_name(p1), element_name(p2))
            s_cstr := strings.clone_to_cstring(syn_str)
            defer delete(s_cstr)
            sw := rl.MeasureText(s_cstr, 16)
            rl.DrawText(s_cstr, VIRTUAL_WIDTH / 2 - sw / 2, i32(m_box_y + 128), 16, rl.RAYWHITE)
        } else {
            adv_target := basic_advantage_target(elem)
            adv_str := fmt.tprintf("AFFINITY: %s is Super Effective against %s (1.85x Damage)", element_name(elem), adv_target)
            a_cstr := strings.clone_to_cstring(adv_str)
            defer delete(a_cstr)
            aw_adv := rl.MeasureText(a_cstr, 16)
            rl.DrawText(a_cstr, VIRTUAL_WIDTH / 2 - aw_adv / 2, i32(m_box_y + 128), 16, rl.RAYWHITE)
        }

        dismiss_hint : cstring : "[CLICK ANYWHERE OR PRESS ESC TO CLOSE INSPECTION]"
        dhw := rl.MeasureText(dismiss_hint, 16)
        rl.DrawText(dismiss_hint, VIRTUAL_WIDTH / 2 - dhw / 2, i32(m_box_y + 175), 16, rl.GOLD)
    }
}
