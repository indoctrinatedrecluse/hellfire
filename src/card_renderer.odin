package hellfire

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Card_Stage_Textures :: [MAX_EVO_STAGES]rl.Texture2D

card_textures: [TOTAL_ELEMENTS]rl.Texture2D
evo_textures:  [TOTAL_ELEMENTS]Card_Stage_Textures
card_textures_loaded: bool

load_card_texture :: proc(filename: cstring) -> rl.Texture2D {
    // Try directly from working directory
    if rl.FileExists(filename) {
        tex := rl.LoadTexture(filename)
        if tex.id > 0 {
            rl.SetTextureFilter(tex, .BILINEAR)
            return tex
        }
    }

    // Try relative to parent (if running from bin/)
    parent_path := fmt.ctprintf("../%s", filename)
    if rl.FileExists(parent_path) {
        tex := rl.LoadTexture(parent_path)
        if tex.id > 0 {
            rl.SetTextureFilter(tex, .BILINEAR)
            return tex
        }
    }

    // Try inside bin/ directory
    bin_path := fmt.ctprintf("bin/%s", filename)
    if rl.FileExists(bin_path) {
        tex := rl.LoadTexture(bin_path)
        if tex.id > 0 {
            rl.SetTextureFilter(tex, .BILINEAR)
            return tex
        }
    }

    return rl.Texture2D{}
}

load_stage_texture :: proc(elem_name: string, s: int) -> rl.Texture2D {
    // 1. Try 1-based stage filename: e.g. card_fire_stage_2.png for Tier II (s=1)
    p_1based := fmt.ctprintf("assets/cards/card_%s_stage_%d.png", elem_name, s + 1)
    tex := load_card_texture(p_1based)
    if tex.id > 0 do return tex

    // 2. Try 0-based stage filename: e.g. card_fire_stage_1.png for Tier II (s=1)
    p_0based := fmt.ctprintf("assets/cards/card_%s_stage_%d.png", elem_name, s)
    tex = load_card_texture(p_0based)
    if tex.id > 0 do return tex

    // 3. For Tier I (s=0), try base card filename
    if s == 0 {
        p_base := fmt.ctprintf("assets/cards/card_%s.png", elem_name)
        tex = load_card_texture(p_base)
        if tex.id > 0 do return tex
    }

    return rl.Texture2D{}
}

init_card_textures :: proc() {
    loaded_count := 0

    for elem in Element {
        idx := int(elem)
        e_name := strings.to_lower(element_name(elem), context.temp_allocator)

        // Load base texture if available
        p_base := fmt.ctprintf("assets/cards/card_%s.png", e_name)
        card_textures[idx] = load_card_texture(p_base)
        if card_textures[idx].id > 0 do loaded_count += 1

        // Load stage-specific textures
        for s in 0..<MAX_EVO_STAGES {
            evo_textures[idx][s] = load_stage_texture(e_name, s)
            if evo_textures[idx][s].id > 0 do loaded_count += 1
        }
    }

    card_textures_loaded = (loaded_count > 0)
    if card_textures_loaded {
        fmt.printf("[Hellfire] Card textures loaded successfully (%d textures in VRAM)!\n", loaded_count)
    } else {
        fmt.println("[Hellfire] Notice: Running with procedural card art fallback.")
    }
}

unload_card_textures :: proc() {
    for idx in 0..<TOTAL_ELEMENTS {
        if card_textures[idx].id > 0 {
            rl.UnloadTexture(card_textures[idx])
            card_textures[idx] = rl.Texture2D{}
        }
        for s in 0..<MAX_EVO_STAGES {
            if evo_textures[idx][s].id > 0 {
                rl.UnloadTexture(evo_textures[idx][s])
                evo_textures[idx][s] = rl.Texture2D{}
            }
        }
    }
    card_textures_loaded = false
}

get_element_card_texture :: proc(elem: Element, stage: int = 0) -> (rl.Texture2D, bool) {
    s := math.clamp(stage, 0, MAX_EVO_STAGES - 1)
    idx := int(elem)
    if idx < 0 || idx >= TOTAL_ELEMENTS do return rl.Texture2D{}, false

    // 1. Exact match for requested stage
    if evo_textures[idx][s].id > 0 do return evo_textures[idx][s], true

    // 2. If evolved (s > 0), search for the closest available evolved form
    if s > 0 {
        for i := s - 1; i >= 1; i -= 1 {
            if evo_textures[idx][i].id > 0 do return evo_textures[idx][i], true
        }
        if evo_textures[idx][4].id > 0 do return evo_textures[idx][4], true
    }

    // 3. Stage 0 or base fallback
    if evo_textures[idx][0].id > 0 do return evo_textures[idx][0], true
    if card_textures[idx].id > 0   do return card_textures[idx], true

    // 4. For dual elements: if no texture exists yet, fallback to primary parent's texture
    if is_dual_element(elem) {
        p1, _ := get_element_parents(elem)
        p1_idx := int(p1)
        if evo_textures[p1_idx][s].id > 0 do return evo_textures[p1_idx][s], true
        if evo_textures[p1_idx][4].id > 0 do return evo_textures[p1_idx][4], true
        if card_textures[p1_idx].id > 0   do return card_textures[p1_idx], true
    }

    return rl.Texture2D{}, false
}

