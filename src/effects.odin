package hellfire

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

particles: [MAX_PARTICLES]Particle
particle_count: int

ambient_particles: [MAX_AMBIENT]Ambient_Particle
ambient_count: int

damage_texts: [MAX_DAMAGE_TEXTS]Damage_Number
damage_text_count: int

combo_popups: [MAX_COMBO_POPUPS]Combo_Popup
combo_popup_count: int

shockwaves: [MAX_SHOCKWAVES]Shockwave
shockwave_count: int

screen_shake: Screen_Shake

add_screen_shake :: proc(intensity: f32, duration: f32) {
    if intensity > screen_shake.intensity {
        screen_shake.intensity = intensity
    }
    if duration > screen_shake.timer {
        screen_shake.timer = duration
    }
}

update_screen_shake :: proc(dt: f32) -> [2]f32 {
    if screen_shake.timer <= 0.0 {
        screen_shake.intensity = 0.0
        return {0.0, 0.0}
    }

    screen_shake.timer -= dt
    current_intensity := screen_shake.intensity * (screen_shake.timer / (screen_shake.timer + dt))

    rx := (rand.float32() * 2.0 - 1.0) * current_intensity
    ry := (rand.float32() * 2.0 - 1.0) * current_intensity
    return {rx, ry}
}

emit_sparks :: proc(pos: [2]f32, color: rl.Color, count: int, speed: f32) {
    for i in 0..<count {
        if particle_count >= MAX_PARTICLES do break

        angle := rand.float32() * math.TAU
        spd   := (rand.float32() * 0.7 + 0.3) * speed
        vel   := [2]f32{math.cos(angle) * spd, math.sin(angle) * spd}

        particles[particle_count] = Particle{
            pos      = pos,
            vel      = vel,
            color    = color,
            size     = rand.float32() * 3.5 + 2.0,
            life     = 0.4 + rand.float32() * 0.3,
            max_life = 0.7,
        }
        particle_count += 1
    }
}

emit_burst :: proc(pos: [2]f32, color1, color2: rl.Color, count: int) {
    for i in 0..<count {
        if particle_count >= MAX_PARTICLES do break

        angle := rand.float32() * math.TAU
        spd   := rand.float32() * 340.0 + 60.0
        vel   := [2]f32{math.cos(angle) * spd, math.sin(angle) * spd}
        col   := rand.float32() > 0.5 ? color1 : color2

        particles[particle_count] = Particle{
            pos      = pos,
            vel      = vel,
            color    = col,
            size     = rand.float32() * 5.0 + 3.0,
            life     = 0.5 + rand.float32() * 0.4,
            max_life = 0.9,
        }
        particle_count += 1
    }
}

emit_trail_particle :: proc(pos: [2]f32, color: rl.Color, size: f32) {
    if particle_count >= MAX_PARTICLES do return

    rx := (rand.float32() * 2.0 - 1.0) * 8.0
    ry := (rand.float32() * 2.0 - 1.0) * 8.0

    particles[particle_count] = Particle{
        pos      = pos + {rx, ry},
        vel      = {rx * 1.5, ry * 1.5},
        color    = color,
        size     = size,
        life     = 0.25,
        max_life = 0.25,
    }
    particle_count += 1
}

add_shockwave :: proc(pos: [2]f32, max_radius: f32, color: rl.Color, duration: f32 = 0.35) {
    if shockwave_count >= MAX_SHOCKWAVES do return

    shockwaves[shockwave_count] = Shockwave{
        pos        = pos,
        radius     = 6.0,
        max_radius = max_radius,
        color      = color,
        life       = duration,
        max_life   = duration,
    }
    shockwave_count += 1
}

// Flashy combo popup triggered when combo >= 2
add_combo_popup :: proc(pos: [2]f32, combo: int, mult: f32, color: rl.Color) {
    if combo < 2 do return
    if combo_popup_count >= MAX_COMBO_POPUPS do return

    title: string
    switch {
    case combo == 2:
        title = "2x COMBO!"
    case combo == 3:
        title = "3x TRIPLE STRIKE!"
    case combo == 4:
        title = "4x MEGA BURST!"
    case combo == 5:
        title = "5x DEMONIC CHAIN!"
    case:
        title = fmt.tprintf("%dx HELLFIRE GOD!", combo)
    }

    // Clamp Y position so it displays comfortably inside the arena
    display_y := math.clamp(pos.y - 45.0, ARENA_TOP + 40.0, ARENA_BOTTOM - 60.0)

    combo_popups[combo_popup_count] = Combo_Popup{
        pos         = {pos.x, display_y},
        combo_count = combo,
        multiplier  = mult,
        title       = strings.clone(title),
        life        = 1.1,
        max_life    = 1.1,
        scale       = 2.2, // Punch-down animation starts large
        color       = color,
    }
    combo_popup_count += 1

    // Accompanying shockwave & spark explosion
    shock_r := 35.0 + f32(combo) * 12.0
    add_shockwave(pos, shock_r, color, 0.38)
    emit_sparks(pos, color, 14 + combo * 3, 260.0 + f32(combo) * 30.0)
    add_screen_shake(2.5 + f32(combo) * 1.1, 0.14)
}

