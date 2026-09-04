package hellfire

import "core:math"
import rl "vendor:raylib"

WINDOW_INIT_WIDTH  : i32 : 540
WINDOW_INIT_HEIGHT : i32 : 960

main :: proc() {
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT, .MSAA_4X_HINT})
    rl.InitWindow(WINDOW_INIT_WIDTH, WINDOW_INIT_HEIGHT, "Hellfire: Card Flick Dungeon Crawler")
    defer rl.CloseWindow()

    rl.SetWindowMinSize(360, 640)
    rl.SetTargetFPS(60)

    target := rl.LoadRenderTexture(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    defer rl.UnloadRenderTexture(target)
    rl.SetTextureFilter(target.texture, .BILINEAR)

    init_card_textures()
    defer unload_card_textures()

    game_init()

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        // Clamp dt to avoid physics spiral on lag spikes or window drags
        if dt > 0.05 do dt = 0.05

        // Window size and letterbox scaling
        win_w := f32(rl.GetScreenWidth())
        win_h := f32(rl.GetScreenHeight())
        scale := math.min(win_w / f32(VIRTUAL_WIDTH), win_h / f32(VIRTUAL_HEIGHT))

        offset_x := (win_w - f32(VIRTUAL_WIDTH) * scale) * 0.5
        offset_y := (win_h - f32(VIRTUAL_HEIGHT) * scale) * 0.5

        // Map mouse coordinates into virtual 720x1280 space
        raw_mouse_x := f32(rl.GetMouseX())
        raw_mouse_y := f32(rl.GetMouseY())
        virtual_mouse_x := (raw_mouse_x - offset_x) / scale
        virtual_mouse_y := (raw_mouse_y - offset_y) / scale
        virtual_mouse := [2]f32{virtual_mouse_x, virtual_mouse_y}

        mouse_pressed  := rl.IsMouseButtonPressed(.LEFT)
        mouse_down     := rl.IsMouseButtonDown(.LEFT)
        mouse_released := rl.IsMouseButtonReleased(.LEFT)

        // Game Update
        game_update(dt, virtual_mouse, mouse_pressed, mouse_down, mouse_released)

        // Screen Shake calculation for render target
        shake_offset := update_screen_shake(0.0) // peek offset

        // Render to Virtual Target
        rl.BeginTextureMode(target)
        rl.ClearBackground(COLOR_BG_VOID)
        game_draw()
        rl.EndTextureMode()

        // Present to Window with Letterboxing
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        dest_rect := rl.Rectangle{
            offset_x + shake_offset.x * scale,
            offset_y + shake_offset.y * scale,
            f32(VIRTUAL_WIDTH) * scale,
            f32(VIRTUAL_HEIGHT) * scale,
        }

        // Raylib render textures are Y-flipped in OpenGL
        src_rect := rl.Rectangle{0, 0, f32(VIRTUAL_WIDTH), -f32(VIRTUAL_HEIGHT)}
        rl.DrawTexturePro(target.texture, src_rect, dest_rect, {0, 0}, 0.0, rl.WHITE)

        rl.EndDrawing()
    }
}