// Ornate Hellfire-style Card Rendering Procedure
draw_card :: proc(
    rect:        rl.Rectangle,
    elem:        Element,
    name:        string,
    rarity:      int,
    hp_cur:      int,
    hp_max:      int,
    selected:    bool,
    hurt_flash:  bool,
    is_monster:  bool,
    time:        f32,
    tilt_rad:    f32 = 0.0,
    stage:       int = 0,
) {
    elem_col1 := element_primary_color(elem)
    elem_col2 := element_secondary_color(elem)

    // Higher stage radiant outer aura and Tier V God Rays
    if stage >= 3 || selected {
        glow_pulse := math.sin(time * (4.0 + f32(stage) * 1.5)) * 0.2 + 0.8
        glow_pad : f32 = 6.0 + f32(stage) * 2.0
        glow_rect := rl.Rectangle{rect.x - glow_pad, rect.y - glow_pad, rect.width + glow_pad * 2.0, rect.height + glow_pad * 2.0}

        aura_col := (stage == 4) ? rl.GOLD : elem_col2
        aura_col.a = u8(glow_pulse * (100.0 + f32(stage) * 25.0))
        rl.DrawRectangleRounded(glow_rect, 0.12, 4, aura_col)
        rl.DrawRectangleRoundedLinesEx(glow_rect, 0.12, 4, 2.0 + f32(stage) * 0.5, (stage == 4) ? rl.GOLD : COLOR_TEXT_GOLD)
    }

    // Tier V Divine Celestial God-Rays
    if stage == 4 {
        center := [2]f32{rect.x + rect.width * 0.5, rect.y + rect.height * 0.5}
        ray_len := rect.width * 0.82
        num_rays := 12
        for i in 0..<num_rays {
            ang := time * 0.5 + f32(i) * (math.PI * 2.0 / f32(num_rays))
            p1 := [2]f32{center.x + math.cos(ang) * ray_len, center.y + math.sin(ang) * ray_len}
            p2 := [2]f32{center.x + math.cos(ang + 0.12) * ray_len, center.y + math.sin(ang + 0.12) * ray_len}
            ray_pulse := math.sin(time * 3.0 + f32(i)) * 0.15 + 0.85
            ray_alpha := u8(45.0 * ray_pulse)
            rl.DrawTriangle(center, p1, p2, rl.Color{255, 220, 80, ray_alpha})
        }
    }

    // Card Backing Shadow
    shadow_rect := rl.Rectangle{rect.x + 4, rect.y + 6, rect.width, rect.height}
    rl.DrawRectangleRounded(shadow_rect, 0.1, 4, rl.Color{0, 0, 0, 130})

    // Outer Card Border (Dark Gothic Slate + Gold filigree trim)
    border_col := selected ? COLOR_TEXT_GOLD : COLOR_WALL_TRIM
    if stage >= 3 do border_col = COLOR_TEXT_GOLD
    if stage == 4 do border_col = rl.GOLD

    card_bg := rl.Color{22, 18, 28, 255}
    if hurt_flash {
        card_bg = rl.Color{240, 230, 230, 255}
    }

    rl.DrawRectangleRounded(rect, 0.1, 4, card_bg)
    rl.DrawRectangleRoundedLinesEx(rect, 0.1, 4, selected ? 3.0 : (2.0 + f32(stage) * 0.4), border_col)

    // Inner Artwork Viewport
    art_margin : f32 = math.max(rect.width * 0.05, 3.0)
    top_header_h : f32 = math.max(rect.height * 0.10, 15.0)
    bot_footer_h : f32 = math.max(rect.height * 0.15, 24.0)

    art_rect := rl.Rectangle{
        rect.x + art_margin,
        rect.y + top_header_h,
        rect.width - art_margin * 2.0,
        rect.height - top_header_h - bot_footer_h,
    }

    // Draw Card Illustration Texture (or procedural fallback)
    tex, has_tex := get_element_card_texture(elem, stage)
    if has_tex && !hurt_flash {
        src_rect := rl.Rectangle{0, 0, f32(tex.width), f32(tex.height)}
        rl.DrawTexturePro(tex, src_rect, art_rect, {0, 0}, 0.0, rl.WHITE)
    } else {
        draw_procedural_card_art(art_rect, elem, hurt_flash, time)
    }

    // Inner Art Frame Trim
    rl.DrawRectangleLinesEx(art_rect, 1.5, elem_col1)

    // Top Header: Elemental Gem Crest
    gem_r : f32 = math.min(top_header_h * 0.42, 12.0)
    gem_center := [2]f32{rect.x + rect.width * 0.5, rect.y + top_header_h * 0.52}

    if is_dual_element(elem) {
        p1, p2 := get_element_parents(elem)
        p1_c1 := element_primary_color(p1)
        p1_c2 := element_secondary_color(p1)
        p2_c1 := element_primary_color(p2)
        p2_c2 := element_secondary_color(p2)

        offset := gem_r * 0.65
        c1 := [2]f32{gem_center.x - offset, gem_center.y}
        c2 := [2]f32{gem_center.x + offset, gem_center.y}

        // Parent 1 Gem (Left)
        rl.DrawCircleV(c1, gem_r * 0.85, border_col)
        rl.DrawCircleV(c1, gem_r * 0.70, p1_c1)
        rl.DrawCircleV(c1, gem_r * 0.35, p1_c2)

        // Parent 2 Gem (Right)
        rl.DrawCircleV(c2, gem_r * 0.85, border_col)
        rl.DrawCircleV(c2, gem_r * 0.70, p2_c1)
        rl.DrawCircleV(c2, gem_r * 0.35, p2_c2)

        // Golden center spark
        rl.DrawCircleV(gem_center, gem_r * 0.3, rl.GOLD)
        rl.DrawCircleV(gem_center, gem_r * 0.15, rl.WHITE)
    } else {
        rl.DrawCircleV(gem_center, gem_r + 2, border_col)
        rl.DrawCircleV(gem_center, gem_r, elem_col1)
        rl.DrawCircleV(gem_center, gem_r * 0.5, elem_col2)
        rl.DrawCircleV(gem_center, gem_r * 0.25, rl.WHITE)
    }

    // Tier Roman Numeral Badge on Top-Left Corner
    tier_tag: cstring
    switch stage {
    case 0: tier_tag = "I"
    case 1: tier_tag = "II"
    case 2: tier_tag = "III"
    case 3: tier_tag = "IV"
    case 4: tier_tag = "V"
    case:   tier_tag = "I"
    }

    badge_size : f32 = math.clamp(rect.width * 0.18, 16.0, 26.0)
    badge_rect := rl.Rectangle{rect.x + 3, rect.y + 3, badge_size, badge_size * 0.8}
    rl.DrawRectangleRec(badge_rect, rl.Color{16, 12, 22, 235})
    rl.DrawRectangleLinesEx(badge_rect, 1.2, border_col)
    bw := rl.MeasureText(tier_tag, i32(badge_size * 0.6))
    rl.DrawText(tier_tag, i32(badge_rect.x + badge_size * 0.5) - bw / 2, i32(badge_rect.y + 2), i32(badge_size * 0.6), (stage == 4) ? rl.GOLD : rl.WHITE)

    // Rarity Stars (3 to 8 stars)
    if rarity > 0 {
        star_count := math.clamp(rarity, 1, 8)
        star_spacing : f32 = math.min(rect.width / 9.0, 11.0)
        start_star_x := gem_center.x - f32(star_count - 1) * star_spacing * 0.5
        star_y := gem_center.y - 1.0

        for s in 0..<star_count {
            sx := start_star_x + f32(s) * star_spacing
            if math.abs(sx - gem_center.x) > (is_dual_element(elem) ? (gem_r * 1.5) : (gem_r + 1.0)) {
                star_col := (s >= 5) ? rl.RED : rl.GOLD
                rl.DrawCircleV([2]f32{sx, star_y}, 2.2, star_col)
                rl.DrawCircleV([2]f32{sx, star_y}, 0.9, rl.WHITE)
            }
        }
    }

    // Bottom Footer: Name Ribbon
    ribbon_rect := rl.Rectangle{
        rect.x + 3,
        rect.y + rect.height - bot_footer_h,
        rect.width - 6,
        bot_footer_h - 6,
    }
    rl.DrawRectangleRec(ribbon_rect, rl.Color{14, 10, 20, 240})
    rl.DrawRectangleLinesEx(ribbon_rect, 1.2, border_col)

    // Creature Name with dynamic responsive text scaling
    if len(name) > 0 {
        name_cstr := strings.clone_to_cstring(name)
        defer delete(name_cstr)

        font_size : i32 = i32(math.clamp(rect.width * 0.075, 11.0, 22.0))
        for font_size > 9 && rl.MeasureText(name_cstr, font_size) > i32(ribbon_rect.width - 8) {
            font_size -= 1
        }

        nw := rl.MeasureText(name_cstr, font_size)
        nx := i32(rect.x + rect.width * 0.5) - nw / 2
        ny := i32(ribbon_rect.y + (ribbon_rect.height - f32(font_size)) * 0.5)
        name_color := (stage == 4) ? rl.GOLD : rl.RAYWHITE
        rl.DrawText(name_cstr, nx, ny, font_size, name_color)
    }

    // HP Bar at very bottom of card
    if hp_max > 0 {
        hp_bar_h : f32 = 4.0
        hp_bar_y := rect.y + rect.height - hp_bar_h - 2.0
        hp_bar_w := rect.width - 8.0
        hp_bar_x := rect.x + 4.0

        hp_pct := math.clamp(f32(hp_cur) / f32(hp_max), 0.0, 1.0)
        rl.DrawRectangle(i32(hp_bar_x), i32(hp_bar_y), i32(hp_bar_w), i32(hp_bar_h), rl.Color{10, 8, 14, 220})
        rl.DrawRectangle(i32(hp_bar_x), i32(hp_bar_y), i32(hp_bar_w * hp_pct), i32(hp_bar_h), elem_col1)
    }
}

