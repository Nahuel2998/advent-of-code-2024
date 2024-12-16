package odin

import "core:os"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

SCR_HEIGHT :: 900
SCR_WIDTH  :: SCR_HEIGHT

CANVAS_HEIGHT :: 103
CANVAS_WIDTH  :: 101
// CANVAS_HEIGHT :: 7
// CANVAS_WIDTH  :: 11

INPUT_FILENAME :: "input"
// INPUT_FILENAME :: "example"

camera : rl.Camera2D

robots : [dynamic]Robot
Robot :: struct {
  using pos : [2]i32,
  vel       : [2]i32,
  color     : rl.Color,
}

main :: proc() {
  context.logger = log.create_console_logger()
  
  rl.SetTargetFPS(120)
  // rl.SetTargetFPS(15)
  rl.InitWindow(SCR_WIDTH, SCR_HEIGHT, "Day 14")
  defer rl.CloseWindow()
  
  Load()
  // SolvePart1()
  SolvePart2()
}

SolvePart1 :: proc() {
  i : int
  for !rl.WindowShouldClose() && i < 100 {
    Step()
    Draw()
    i += 1
  }
  
  cuadrants :  [4]int
  cuad_x    := i32(CANVAS_WIDTH  / 2)
  cuad_y    := i32(CANVAS_HEIGHT / 2)
  for robot in robots {
    if robot.x == cuad_x || robot.y == cuad_y do continue
    cuadrants[int(robot.x < cuad_x) + int(robot.y < cuad_y) * 2] += 1
  }
  
  res : int = 1
  for c in cuadrants do res *= c

  fmt.println(res)
}

SolvePart2 :: proc() {
  i : i32
  for !rl.WindowShouldClose() {
    mul : i32 = rl.IsKeyDown(.RIGHT) ? 1 : rl.IsKeyDown(.LEFT) ? -1 : 0
    
    if mul != 0 {
      Step(mul)
      i += mul
    }

    Draw()
    fmt.println(i)
  }
}

Load :: proc() {
  robot_data := os.read_entire_file(INPUT_FILENAME, context.temp_allocator) or_else log.panicf("what where")
  robots = make([dynamic]Robot)
  
  for s in strings.split_lines(string(robot_data), context.temp_allocator) {
    parts := strings.split(s, " ", context.temp_allocator)

    p := strings.split(parts[0], ",", context.temp_allocator)
    v := strings.split(parts[1], ",", context.temp_allocator)
    
    append(&robots, Robot{
      { i32(strconv.atoi(p[0][2:])), i32(strconv.atoi(p[1])) },
      { i32(strconv.atoi(v[0][2:])), i32(strconv.atoi(v[1])) },
      rl.Color{
        u8(rl.GetRandomValue(128, 200)), 
        u8(rl.GetRandomValue(128, 200)), 
        u8(rl.GetRandomValue(128, 200)), 
        255,
      }
    }) 
  }
  
  fmt.println("Robots:", len(robots))

  camera = rl.Camera2D{
    zoom = SCR_WIDTH / f32(CANVAS_WIDTH)
  }
}

Step :: proc(mul : i32 = 1) {
  for &robot in robots {
    robot.pos += robot.vel * mul 
    
    if robot.x < 0 do robot.x += CANVAS_WIDTH
    if robot.y < 0 do robot.y += CANVAS_HEIGHT

    robot.x %= CANVAS_WIDTH
    robot.y %= CANVAS_HEIGHT
  }
}

Draw :: proc() {
  rl.BeginDrawing()
  rl.ClearBackground(rl.DARKGRAY - 25)
  
  rl.BeginMode2D(camera)
  {
    for robot, i in robots {
      rl.DrawPixel(robot.x, robot.y, robot.color)
    }
  }
  rl.EndMode2D()

  rl.DrawFPS(10, SCR_HEIGHT - 30)
  rl.EndDrawing()
}