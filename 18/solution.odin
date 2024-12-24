package solution

import "core:os"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 900
SCR_WIDTH  :: SCR_HEIGHT

INPUT_FILENAME :: "input"
// INPUT_FILENAME :: "example"

CANVAS_WIDTH  :: 7 when INPUT_FILENAME == "example" else 71
CANVAS_HEIGHT :: CANVAS_WIDTH

camera : rl.Camera2D

grid : [CANVAS_HEIGHT * CANVAS_WIDTH]Tile
Tile :: enum {
  Empty,  
  Corrupted,
  Visited,
}

to_fall   : int
corrupted : [dynamic]int

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
Position :: [2]int

player : Position

main :: proc() {
  context.logger = log.create_console_logger()
  
  rl.SetTargetFPS(120)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 18")
  defer rl.CloseWindow()
  
  Load()
  // Part1()
  Part2()
}

Part1 :: proc() {
  i : int
  step_for := INPUT_FILENAME == "example" ? 12 : 1024
  for !rl.WindowShouldClose() {
    if i < step_for do Step()
    else do Move()
    i += 1
    Draw()
  }
  
  res : int
  for tile in grid {
    if tile == .Visited do res += 1
  }
  fmt.println("Part 1:", res - 1)
}

Part2 :: proc() {
  step_for := 1024
  solved : bool

  for !rl.WindowShouldClose() {
    if !solved {
      Reset()
      for _ in 0..<step_for do Step()     
      floodFill({0, 0})
      if grid[indexOf({70, 70})] != .Visited do solved = true

      // CONSIDER: Binary search would've been nice here
      //           But doesn't look as cool when animated
      step_for += 1
    }
    Draw()
  }
  
  fmt.println("Part 2:", posOf(corrupted[to_fall - 1]))
}

Reset :: proc() {
  slice.fill(grid[:], Tile.Empty)
  to_fall = 0
}

Load :: proc() {
  ram_data := os.read_entire_file(INPUT_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  corrupted = make([dynamic]int)
  
  for s in strings.split_lines(string(ram_data), context.temp_allocator) {
    xy := strings.split(s, ",", context.temp_allocator)
    if len(xy) < 2 do continue
    append(&corrupted, indexOf({ strconv.atoi(xy[0]), strconv.atoi(xy[1]) }))
  }

  camera = rl.Camera2D{
    zoom = SCR_WIDTH / f32(CANVAS_WIDTH)
  }
}

Step :: proc() {
  if to_fall >= len(corrupted) do return
    
  grid[corrupted[to_fall]] = .Corrupted
  to_fall += 1
}

Move :: proc() {
  #partial switch rl.GetKeyPressed() {
  case .LEFT:
    player += DIRECTION_VEC[.Left]
  case .RIGHT:
    player += DIRECTION_VEC[.Right]
  case .UP:
    player += DIRECTION_VEC[.Up]
  case .DOWN:
    player += DIRECTION_VEC[.Down]
  }
  grid[indexOf(player)] = .Visited
}

// NOTE: Pathfinding? What's that?
floodFill :: proc(pos : Position) {
  if pos.x < 0 || pos.x >= CANVAS_WIDTH  || 
     pos.y < 0 || pos.y >= CANVAS_HEIGHT { return; }

  i := indexOf(pos)

  tile := grid[i] 
  if tile != .Empty do return
    
  grid[i] = .Visited
  for dir in DIRECTION_VEC {
    floodFill(pos + dir)    
  }
}

indexOf :: proc(pos : Position) -> int {
  return int(pos.y * CANVAS_WIDTH + pos.x)
}

posOf :: proc(index : int) -> Position {
  return {index % CANVAS_WIDTH, index / CANVAS_WIDTH}
}

Draw :: proc() {
  rl.BeginDrawing()
  rl.ClearBackground(rl.DARKGRAY - 25)
  
  rl.BeginMode2D(camera)
  {
    for tile, i in grid {
      pos := Position{ i % CANVAS_WIDTH, i / CANVAS_WIDTH }
      switch tile {
      case .Visited:        
        rl.DrawPixel(i32(pos.x), i32(pos.y), rl.DARKGREEN)
      case .Corrupted:        
        rl.DrawPixel(i32(pos.x), i32(pos.y), rl.RAYWHITE)
      case .Empty:        
      }
    }
  }
  rl.EndMode2D()

  rl.DrawFPS(10, SCR_HEIGHT - 30)
  rl.EndDrawing()
}