// Procedural fantasy silhouette fallback for missing textures
draw_procedural_card_art :: proc(art_rect: rl.Rectangle, elem: Element, hurt_flash: bool, time: f32) {
    elem_col1 := element_primary_color(elem)
    elem_col2 := element_secondary_color(elem)

    bg_col := rl.Color{24, 18, 32, 255}
    if hurt_flash do bg_col = rl.Color{245, 240, 240, 255}
    rl.DrawRectangleRec(art_rect, bg_col)

    center_x := art_rect.x + art_rect.width * 0.5
    center_y := art_rect.y + art_rect.height * 0.5
    scale := art_rect.width * 0.38

    if is_dual_element(elem) {
        p1, p2 := get_element_parents(elem)
        p1_col := element_primary_color(p1)
        p2_col := element_primary_color(p2)

        // Dual swirling cosmic energy rings
        spin1 := time * 2.5
        spin2 := -time * 2.2
        rl.DrawCircleLinesV([2]f32{center_x, center_y}, scale * (0.88 + math.sin(spin1) * 0.08), p1_col)
        rl.DrawCircleLinesV([2]f32{center_x, center_y}, scale * (0.68 + math.cos(spin2) * 0.08), p2_col)
        rl.DrawCircleV([2]f32{center_x, center_y}, scale * 0.5, rl.Color{elem_col1.r, elem_col1.g, elem_col1.b, 70})

        // Opposing spirit triangles for dual elements
        pt1_1 := [2]f32{center_x + math.cos(spin1) * scale * 0.42, center_y + math.sin(spin1) * scale * 0.42}
        pt1_2 := [2]f32{center_x + math.cos(spin1 + 2.2) * scale * 0.35, center_y + math.sin(spin1 + 2.2) * scale * 0.35}
        pt1_3 := [2]f32{center_x + math.cos(spin1 + 4.2) * scale * 0.35, center_y + math.sin(spin1 + 4.2) * scale * 0.35}
        rl.DrawTriangle(pt1_1, pt1_2, pt1_3, p1_col)

        pt2_1 := [2]f32{center_x + math.cos(spin2) * scale * 0.38, center_y + math.sin(spin2) * scale * 0.38}
        pt2_2 := [2]f32{center_x + math.cos(spin2 + 2.2) * scale * 0.32, center_y + math.sin(spin2 + 2.2) * scale * 0.32}
        pt2_3 := [2]f32{center_x + math.cos(spin2 + 4.2) * scale * 0.32, center_y + math.sin(spin2 + 4.2) * scale * 0.32}
        rl.DrawTriangle(pt2_1, pt2_2, pt2_3, p2_col)

        // Core shining cosmic spark
        rl.DrawCircleV([2]f32{center_x, center_y}, 4.5, rl.WHITE)
        rl.DrawCircleV([2]f32{center_x, center_y}, 2.2, rl.GOLD)
        return
    }

    pulse := math.sin(time * 3.0) * 0.1 + 0.9
    rl.DrawCircleLinesV([2]f32{center_x, center_y}, scale * pulse, elem_col1)
    rl.DrawCircleV([2]f32{center_x, center_y}, scale * 0.8 * pulse, rl.Color{elem_col1.r, elem_col1.g, elem_col1.b, 60})

    p1 := [2]f32{center_x, center_y - scale * 0.7}
    p2 := [2]f32{center_x - scale * 0.6, center_y + scale * 0.5}
    p3 := [2]f32{center_x + scale * 0.6, center_y + scale * 0.5}
    rl.DrawTriangle(p1, p2, p3, elem_col2)

    rl.DrawCircleV([2]f32{center_x - scale * 0.2, center_y - scale * 0.15}, 3.0, rl.WHITE)
    rl.DrawCircleV([2]f32{center_x + scale * 0.2, center_y - scale * 0.15}, 3.0, rl.WHITE)
}
