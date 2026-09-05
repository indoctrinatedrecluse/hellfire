package hellfire

import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

// Line-segment to circle distance check
dist_to_segment :: proc(p, a, b: [2]f32) -> (dist: f32, closest: [2]f32) {
    ab := b - a
    ap := p - a
    ab_len_sq := linalg.length2(ab)
    if ab_len_sq == 0.0 {
        return linalg.length(p - a), a
    }

    t := math.clamp(linalg.dot(ap, ab) / ab_len_sq, 0.0, 1.0)
    closest = a + ab * t
    dist = linalg.length(p - closest)
    return
}

update_orb_physics :: proc(orb: ^Orb, enemies: ^[MAX_ENEMIES]Enemy, enemy_count: int, dt: f32) -> bool {
    if !orb.active do return false

    // Record trail
    orb.trail_timer += dt
    if orb.trail_timer >= 0.015 {
        orb.trail_timer = 0.0
        for j := MAX_TRAIL_POINTS - 1; j > 0; j -= 1 {
            orb.trail[j] = orb.trail[j - 1]
        }
        orb.trail[0] = orb.pos
        if orb.trail_count < MAX_TRAIL_POINTS {
            orb.trail_count += 1
        }
    }

    emit_trail_particle(orb.pos, element_secondary_color(orb.element), orb.radius * 0.45)

    // Dynamic depth scaling of ball radius based on Y position
    depth_z := arena_depth_z_at_y(orb.pos.y)
    orb.radius = BALL_BASE_RADIUS * (0.65 + 0.35 * depth_z)

    // Move
    orb.pos += orb.vel * dt
    orb.vel *= math.pow(BALL_DRAG, dt * 60.0)

    // Check stop / exit condition
    speed := linalg.length(orb.vel)
    if orb.pos.y > ARENA_BOTTOM + 80.0 || (speed < BALL_MIN_SPEED && orb.pos.y > ARENA_TOP + 200.0) {
        orb.active = false
        orb.vel = {0.0, 0.0}
        return false
    }

    // --- Arena Wall Collisions ---
    left_wall, right_wall, top_wall := arena_get_walls()
    walls := [3]Arena_Wall{left_wall, right_wall, top_wall}

    for wall in walls {
        d, closest := dist_to_segment(orb.pos, wall.p1, wall.p2)
        if d < orb.radius {
            vel_dot_n := linalg.dot(orb.vel, wall.normal)
            if vel_dot_n < 0.0 {
                pen := orb.radius - d
                orb.pos += wall.normal * pen
                orb.vel = (orb.vel - 2.0 * vel_dot_n * wall.normal) * BALL_RESTITUTION

                orb.bounces += 1
                orb.combo += 1

                spark_col := element_secondary_color(orb.element)
                emit_sparks(closest, spark_col, 10, 240.0)
                add_screen_shake(2.2, 0.07)
            }
        }
    }

    // --- Dungeon Blocks Collisions ---
    for i in 0..<block_count {
        b := &blocks[i]
        if !b.active do continue

        hw := b.size.x * 0.5
        hh := b.size.y * 0.5

        cx := math.clamp(orb.pos.x, b.pos.x - hw, b.pos.x + hw)
        cy := math.clamp(orb.pos.y, b.pos.y - hh, b.pos.y + hh)
        dist := linalg.distance(orb.pos, [2]f32{cx, cy})

        if dist < orb.radius {
            collision_normal: [2]f32
            if dist > 0.001 {
                collision_normal = linalg.normalize0(orb.pos - [2]f32{cx, cy})
            } else {
                collision_normal = [2]f32{0.0, 1.0}
            }

            vel_dot_norm := linalg.dot(orb.vel, -collision_normal)
            if vel_dot_norm > 0.0 {
                // Separate
                orb.pos = [2]f32{cx, cy} + collision_normal * (orb.radius + 1.0)
                orb.vel = linalg.reflect(orb.vel, -collision_normal) * BALL_RESTITUTION

                // Element affinity, evolution power & combo calculations
                elem_mult, effect, label := element_interaction(orb.element, b.element)
                orb.bounces += 1
                orb.combo += 1
                combo_mult := combo_multiplier_for_count(orb.combo)

                card_stage := game.card_stages[int(orb.element)]
                c_data := get_card_stage_data(orb.element, card_stage)
                evo_mult := c_data.power_mult

                base_dmg : f32 = 65.0
                damage := int(base_dmg * evo_mult * elem_mult * combo_mult)

                b.current_hp -= damage
                b.hurt_timer = 0.12
                game.score += 25 * orb.combo

                // Trigger flashy combo popup when hitting 2+ blocks/targets
                if orb.combo >= 2 {
                    combo_col := element_secondary_color(orb.element)
                    add_combo_popup(b.pos, orb.combo, combo_mult, combo_col)
                }

                dmg_col := (effect == .RESISTED) ? rl.LIGHTGRAY : element_secondary_color(orb.element)
                add_damage_number([2]f32{cx, cy}, damage, false, dmg_col, label)

                if b.current_hp <= 0 {
                    b.current_hp = 0
                    b.active = false
                    emit_burst(b.pos, element_primary_color(b.element), rl.WHITE, 35)
                    add_shockwave(b.pos, 52.0, element_primary_color(b.element))
                    add_screen_shake(5.5, 0.16)
                    game.score += 150
                } else {
                    emit_sparks([2]f32{cx, cy}, element_secondary_color(orb.element), 8, 220.0)
                    add_screen_shake(2.8, 0.09)
                }
            }
        }
    }

    // --- Enemy Collisions ---
    for i in 0..<enemy_count {
        e := &enemies[i]
        if !e.alive do continue

        dist_enemy := linalg.distance(orb.pos, e.pos)
        if dist_enemy < orb.radius + e.radius {
            collision_normal := linalg.normalize0(orb.pos - e.pos)
            vel_dot_norm := linalg.dot(orb.vel, -collision_normal)

            if vel_dot_norm > 0.0 {
                // Separate bodies
                orb.pos = e.pos + collision_normal * (orb.radius + e.radius + 1.0)
                orb.vel = linalg.reflect(orb.vel, -collision_normal) * BALL_RESTITUTION

                // Check weak point hit
                weak_world_pos := e.pos + e.weak_offset
                dist_weak := linalg.distance(orb.pos, weak_world_pos)
                is_crit := dist_weak < (orb.radius + e.weak_radius)

                // Detailed elemental advantage, evolution tier, and combo
                elem_mult, effect, label := element_interaction(orb.element, e.element)
                orb.bounces += 1
                orb.combo += 1
                combo_mult := combo_multiplier_for_count(orb.combo)
                crit_mult : f32 = is_crit ? 2.2 : 1.0

                card_stage := game.card_stages[int(orb.element)]
                c_data := get_card_stage_data(orb.element, card_stage)
                evo_mult := c_data.power_mult

                base_dmg : f32 = 75.0
                total_damage := int(base_dmg * evo_mult * elem_mult * combo_mult * crit_mult)

                e.current_hp -= total_damage
                e.hurt_timer = 0.14
                game.score += total_damage

                // Trigger flashy combo popup when hitting 2+ targets
                if orb.combo >= 2 {
                    popup_col := is_crit ? rl.GOLD : element_secondary_color(orb.element)
                    add_combo_popup(e.pos, orb.combo, combo_mult, popup_col)
                }

                damage_col := is_crit ? rl.GOLD : ((effect == .RESISTED) ? rl.LIGHTGRAY : element_secondary_color(orb.element))
                add_damage_number(is_crit ? weak_world_pos : orb.pos, total_damage, is_crit, damage_col, label)

                if e.current_hp <= 0 {
                    e.current_hp = 0
                    e.alive = false
                    emit_burst(e.pos, element_primary_color(e.element), rl.WHITE, 45)
                    add_shockwave(e.pos, 68.0, element_primary_color(e.element))
                    add_screen_shake(8.5, 0.24)
                    game.score += 300 * game.current_wave
                } else {
                    emit_sparks(orb.pos, element_primary_color(e.element), is_crit ? 16 : 8, is_crit ? 340.0 : 200.0)
                    add_screen_shake(is_crit ? 5.5 : 3.0, 0.12)
                }
            }
        }
    }

    return true
}

