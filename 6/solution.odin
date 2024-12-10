package solution

import "core:os"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 750
SCR_WIDTH  :: SCR_HEIGHT

LEVEL_FILENAME :: "input"

camera : rl.Camera2D
guard  : Guard
Guard :: struct {
  using pos :  Position,
  dir       : Direction,
}
Position  :: [2]i32
Direction :: enum {
  Up,
  Right,
  Down,
  Left,
}
DIRECTION_VEC := [Direction]Position {
  .Up    = { 0, -1},
  .Right = {+1,  0},
  .Down  = { 0, +1},
  .Left  = {-1,  0},
}

level_width : i32
level  : []Tile
Tile  :: enum {
  Empty, 
  Wall,
  Visited_Up,
  Visited_Right,
  Visited_Down,
  Visited_Left,
}

init : Simulation
Simulation :: struct {
  guard :         Guard,  
  level : [dynamic]Tile,
}

visited := 0
loops   := 0

main :: proc() {
  context.logger = log.create_console_logger()
  
  // rl.SetTargetFPS(512)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 6")
  defer rl.CloseWindow()
  
  Load()
  // Part1()
  Part2()
}

Part1 :: proc() {
  Reset()
  for !rl.WindowShouldClose() {
    if !Step() && visited == 0 {
      for tile in level {
        #partial switch tile {
        case .Visited_Down, .Visited_Left, .Visited_Right, .Visited_Up: visited += 1
        }
      }
      fmt.println("Part 1:", visited)
    }
    Draw()
  }
}

Part2 :: proc() {
  Reset()
  
  indexes := make(map[int]struct{})
  for Step() do indexes[indexOf(guard.pos)] = {}

  for i in indexes {
    Reset()
    if level[i] != .Empty do continue

    level[i] = .Wall
    for !rl.WindowShouldClose() && Step() do Draw()
  }
  
  fmt.println("Part 2:", loops)
  for !rl.WindowShouldClose() do Draw()
}

Load :: proc() {
  level_data := os.read_entire_file(LEVEL_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  
  init.level = make([dynamic]Tile)
  
  guard_pos : i32
  for c in level_data {
    switch c{
    case '\n':
      if level_width == 0 do level_width = i32(len(init.level))
    case '.':
      append(&init.level, Tile.Empty)
    case '#':
      append(&init.level, Tile.Wall)
    case '^', '>', 'v', '<':
      guard_pos = i32(len(init.level))

      switch c {
      case '^': init.guard.dir = .Up
      case '>': init.guard.dir = .Right
      case 'v': init.guard.dir = .Down
      case '<': init.guard.dir = .Left
      }

      append(&init.level, visitedDir(init.guard.dir))
    }
  }
  
  init.guard.pos = {guard_pos % level_width, guard_pos / level_width}

  level = make([]Tile, len(init.level))
  camera = rl.Camera2D{
    zoom = SCR_HEIGHT / f32(level_width)
  }
}

Reset :: proc() {
  visited = 0

  guard = init.guard
  copy(level, init.level[:])
}

Step :: proc() -> bool {
  new_pos := guard.pos + DIRECTION_VEC[guard.dir]
  index   := indexOf(new_pos)
  
  if !rl.CheckCollisionPointRec(
    { f32(new_pos.x),         f32(new_pos.y) }, 
    { 0, 0, f32(level_width), f32(level_width) },
  ) { return false }
    
  if level[index] == .Wall {
    guard.dir = turn(guard.dir)
    return Step()
  }
  
  new_tile := visitedDir(guard.dir)
  if level[index] == new_tile {
    fmt.println("Looped", guard.pos)
    loops += 1
    return false
  }
  
  level[index] = new_tile
  guard.pos    = new_pos
  
  return true
}

visitedDir :: proc(dir : Direction) -> Tile {
  return Tile(i32(Tile.Visited_Up) + i32(guard.dir)) 
}

turn :: proc(dir : Direction, clockwise : i32 = 1) -> Direction {
  return Direction((i32(dir) + clockwise) % 4)    
}

indexOf :: proc(pos : Position) -> int {
  return int(pos.y * level_width + pos.x)
}

Draw :: proc() {
  rl.BeginDrawing()
  rl.ClearBackground(rl.RAYWHITE)
  
  rl.BeginMode2D(camera)
  {
    for tile, i in level {
      pos := Position{ i32(i) % level_width, i32(i) / level_width }
      switch tile {
      case .Visited_Down, .Visited_Left, .Visited_Right, .Visited_Up:
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