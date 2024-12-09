package solution

import "core:os"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 750
SCR_WIDTH  :: SCR_HEIGHT

LEVEL_FILENAME :: "input"

camera : rl.Camera2D
guard  : struct {
  using pos :    [2]i32,
  dir       : Direction,
}
Direction :: enum {
  Up,
  Right,
  Down,
  Left,
}
DIRECTION_VEC := [Direction][2]i32 {
  .Up    = { 0, -1},
  .Right = {+1,  0},
  .Down  = { 0, +1},
  .Left  = {-1,  0},
}

level_width : i32
level  : [dynamic]Tile
Tile  :: enum {
  Empty, 
  Wall,
  Visited,
}

result := 0

main :: proc() {
  context.logger = log.create_console_logger()
  
  rl.SetTargetFPS(512)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 6")
  defer rl.CloseWindow()
  
  Init()
  for !rl.WindowShouldClose() {
    if !Update() && result == 0 {
      for tile in level {
        if tile == .Visited do result += 1
      }
      fmt.println("Part 1:", result)
    }
    Draw()
  }
}

Init :: proc() {
  level_data := os.read_entire_file(LEVEL_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  
  level = make([dynamic]Tile)
  
  guard_pos : i32
  for c in level_data {
    switch c{
    case '\n':
      if level_width == 0 do level_width = i32(len(level))
    case '.':
      append(&level, Tile.Empty)
    case '#':
      append(&level, Tile.Wall)
    case '^', '>', 'v', '<':
      guard_pos = i32(len(level))
      append(&level, Tile.Visited)

      switch c {
      case '^': guard.dir = .Up
      case '>': guard.dir = .Right
      case 'v': guard.dir = .Down
      case '<': guard.dir = .Left
      }
    }
  }
  
  guard.pos = {guard_pos % level_width, guard_pos / level_width}

  camera = rl.Camera2D{
    zoom = SCR_HEIGHT / f32(level_width)
  }
}

Update :: proc() -> bool {
  new_pos := guard.pos + DIRECTION_VEC[guard.dir]
  index   := indexOf(new_pos)
  if index > len(level) || index < 0 do return false
    
  if level[index] == .Wall {
    guard.dir = turn(guard.dir)
    return true
  }
  
  level[index] = .Visited
  guard.pos    = new_pos
  
  return true
}

turn :: proc(dir : Direction, clockwise : i32 = 1) -> Direction {
  return Direction((i32(dir) + clockwise) % 4)    
}

indexOf :: proc(pos : [2]i32) -> int {
  return int(pos.y * level_width + pos.x)
}

Draw :: proc() {
  rl.BeginDrawing()
  rl.ClearBackground(rl.RAYWHITE)
  
  rl.BeginMode2D(camera)
  {
    for tile, i in level {
      pos := [2]i32{ i32(i) % level_width, i32(i) / level_width }
      switch tile {
      case .Visited:
        rl.DrawPixel(pos.x, pos.y, rl.DARKGREEN)
      case .Wall:
        rl.DrawPixel(pos.x, pos.y, rl.MAROON)
      case .Empty:
      }
    }

    rl.DrawPixel(guard.x, guard.y, rl.GREEN)
  }
  rl.EndMode2D()
  
  rl.DrawFPS(10, 10)
  rl.EndDrawing()
}