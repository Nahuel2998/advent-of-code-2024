package solution

import "core:os"
import "core:strings"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 900
SCR_WIDTH  :: SCR_HEIGHT

LEVEL_FILENAME :: "input"
// LEVEL_FILENAME :: "example"

MIN_BETTER :: 50 when LEVEL_FILENAME == "example" else 100 

// PART :: 1
PART :: 2

camera : rl.Camera2D

pos        : Position
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
  Start,
  End,
}

track_i : i32
track   : map[Position]i32
track_r : [dynamic]Position

shortcuts : map[Position][dynamic]Position
Shortcut :: struct {
  pos  : Position,
  cost :      i32,
}

main :: proc() {
  context.logger = log.create_console_logger()
  
  rl.SetTargetFPS(30 when LEVEL_FILENAME == "example" else 240)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 20")
  defer rl.CloseWindow()
  
  Load()
  when PART == 1 do Part1()    
  else           do Part2()
}

Part1 :: proc() {
  fillTrack()
  Solve(2)
  for !rl.WindowShouldClose() {
    Draw()
  }
  
  res : int
  for _, shs in shortcuts do res += len(shs)
  fmt.println("Part 1:", res)
}

Part2 :: proc() {
  fillTrack()
  Solve(20)
  for !rl.WindowShouldClose() {
    Draw()
  }
  
  res : int
  for _, shs in shortcuts do res += len(shs)   
  fmt.println("Part 2:", res)
}

Solve :: proc(n : i32) {
  points := pointsInDistance(n)
  for k1, old_p in track {
    scuts := make([dynamic]Position)
    for p in points {
      k2        := k1 + p.pos
      new_p, ok := track[k2]
      if !ok do continue
        
      saved := new_p - p.cost - old_p
      if saved < MIN_BETTER do continue
        
      append(&scuts, k2)
    }
    shortcuts[k1] = scuts
  }
}

fillTrack :: proc() {
  for level[indexOf(pos)] != .End {
    track[pos] = track_i
    append(&track_r, pos) // NOTE: ugly, but I wanted a cool visualization
    track_i += 1

    dl: for dir in DIRECTION_VEC {
      new_pos := pos + dir
      if new_pos in track do continue 

      switch level[indexOf(new_pos)]  {
      case .Empty, .End:
        pos = new_pos
        break dl
      case .Start, .Wall:
      }
    }
  }
  track[pos] = track_i
  append(&track_r, pos)
}

pointsInDistance :: proc(n : i32) -> []Shortcut {
  m_res := make(map[Shortcut]struct{})
  for x in 0..=n {
    for y in 0..=n {
      cost := x + y
      if cost > n do continue
        
      p := Position{x, y}
      m_res[Shortcut{ { p.x,  p.y }, cost }] = {}
      m_res[Shortcut{ {-p.x,  p.y }, cost }] = {}
      m_res[Shortcut{ { p.x, -p.y }, cost }] = {}
      m_res[Shortcut{ {-p.x, -p.y }, cost }] = {}
    }
  }
  
  res := make([]Shortcut, len(m_res))
  i   : int
  for k in m_res {
    res[i] = k   
    i += 1
  } 

  return res
}

Load :: proc() {
  input := os.read_entire_file(LEVEL_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  level     = make([dynamic]Tile)
  
  for c in input {
    switch c {
    case '\n':
      if level_width == 0 do level_width = i32(len(level))
    case '.':
      append(&level, Tile.Empty)
    case '#':
      append(&level, Tile.Wall)
    case 'S':
      pos = posOf(i32(len(level)))
      append(&level, Tile.Start)
    case 'E':
      append(&level, Tile.End)
    }
  }
  
  camera = rl.Camera2D{
    zoom = SCR_HEIGHT / f32(level_width)
  }
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
      case .Start:
        rl.DrawPixel(pos.x, pos.y, rl.GREEN)
      case .End:
        rl.DrawPixel(pos.x, pos.y, rl.RED)
      case .Wall:
        rl.DrawPixel(pos.x, pos.y, rl.GRAY)
      case .Empty:
      }
    }

    when PART == 1 {
      for from in shortcuts do drawShortcutsFor(from)
    } else {
      drawShortcutsFor(track_r[track_i % i32(len(track))])
      track_i += 1
    }
  }
  rl.EndMode2D()
  
  rl.DrawFPS(10, 10)
  rl.EndDrawing()
}

drawShortcutsFor :: proc(from : Position) {
  shs := shortcuts[from] 
  if len(shs) == 0 do return

  rl.DrawPixel(from.x, from.y, rl.PURPLE)
  for to in shs {
    s := [2]rl.Vector2{ 
      { f32(from.x) + 0.5, f32(from.y) + 0.5 }, 
      { f32(  to.x) + 0.5, f32(  to.y) + 0.5 } 
    }
    rl.DrawPixel(to.x, to.y, rl.DARKPURPLE)
    rl.DrawLineStrip(raw_data(s[:]), 2, rl.MAGENTA)
  }
}