update_combo_popups :: proc(dt: f32) {
    i := 0
    for i < combo_popup_count {
        cp := &combo_popups[i]
        cp.life -= dt
        if cp.life <= 0.0 {
            delete(cp.title)
            combo_popups[i] = combo_popups[combo_popup_count - 1]
            combo_popup_count -= 1
            continue
        }

        // Punch scale interpolation: 2.2 down to 1.0 quickly
        t := 1.0 - (cp.life / cp.max_life)
        if t < 0.25 {
            cp.scale = 2.2 - (t / 0.25) * 1.2
        } else {
            cp.scale = 1.0 + math.sin((t - 0.25) * math.PI * 3.0) * 0.08
        }

        // Drift slowly upward
        cp.pos.y -= 25.0 * dt
        i += 1
    }
}

draw_combo_popups :: proc() {
    for i in 0..<combo_popup_count {
        cp := combo_popups[i]
        alpha_t := math.clamp(cp.life / (cp.max_life * 0.4), 0.0, 1.0)

        font_size : i32 = i32(f32(28 + min(cp.combo_count * 3, 16)) * cp.scale)
        cstr := strings.clone_to_cstring(cp.title)
        defer delete(cstr)

        text_w := rl.MeasureText(cstr, font_size)
        draw_x := i32(cp.pos.x) - text_w / 2
        draw_y := i32(cp.pos.y) - font_size / 2

        // Glow color & Drop shadow
        c := cp.color
        c.a = u8(f32(c.a) * alpha_t)
        shadow_c := rl.BLACK
        shadow_c.a = u8(220.0 * alpha_t)

        // Draw multiple passes for bold glowing aura
        glow_c := c
        glow_c.a = u8(110.0 * alpha_t)
        rl.DrawText(cstr, draw_x - 2, draw_y, font_size, glow_c)
        rl.DrawText(cstr, draw_x + 2, draw_y, font_size, glow_c)
        rl.DrawText(cstr, draw_x, draw_y - 2, font_size, glow_c)
        rl.DrawText(cstr, draw_x, draw_y + 2, font_size, glow_c)

        rl.DrawText(cstr, draw_x + 3, draw_y + 3, font_size, shadow_c)
        rl.DrawText(cstr, draw_x, draw_y, font_size, c)

        // Multiplier subtitle
        mult_str := fmt.tprintf("(+%.0f%% DMG)", (cp.multiplier - 1.0) * 100.0)
        m_cstr := strings.clone_to_cstring(mult_str)
        defer delete(m_cstr)
        sub_size : i32 = i32(18.0 * cp.scale)
        sub_w := rl.MeasureText(m_cstr, sub_size)
        rl.DrawText(m_cstr, i32(cp.pos.x) - sub_w / 2, draw_y + font_size + 4, sub_size, COLOR_TEXT_GOLD)
    }
}

update_shockwaves :: proc(dt: f32) {
    i := 0
    for i < shockwave_count {
        s := &shockwaves[i]
        s.life -= dt
        if s.life <= 0.0 {
            shockwaves[i] = shockwaves[shockwave_count - 1]
            shockwave_count -= 1
            continue
        }

        t := 1.0 - (s.life / s.max_life)
        s.radius = 6.0 + t * (s.max_radius - 6.0)
        i += 1
    }
}

draw_shockwaves :: proc() {
    for i in 0..<shockwave_count {
        s := shockwaves[i]
        alpha_t := math.clamp(s.life / s.max_life, 0.0, 1.0)
        c := s.color
        c.a = u8(f32(c.a) * alpha_t * 0.8)
        rl.DrawCircleLinesV(s.pos, s.radius, c)
        rl.DrawCircleLinesV(s.pos, s.radius * 0.95, c)
    }
}

// Ambient Environment Particle System
init_ambient_particles :: proc(c1, c2: rl.Color) {
    ambient_count = MAX_AMBIENT
    for i in 0..<MAX_AMBIENT {
        y := ARENA_TOP + rand.float32() * (ARENA_BOTTOM - ARENA_TOP)
        hw := arena_half_width_at_y(y)
        x := ARENA_CENTER_X + (rand.float32() * 2.0 - 1.0) * hw

        col := (rand.float32() > 0.4) ? c1 : c2
        ambient_particles[i] = Ambient_Particle{
            pos      = {x, y},
            vel      = {(rand.float32() * 2.0 - 1.0) * 12.0, - (rand.float32() * 25.0 + 15.0)},
            color    = col,
            size     = rand.float32() * 3.0 + 1.5,
            life     = rand.float32() * 3.0 + 1.0,
            max_life = 4.0,
            phase    = rand.float32() * math.TAU,
        }
    }
}

