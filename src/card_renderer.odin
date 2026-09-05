package hellfire

import "core:fmt"
import "core:math"
import "core:strings"
import rl "vendor:raylib"

Card_Texture_Set :: struct {
    fire:   rl.Texture2D,
    water:  rl.Texture2D,
    earth:  rl.Texture2D,
    chaos:  rl.Texture2D,
    light:  rl.Texture2D,
    loaded: bool,
}

Card_Stage_Textures :: [MAX_EVO_STAGES]rl.Texture2D

Evo_Texture_Set :: struct {
    fire:  Card_Stage_Textures,
    water: Card_Stage_Textures,
    earth: Card_Stage_Textures,
    chaos: Card_Stage_Textures,
    light: Card_Stage_Textures,
}

card_textures: Card_Texture_Set
evo_textures:  Evo_Texture_Set

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

init_card_textures :: proc() {
    // Load base textures
    card_textures.fire  = load_card_texture("assets/cards/card_fire.png")
    card_textures.water = load_card_texture("assets/cards/card_water.png")
    card_textures.earth = load_card_texture("assets/cards/card_earth.png")
    card_textures.chaos = load_card_texture("assets/cards/card_chaos.png")
    card_textures.light = load_card_texture("assets/cards/card_light.png")

    // Load stage-specific textures if present
    for s in 0..<MAX_EVO_STAGES {
        path_fire  := fmt.ctprintf("assets/cards/card_fire_stage_%d.png", s)
        path_water := fmt.ctprintf("assets/cards/card_water_stage_%d.png", s)
        path_earth := fmt.ctprintf("assets/cards/card_earth_stage_%d.png", s)
        path_chaos := fmt.ctprintf("assets/cards/card_chaos_stage_%d.png", s)
        path_light := fmt.ctprintf("assets/cards/card_light_stage_%d.png", s)

        evo_textures.fire[s]  = load_card_texture(path_fire)
        evo_textures.water[s] = load_card_texture(path_water)
        evo_textures.earth[s] = load_card_texture(path_earth)
        evo_textures.chaos[s] = load_card_texture(path_chaos)
        evo_textures.light[s] = load_card_texture(path_light)
    }

    card_textures.loaded = (card_textures.fire.id > 0 || card_textures.water.id > 0)
    if card_textures.loaded {
        fmt.println("[Hellfire] Creature card textures loaded successfully into VRAM!")
    } else {
        fmt.println("[Hellfire] Notice: Running with procedural card art fallback.")
    }
}

unload_card_textures :: proc() {
    if card_textures.fire.id > 0  do rl.UnloadTexture(card_textures.fire)
    if card_textures.water.id > 0 do rl.UnloadTexture(card_textures.water)
    if card_textures.earth.id > 0 do rl.UnloadTexture(card_textures.earth)
    if card_textures.chaos.id > 0 do rl.UnloadTexture(card_textures.chaos)
    if card_textures.light.id > 0 do rl.UnloadTexture(card_textures.light)

    for s in 0..<MAX_EVO_STAGES {
        if evo_textures.fire[s].id > 0  do rl.UnloadTexture(evo_textures.fire[s])
        if evo_textures.water[s].id > 0 do rl.UnloadTexture(evo_textures.water[s])
        if evo_textures.earth[s].id > 0 do rl.UnloadTexture(evo_textures.earth[s])
        if evo_textures.chaos[s].id > 0 do rl.UnloadTexture(evo_textures.chaos[s])
        if evo_textures.light[s].id > 0 do rl.UnloadTexture(evo_textures.light[s])
    }
    card_textures.loaded = false
}

