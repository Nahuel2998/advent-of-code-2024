package solution

import "core:os"
import "core:slice"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 900
SCR_WIDTH  :: SCR_HEIGHT

CANVAS_WIDTH :: 315
// CANVAS_WIDTH :: 20 

DISK_FILENAME :: "input"
// DISK_FILENAME :: "example"

camera : rl.Camera2D
disk   : [dynamic]int
colors : []rl.Color

files : [dynamic]File
File :: struct {
  position : int,
  length   : int,
}

solver : Solver
Solver :: struct {
  i : int,
  j : int,
  solved : bool,
}

main :: proc() {
  context.logger = log.create_console_logger()
  
  rl.SetTargetFPS(60)
  // rl.SetTargetFPS(1)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 9")
  defer rl.CloseWindow()
  
  Load()
  // Solve(StepPart1)
  Solve(StepPart2)
}

Solve :: proc(Step : proc()) {
  for !rl.WindowShouldClose() {
    for _ in 0..<20 do Step()
    // Step()
    Draw()

    if solver.solved do break
  }
  
  res := 0
  for cell, i in disk {
    if cell == -1 do continue
    res += i * cell
  }
  
  fmt.println("Result:", res)
}

Load :: proc() {
  disk_data := os.read_entire_file(DISK_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  disk, files = make([dynamic]int), make([dynamic]File)

  file, is_file := 0, true
  for c in disk_data {
    if c == '\n' do break
    pos, len := len(disk), int(c - '0')
    
    for _ in '0'..<c do append(&disk, is_file ? file : -1)

    if is_file {
      append(&files, File{ pos, len })
      file += 1
    } 
    is_file = !is_file
  }
  
  colors = make([]rl.Color, file)
  for i in 0..<file {
    colors[i] = rl.Color{
      u8(rl.GetRandomValue(128, 200)), 
      u8(rl.GetRandomValue(128, 200)), 
      u8(rl.GetRandomValue(128, 200)), 
      255,
    }
  }
  
  fmt.println("Files:", file)
  fmt.println("Cells:", len(disk))
  
  solver.j = len(disk) - 1

  camera = rl.Camera2D{
    zoom = SCR_HEIGHT / f32(CANVAS_WIDTH)
  }
}

StepPart1 :: proc() {
  using solver
  
  if solved do return
  
  for disk[i] != -1          do i += 1
  for disk[j] == -1 && j > i do j -= 1
    
  if i >= j {
    solved = true   
    return
  } 
  
  disk[i] = disk[j]
  disk[j] = -1
}

StepPart2 :: proc() {
  if len(files) == 0 {
    solver.solved = true
    return
  }

  file := pop(&files)
  
  start := 0
  for start < file.position {
    for start < file.position && disk[start] != -1 do start += 1

    end := start
    for end < len(disk) && disk[end] == -1 {
      end += 1
      if end - start >= file.length {
        slice.fill(disk[start : end], disk[file.position])
        slice.fill(disk[file.position : file.position + file.length], -1)
        return
      }
    }

    start = end
  }
}

Draw :: proc() {
  rl.BeginDrawing()
  rl.ClearBackground(rl.DARKGRAY - 25)
  
  rl.BeginMode2D(camera)
  {
    for cell, i in disk {
      x, y := i32(i % CANVAS_WIDTH), i32(i / CANVAS_WIDTH)
      rl.DrawPixel(x, y, cell < 0 ? rl.GRAY - 20 : colors[cell])
    }
  }
  rl.EndMode2D()

  rl.DrawFPS(10, SCR_HEIGHT - 30)
  rl.EndDrawing()
}