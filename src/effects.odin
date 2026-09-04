package hellfire

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:strings"
import rl "vendor:raylib"

particles: [MAX_PARTICLES]Particle
particle_count: int

damage_texts: [MAX_DAMAGE_TEXTS]Damage_Number
damage_text_count: int

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
        spd   := rand.float32() * 320.0 + 60.0
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

update_particles :: proc(dt: f32) {
    i := 0
    for i < particle_count {
        p := &particles[i]
        p.life -= dt
        if p.life <= 0.0 {
            // Swap with last
            particles[i] = particles[particle_count - 1]
            particle_count -= 1
            continue
        }

        p.pos += p.vel * dt
        p.vel *= 0.94 // slight drag
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

add_damage_number :: proc(pos: [2]f32, amount: int, is_crit: bool, color: rl.Color) {
    if damage_text_count >= MAX_DAMAGE_TEXTS do return

    text_buf: string
    if is_crit {
        text_buf = fmt.tprintf("CRIT %d!", amount)
    } else {
        text_buf = fmt.tprintf("%d", amount)
    }

    damage_texts[damage_text_count] = Damage_Number{
        pos      = pos + {rand.float32() * 20.0 - 10.0, -10.0},
        vel      = {rand.float32() * 40.0 - 20.0, -95.0},
        text     = strings.clone(text_buf),
        color    = color,
        is_crit  = is_crit,
        life     = 0.9,
        max_life = 0.9,
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
        d.vel.y += 60.0 * dt // slight gravity easing
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
        shadow_c.a = u8(180.0 * alpha_t)

        cstr := strings.clone_to_cstring(d.text)
        defer delete(cstr)

        text_w := rl.MeasureText(cstr, font_size)
        draw_x := i32(d.pos.x) - text_w / 2
        draw_y := i32(d.pos.y)

        // Drop shadow for legibility
        rl.DrawText(cstr, draw_x + 2, draw_y + 2, font_size, shadow_c)
        rl.DrawText(cstr, draw_x, draw_y, font_size, c)
    }
}