get_element_card_texture :: proc(elem: Element, stage: int = 0) -> (rl.Texture2D, bool) {
    s := math.clamp(stage, 0, MAX_EVO_STAGES - 1)

    textures: ^Card_Stage_Textures
    base_tex: rl.Texture2D

    switch elem {
    case .FIRE:
        textures = &evo_textures.fire
        base_tex = card_textures.fire
    case .WATER:
        textures = &evo_textures.water
        base_tex = card_textures.water
    case .EARTH:
        textures = &evo_textures.earth
        base_tex = card_textures.earth
    case .CHAOS:
        textures = &evo_textures.chaos
        base_tex = card_textures.chaos
    case .LIGHT:
        textures = &evo_textures.light
        base_tex = card_textures.light
    }

    // 1. Exact match for requested stage
    if textures[s].id > 0 do return textures[s], true

    // 2. If evolved (s > 0), search for the closest available evolved form (prefer s down to 1, then stage 4)
    if s > 0 {
        for i := s - 1; i >= 1; i -= 1 {
            if textures[i].id > 0 do return textures[i], true
        }
        if textures[4].id > 0 do return textures[4], true
    }

    // 3. Stage 0 or base fallback
    if textures[0].id > 0 do return textures[0], true
    if base_tex.id > 0    do return base_tex, true

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

    // Higher stage radiant outer aura
    if stage >= 3 || selected {
        glow_pulse := math.sin(time * (4.0 + f32(stage) * 1.5)) * 0.2 + 0.8
        glow_pad : f32 = 6.0 + f32(stage) * 2.0
        glow_rect := rl.Rectangle{rect.x - glow_pad, rect.y - glow_pad, rect.width + glow_pad * 2.0, rect.height + glow_pad * 2.0}

        aura_col := (stage == 4) ? rl.GOLD : elem_col2
        aura_col.a = u8(glow_pulse * (100.0 + f32(stage) * 25.0))
        rl.DrawRectangleRounded(glow_rect, 0.12, 4, aura_col)
        rl.DrawRectangleRoundedLinesEx(glow_rect, 0.12, 4, 2.0 + f32(stage) * 0.5, (stage == 4) ? rl.GOLD : COLOR_TEXT_GOLD)
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
    art_margin : f32 = math.max(rect.width * 0.06, 4.0)
    top_header_h : f32 = math.max(rect.height * 0.12, 16.0)
    bot_footer_h : f32 = math.max(rect.height * 0.18, 22.0)

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
    rl.DrawCircleV(gem_center, gem_r + 2, border_col)
    rl.DrawCircleV(gem_center, gem_r, elem_col1)
    rl.DrawCircleV(gem_center, gem_r * 0.5, elem_col2)
    rl.DrawCircleV(gem_center, gem_r * 0.25, rl.WHITE)

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

    badge_size : f32 = math.clamp(rect.width * 0.18, 16.0, 24.0)
    badge_rect := rl.Rectangle{rect.x + 3, rect.y + 3, badge_size, badge_size * 0.8}
    rl.DrawRectangleRec(badge_rect, rl.Color{16, 12, 22, 220})
    rl.DrawRectangleLinesEx(badge_rect, 1.0, border_col)
    bw := rl.MeasureText(tier_tag, i32(badge_size * 0.6))
    rl.DrawText(tier_tag, i32(badge_rect.x + badge_size * 0.5) - bw / 2, i32(badge_rect.y + 2), i32(badge_size * 0.6), (stage == 4) ? rl.GOLD : rl.WHITE)

    // Rarity Stars (3 to 7 stars)
    if rarity > 0 {
        star_count := math.clamp(rarity, 1, 7)
        star_spacing : f32 = math.min(rect.width / 8.5, 11.0)
        start_star_x := gem_center.x - f32(star_count - 1) * star_spacing * 0.5
        star_y := gem_center.y - 1.0

        for s in 0..<star_count {
            sx := start_star_x + f32(s) * star_spacing
            if math.abs(sx - gem_center.x) > gem_r + 1 {
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
    rl.DrawRectangleRec(ribbon_rect, rl.Color{16, 12, 22, 230})
    rl.DrawRectangleLinesEx(ribbon_rect, 1.0, border_col)

    // Creature Name
    if len(name) > 0 {
        name_cstr := strings.clone_to_cstring(name)
        defer delete(name_cstr)
        font_size : i32 = i32(math.clamp(rect.width * 0.105, 10.0, 15.0))
        nw := rl.MeasureText(name_cstr, font_size)
        nx := i32(rect.x + rect.width * 0.5) - nw / 2
        ny := i32(ribbon_rect.y + 2)
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

    bg_col := rl.Color{28, 22, 38, 255}
    if hurt_flash do bg_col = rl.Color{245, 240, 240, 255}
    rl.DrawRectangleRec(art_rect, bg_col)

    center_x := art_rect.x + art_rect.width * 0.5
    center_y := art_rect.y + art_rect.height * 0.5
    scale := art_rect.width * 0.38

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
