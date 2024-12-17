package solution

import "core:os"
import "core:strings"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 900
SCR_WIDTH  :: SCR_HEIGHT

LEVEL_FILENAME :: "../input"
// LEVEL_FILENAME :: "../example"
// LEVEL_FILENAME :: "../test"

camera : rl.Camera2D
robot  : Robot
Robot :: struct {
  using pos :           Position,
  moves     : [dynamic]Direction,
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
level  : [dynamic]Tile
Tile  :: enum {
  Empty, 
  Wall,
  Box_L,
  Box_R,
}

main :: proc() {
  context.logger = log.create_console_logger()
  
  rl.SetTargetFPS(512)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 15 Part 2")
  defer rl.CloseWindow()
  
  Load()
  Part2()
}

Part2 :: proc() {
  for !rl.WindowShouldClose() {
    Step()
    Draw()
  }
  
  res : i32
  for tile, i in level {
    if tile == .Box_L {
      pos := posOf(i32(i))
      res += pos.x + pos.y * 100
    }
  }
  fmt.println("Part 2:", res)
}

Load :: proc() {
  input := os.read_entire_file(LEVEL_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  data  := strings.split(string(input), "\n\n", context.temp_allocator)

  level_data, mov_data := data[0], data[1]
  
  level = make([dynamic]Tile)
  
  robot_pos : i32
  for c in level_data {
    switch c {
    case '\n':
      if level_width == 0 do level_width = i32(len(level))
    case '.':
      append(&level, Tile.Empty, Tile.Empty)
    case '#':
      append(&level, Tile.Wall, Tile.Wall)
    case 'O':
      append(&level, Tile.Box_L, Tile.Box_R)
    case '@':
      robot_pos = i32(len(level))

      append(&level, Tile.Empty, Tile.Empty)
    }
  }
  
  robot.pos = posOf(robot_pos)
  robot.moves = make([dynamic]Direction)
  
  #reverse for c in mov_data {
    switch c {
    case '^':
      append(&robot.moves, Direction.Up)
    case 'v':
      append(&robot.moves, Direction.Down)
    case '>':
      append(&robot.moves, Direction.Right)
    case '<':
      append(&robot.moves, Direction.Left)
    }
  }

  camera = rl.Camera2D{
    zoom = SCR_HEIGHT / f32(level_width)
  }
}

Step :: proc() -> bool {
  if len(robot.moves) == 0 do return false
    
  dir := pop(&robot.moves)
  new_pos := robot.pos + DIRECTION_VEC[dir]

  if push(new_pos, dir, dry_run=true) {
    push(new_pos, dir)
    robot.pos = new_pos
    level[indexOf(new_pos)] = .Empty
  }

  return true
}

// NOTE: Ugly :(
push :: proc(pos : Position, dir: Direction, dry_run : bool = false, complement : bool = false) -> bool {
  tile := level[indexOf(pos)] 
  switch tile {
  case .Empty: return true
  case .Box_L, .Box_R:
    if dir == .Left || dir == .Right || complement {
      new_pos := pos + DIRECTION_VEC[dir]
      
      can_push := push(new_pos, dir, dry_run) 
      if dry_run do return can_push

      if can_push {
        level[indexOf(new_pos)] = tile
        return true
      }
      return false
    }

    cmp_pos : Position
    new_pos := pos + DIRECTION_VEC[dir]
    if tile == .Box_L {
      cmp_pos = pos + DIRECTION_VEC[.Right]
    } else {
      cmp_pos = pos + DIRECTION_VEC[.Left]
    }

    can_push := push(new_pos, dir, dry_run) && push(cmp_pos, dir, dry_run, complement=true)  
    if dry_run do return can_push

    if can_push {
      level[indexOf(new_pos)] = tile

      level[indexOf(pos)]     = .Empty
      level[indexOf(cmp_pos)] = .Empty
      return true
    }
  case .Wall:
  }
  return false
}

indexOf :: proc(pos : Position) -> int {
  return int(pos.y * level_width + pos.x)
}

posOf :: proc(index : i32) -> Position {
  return {index % level_width, index / level_width}
}

Draw :: proc() {
  rl.BeginDrawing()
  rl.ClearBackground(rl.RAYWHITE)
  
  rl.BeginMode2D(camera)
  {
    for tile, i in level {
      pos := Position{ i32(i) % level_width, i32(i) / level_width }
      switch tile {
      case .Box_L:
        rl.DrawPixel(pos.x, pos.y, rl.MAROON)
      case .Box_R:
        rl.DrawPixel(pos.x, pos.y, rl.RED)
      case .Wall:
        rl.DrawPixel(pos.x, pos.y, rl.GRAY)
      case .Empty:
      }
    }

    rl.DrawPixel(robot.x, robot.y, rl.GREEN)
  }
  rl.EndMode2D()
  
  rl.DrawFPS(10, 10)
  rl.EndDrawing()
}