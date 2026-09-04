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

card_textures: Card_Texture_Set

init_card_textures :: proc() {
    // Attempt loading textures from assets/cards/
    tex_fire  := rl.LoadTexture("assets/cards/card_fire.jpg")
    tex_water := rl.LoadTexture("assets/cards/card_water.jpg")
    tex_earth := rl.LoadTexture("assets/cards/card_earth.jpg")
    tex_chaos := rl.LoadTexture("assets/cards/card_chaos.jpg")
    tex_light := rl.LoadTexture("assets/cards/card_light.jpg")

    card_textures.fire  = tex_fire
    card_textures.water = tex_water
    card_textures.earth = tex_earth
    card_textures.chaos = tex_chaos
    card_textures.light = tex_light

    // Enable bilinear texture filtering for smooth 2.5D scaling
    if tex_fire.id > 0  do rl.SetTextureFilter(tex_fire, .BILINEAR)
    if tex_water.id > 0 do rl.SetTextureFilter(tex_water, .BILINEAR)
    if tex_earth.id > 0 do rl.SetTextureFilter(tex_earth, .BILINEAR)
    if tex_chaos.id > 0 do rl.SetTextureFilter(tex_chaos, .BILINEAR)
    if tex_light.id > 0 do rl.SetTextureFilter(tex_light, .BILINEAR)

    card_textures.loaded = (tex_fire.id > 0 || tex_water.id > 0)
}

unload_card_textures :: proc() {
    if card_textures.fire.id > 0  do rl.UnloadTexture(card_textures.fire)
    if card_textures.water.id > 0 do rl.UnloadTexture(card_textures.water)
    if card_textures.earth.id > 0 do rl.UnloadTexture(card_textures.earth)
    if card_textures.chaos.id > 0 do rl.UnloadTexture(card_textures.chaos)
    if card_textures.light.id > 0 do rl.UnloadTexture(card_textures.light)
    card_textures.loaded = false
}

get_element_card_texture :: proc(elem: Element) -> (rl.Texture2D, bool) {
    switch elem {
    case .FIRE:
        if card_textures.fire.id > 0 do return card_textures.fire, true
    case .WATER:
        if card_textures.water.id > 0 do return card_textures.water, true
    case .EARTH:
        if card_textures.earth.id > 0 do return card_textures.earth, true
    case .CHAOS:
        if card_textures.chaos.id > 0 do return card_textures.chaos, true
    case .LIGHT:
        if card_textures.light.id > 0 do return card_textures.light, true
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
) {
    elem_col1 := element_primary_color(elem)
    elem_col2 := element_secondary_color(elem)

    // Selection or Boss Glow Aura
    if selected {
        glow_pulse := math.sin(time * 6.0) * 0.2 + 0.8
        glow_rect := rl.Rectangle{rect.x - 6, rect.y - 6, rect.width + 12, rect.height + 12}
        rl.DrawRectangleRounded(glow_rect, 0.12, 4, rl.Color{elem_col2.r, elem_col2.g, elem_col2.b, u8(glow_pulse * 140)})
        rl.DrawRectangleRoundedLinesEx(glow_rect, 0.12, 4, 2.5, COLOR_TEXT_GOLD)
    }

    // Card Backing Shadow
    shadow_rect := rl.Rectangle{rect.x + 4, rect.y + 6, rect.width, rect.height}
    rl.DrawRectangleRounded(shadow_rect, 0.1, 4, rl.Color{0, 0, 0, 130})

    // Outer Card Border (Dark Gothic Slate + Gold filigree trim)
    border_col := selected ? COLOR_TEXT_GOLD : COLOR_WALL_TRIM
    card_bg    := rl.Color{22, 18, 28, 255}
    if hurt_flash {
        card_bg = rl.Color{240, 230, 230, 255}
    }

    rl.DrawRectangleRounded(rect, 0.1, 4, card_bg)
    rl.DrawRectangleRoundedLinesEx(rect, 0.1, 4, selected ? 3.0 : 2.0, border_col)

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
    tex, has_tex := get_element_card_texture(elem)
    if has_tex && !hurt_flash {
        src_rect := rl.Rectangle{0, 0, f32(tex.width), f32(tex.height)}
        rl.DrawTexturePro(tex, src_rect, art_rect, {0, 0}, 0.0, rl.WHITE)
    } else {
        // High quality procedural fantasy fallback silhouette
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

    // Rarity Stars (1 to 5 stars)
    if rarity > 0 {
        star_count := math.clamp(rarity, 1, 5)
        star_spacing : f32 = math.min(rect.width / 7.0, 14.0)
        start_star_x := gem_center.x - f32(star_count - 1) * star_spacing * 0.5
        star_y := gem_center.y - 1.0

        for s in 0..<star_count {
            sx := start_star_x + f32(s) * star_spacing
            if math.abs(sx - gem_center.x) > gem_r + 2 {
                rl.DrawCircleV([2]f32{sx, star_y}, 2.5, rl.GOLD)
                rl.DrawCircleV([2]f32{sx, star_y}, 1.0, rl.WHITE)
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
        font_size : i32 = i32(math.clamp(rect.width * 0.11, 11.0, 16.0))
        nw := rl.MeasureText(name_cstr, font_size)
        nx := i32(rect.x + rect.width * 0.5) - nw / 2
        ny := i32(ribbon_rect.y + 2)
        rl.DrawText(name_cstr, nx, ny, font_size, rl.RAYWHITE)
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

    // Dark gradient background
    bg_col := rl.Color{28, 22, 38, 255}
    if hurt_flash do bg_col = rl.Color{245, 240, 240, 255}
    rl.DrawRectangleRec(art_rect, bg_col)

    center_x := art_rect.x + art_rect.width * 0.5
    center_y := art_rect.y + art_rect.height * 0.5
    scale := art_rect.width * 0.38

    // Mystic elemental aura rings
    pulse := math.sin(time * 3.0) * 0.1 + 0.9
    rl.DrawCircleLinesV([2]f32{center_x, center_y}, scale * pulse, elem_col1)
    rl.DrawCircleV([2]f32{center_x, center_y}, scale * 0.8 * pulse, rl.Color{elem_col1.r, elem_col1.g, elem_col1.b, 60})

    // Stylized Creature Silhouette
    p1 := [2]f32{center_x, center_y - scale * 0.7}
    p2 := [2]f32{center_x - scale * 0.6, center_y + scale * 0.5}
    p3 := [2]f32{center_x + scale * 0.6, center_y + scale * 0.5}
    rl.DrawTriangle(p1, p2, p3, elem_col2)

    // Glowing creature eyes
    rl.DrawCircleV([2]f32{center_x - scale * 0.2, center_y - scale * 0.15}, 3.0, rl.WHITE)
    rl.DrawCircleV([2]f32{center_x + scale * 0.2, center_y - scale * 0.15}, 3.0, rl.WHITE)
}