update_ambient_particles :: proc(dt: f32, c1, c2: rl.Color) {
    for i in 0..<ambient_count {
        p := &ambient_particles[i]
        p.life -= dt
        p.phase += dt * 1.5

        if p.life <= 0.0 || p.pos.y < ARENA_TOP {
            // Respawn near bottom or middle
            p.pos.y = ARENA_BOTTOM - rand.float32() * 80.0
            hw := arena_half_width_at_y(p.pos.y)
            p.pos.x = ARENA_CENTER_X + (rand.float32() * 2.0 - 1.0) * hw
            p.life = rand.float32() * 3.0 + 1.5
            p.max_life = p.life
            p.color = (rand.float32() > 0.4) ? c1 : c2
        }

        // Sway gently
        p.pos.x += math.sin(p.phase) * 16.0 * dt
        p.pos += p.vel * dt
    }
}

draw_ambient_particles :: proc() {
    for i in 0..<ambient_count {
        p := ambient_particles[i]
        alpha_t := math.clamp(p.life / p.max_life, 0.0, 1.0)
        c := p.color
        c.a = u8(f32(c.a) * alpha_t * 0.75)
        rl.DrawCircleV(p.pos, p.size, c)
    }
}

update_particles :: proc(dt: f32) {
    i := 0
    for i < particle_count {
        p := &particles[i]
        p.life -= dt
        if p.life <= 0.0 {
            particles[i] = particles[particle_count - 1]
            particle_count -= 1
            continue
        }

        p.pos += p.vel * dt
        p.vel *= 0.94
        i += 1
    }
}

draw_particles :: proc() {
    for i in 0..<particle_count {
        p := particles[i]
        alpha_t := math.clamp(p.life / p.max_life, 0.0, 1.0)
        c := p.color
        c.a = u8(f32(c.a) * alpha_t)
        current_size := p.size * (0.3 + 0.7 * alpha_t)
        rl.DrawCircleV(p.pos, current_size, c)
    }
}

add_damage_number :: proc(pos: [2]f32, amount: int, is_crit: bool, color: rl.Color, subtitle: string = "") {
    if damage_text_count >= MAX_DAMAGE_TEXTS do return

    text_buf: string
    if len(subtitle) > 0 {
        if is_crit {
            text_buf = fmt.tprintf("CRIT %d!\n%s", amount, subtitle)
        } else {
            text_buf = fmt.tprintf("%d\n%s", amount, subtitle)
        }
    } else {
        if is_crit {
            text_buf = fmt.tprintf("CRIT %d!", amount)
        } else {
            text_buf = fmt.tprintf("%d", amount)
        }
    }

    damage_texts[damage_text_count] = Damage_Number{
        pos      = pos + {rand.float32() * 20.0 - 10.0, -10.0},
        vel      = {rand.float32() * 40.0 - 20.0, -95.0},
        text     = strings.clone(text_buf),
        color    = color,
        is_crit  = is_crit,
        life     = 0.95,
        max_life = 0.95,
    }
    damage_text_count += 1
}

update_damage_numbers :: proc(dt: f32) {
    i := 0
    for i < damage_text_count {
        d := &damage_texts[i]
        d.life -= dt
        if d.life <= 0.0 {
            delete(d.text)
            damage_texts[i] = damage_texts[damage_text_count - 1]
            damage_text_count -= 1
            continue
        }

        d.pos += d.vel * dt
        d.vel.y += 55.0 * dt
        i += 1
    }
}

draw_damage_numbers :: proc() {
    for i in 0..<damage_text_count {
        d := damage_texts[i]
        alpha_t := math.clamp(d.life / d.max_life, 0.0, 1.0)
        font_size : i32 = d.is_crit ? 28 : 22

        c := d.color
        c.a = u8(f32(c.a) * alpha_t)
        shadow_c := rl.BLACK
        shadow_c.a = u8(190.0 * alpha_t)

        cstr := strings.clone_to_cstring(d.text)
        defer delete(cstr)

        text_w := rl.MeasureText(cstr, font_size)
        draw_x := i32(d.pos.x) - text_w / 2
        draw_y := i32(d.pos.y)

        rl.DrawText(cstr, draw_x + 2, draw_y + 2, font_size, shadow_c)
        rl.DrawText(cstr, draw_x, draw_y, font_size, c)
    }
}
