package hellfire

import rl "vendor:raylib"

// Virtual Resolution (9:16 Portrait)
VIRTUAL_WIDTH  : i32 : 720
VIRTUAL_HEIGHT : i32 : 1280

// Arena Geometry (2.5D Perspective Dungeon Room)
ARENA_TOP           : f32 : 180.0
ARENA_BOTTOM        : f32 : 1060.0
ARENA_TOP_HALF_W    : f32 : 230.0 // Top wall extends from 360 - 230 to 360 + 230
ARENA_BOTTOM_HALF_W : f32 : 330.0 // Bottom extends from 360 - 330 to 360 + 330
ARENA_CENTER_X      : f32 : 360.0

// Summoning & Launch Pad
LAUNCH_PAD_POS : [2]f32 : {360.0, 1010.0}
LAUNCH_PAD_RADIUS : f32 : 44.0
MAX_PULL_DISTANCE : f32 : 130.0
LAUNCH_SPEED_MULT : f32 : 10.5
MAX_LAUNCH_SPEED  : f32 : 1650.0

// Physics Constants
BALL_BASE_RADIUS : f32 : 18.0
BALL_RESTITUTION : f32 : 0.88
BALL_DRAG        : f32 : 0.9985
BALL_MIN_SPEED   : f32 : 35.0

// Theme Colors
COLOR_BG_VOID       :: rl.Color{10, 8, 14, 255}
COLOR_DUNGEON_FLOOR :: rl.Color{24, 20, 30, 255}
COLOR_DUNGEON_WALL  :: rl.Color{45, 38, 54, 255}
COLOR_WALL_BORDER   :: rl.Color{78, 66, 92, 255}
COLOR_WALL_TRIM     :: rl.Color{140, 115, 75, 255} // Antique bronze/gold

COLOR_FIRE_PRIMARY   :: rl.Color{255, 75, 40, 255}
COLOR_FIRE_SECONDARY :: rl.Color{255, 180, 50, 255}
COLOR_WATER_PRIMARY  :: rl.Color{35, 130, 255, 255}
COLOR_WATER_SECONDARY:: rl.Color{90, 220, 255, 255}
COLOR_EARTH_PRIMARY  :: rl.Color{40, 190, 75, 255}
COLOR_EARTH_SECONDARY:: rl.Color{140, 240, 100, 255}
COLOR_CHAOS_PRIMARY  :: rl.Color{180, 45, 240, 255}
COLOR_CHAOS_SECONDARY:: rl.Color{230, 120, 255, 255}
COLOR_LIGHT_PRIMARY  :: rl.Color{255, 225, 100, 255}
COLOR_LIGHT_SECONDARY:: rl.Color{255, 255, 220, 255}

COLOR_RUNE_GLOW :: rl.Color{255, 175, 50, 180}
COLOR_TEXT_GOLD :: rl.Color{245, 215, 130, 255}