// Ray-cast trajectory for aiming guide line with first wall reflection
Trajectory_Preview :: struct {
    start:       [2]f32,
    bounce_pt:   [2]f32,
    reflect_end: [2]f32,
    hit_wall:    bool,
}

calculate_trajectory :: proc(origin: [2]f32, dir: [2]f32, max_len: f32) -> Trajectory_Preview {
    preview: Trajectory_Preview
    preview.start = origin

    if linalg.length2(dir) == 0.0 {
        return preview
    }

    left_wall, right_wall, top_wall := arena_get_walls()
    walls := [3]Arena_Wall{left_wall, right_wall, top_wall}

    closest_t : f32 = max_len
    hit_normal := [2]f32{}
    hit_found := false

    for wall in walls {
        v1 := origin - wall.p1
        v2 := wall.p2 - wall.p1
        v3 := [2]f32{-dir.y, dir.x}

        dot := linalg.dot(v2, v3)
        if math.abs(dot) < 0.0001 do continue

        t1 := (v2.x * v1.y - v2.y * v1.x) / dot
        t2 := linalg.dot(v1, v3) / dot

        if t1 > 0.0 && t1 < closest_t && t2 >= 0.0 && t2 <= 1.0 {
            closest_t = t1
            hit_normal = wall.normal
            hit_found = true
        }
    }

    if hit_found {
        preview.bounce_pt = origin + dir * closest_t
        preview.hit_wall = true
        reflect_dir := linalg.normalize0(dir - 2.0 * linalg.dot(dir, hit_normal) * hit_normal)
        preview.reflect_end = preview.bounce_pt + reflect_dir * (max_len - closest_t) * 0.7
    } else {
        preview.bounce_pt = origin + dir * max_len
        preview.hit_wall = false
    }

    return preview
}

draw_aim_guide :: proc(preview: Trajectory_Preview, elem: Element) {
    col := element_secondary_color(elem)
    col.a = 210

    rl.DrawLineEx(preview.start, preview.bounce_pt, 2.5, col)
    rl.DrawCircleV(preview.bounce_pt, 5.0, col)

    if preview.hit_wall {
        reflect_col := col
        reflect_col.a = 140
        rl.DrawLineEx(preview.bounce_pt, preview.reflect_end, 2.0, reflect_col)
        rl.DrawCircleV(preview.reflect_end, 4.0, reflect_col)
    }
}
