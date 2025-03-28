package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

WINDOW_HEIGHT :: 600
WINDOW_WIDTH :: WINDOW_HEIGHT

GRID_HEIGHT :: 30
GRID_WIDTH :: GRID_HEIGHT

GRID_CELL_HEIGHT :: WINDOW_HEIGHT / GRID_HEIGHT
GRID_CELL_WIDTH :: WINDOW_WIDTH / GRID_WIDTH

Direction :: enum{
    Up,
    Right,
    Down,
    Left
}
Direction_vecs := [Direction]rl.Vector2 {
	.Up    = { 0, -1 },
	.Right = { 1,  0 },
	.Down  = { 0,  1 },
	.Left  = {-1,  0 },
}

SNAKE_MAX_LENGHT :: GRID_HEIGHT * GRID_WIDTH
SNAKE_VELOCITY :: 8.0

GridPos :: struct {
    x, y: i32
}

Snake :: struct {
    body: [SNAKE_MAX_LENGHT] GridPos,
    body_len: u32,
    direction: Direction,
    next_direction: Direction,
    dead: bool,
}

GameState :: struct {
    snake: Snake,
    fruit_pos: GridPos,
    score: int,
}

is_snake_body :: proc(snake: ^Snake, pos: GridPos) -> bool {
    for i in 0..<snake.body_len {
        if snake.body[i] == pos {
            return true;
        }
    }

    return false;
}

get_left_circular :: proc(index: int, array: []$T) -> T {
    if index == 0 {
        return array[len(array)-1]
    }

    return array[index-1]
}

get_right_circular :: proc(index: int, array: []$T) -> T {
    return array[(index+1) % len(array)]
}


update_snake_direction :: proc(state: ^GameState) {
    keys := [4]rl.KeyboardKey{ .W, .D, .S, .A }
    directions := [4]Direction{ .Up, .Right, .Down, .Left }
    assert(len(keys) == len(Direction_vecs))

    for key, i in keys {
        if (rl.IsKeyPressed(key) && (
                state.snake.direction == get_left_circular(i, directions[:])
                || state.snake.direction == get_right_circular(i, directions[:])
            )
        ) {
            state.snake.next_direction = directions[i]; 
            return;
        }
    }
}

update_snake_position :: proc(state: ^GameState) {
    state.snake.direction = state.snake.next_direction

    for i in 0..<state.snake.body_len-1 {
        state.snake.body[i].x = state.snake.body[i+1].x
        state.snake.body[i].y = state.snake.body[i+1].y
    }

    new_head_pos := GridPos {
        x = (state.snake.body[state.snake.body_len-1].x
            + cast(i32) Direction_vecs[state.snake.direction].x),
        y = (state.snake.body[state.snake.body_len-1].y
            + cast(i32) Direction_vecs[state.snake.direction].y)
    }

    if (
        is_snake_body(&state.snake, new_head_pos) 
        || !rl.CheckCollisionPointRec(
                { cast(f32) new_head_pos.x, cast(f32) new_head_pos.y },
                rl.Rectangle { 0, 0, GRID_WIDTH, GRID_HEIGHT}
            )
    ) {
        state.snake.dead = true;
        return
    }

    if new_head_pos == state.fruit_pos {

        state.score += 1
        // add body (use fruit_pos for the new head)
        state.snake.body[state.snake.body_len] = state.fruit_pos
        state.snake.body_len += 1

        spawn_fruit(state)
    } else {
        // update head_pos
        state.snake.body[state.snake.body_len-1] = new_head_pos
    }
}


draw :: proc(state: ^GameState) {
    for i in 0..<state.snake.body_len {
        rl.DrawRectangle(
            state.snake.body[i].x * GRID_CELL_WIDTH,
            state.snake.body[i].y * GRID_CELL_HEIGHT,
            GRID_CELL_WIDTH,
            GRID_CELL_HEIGHT,
            rl.GREEN
        )

        rl.DrawRectangleLines(
            state.snake.body[i].x * GRID_CELL_WIDTH,
            state.snake.body[i].y * GRID_CELL_HEIGHT,
            GRID_CELL_WIDTH,
            GRID_CELL_HEIGHT,
            rl.WHITE
        )
    }

    rl.DrawRectangle(
        state.fruit_pos.x * GRID_CELL_WIDTH,
        state.fruit_pos.y * GRID_CELL_HEIGHT,
        GRID_CELL_WIDTH,
        GRID_CELL_HEIGHT,
        rl.RED
    )

    rl.DrawText(fmt.ctprintf("Score: %d", state.score), 25, 25, 20, rl.RAYWHITE)

    if state.snake.dead {
        rl.DrawText("you died!", 20 + WINDOW_WIDTH / 3 , WINDOW_HEIGHT / 2, 40, rl.RAYWHITE)
        rl.DrawText("press enter to restart", 20 + WINDOW_WIDTH / 3 , 50 + WINDOW_HEIGHT / 2, 15, rl.WHITE)
    }
}

spawn_fruit :: proc(state: ^GameState) {
    fruit_pos := GridPos {
        x = rand.int31_max(GRID_WIDTH),
        y = rand.int31_max(GRID_HEIGHT)
    }

    for is_snake_body(&state.snake, fruit_pos) {
        fruit_pos = GridPos {
            x = rand.int31_max(GRID_WIDTH),
            y = rand.int31_max(GRID_HEIGHT)
        }
    }

    state.fruit_pos = fruit_pos
}

main :: proc() {
    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "snake")

    rl.SetTargetFPS(60)

    DEFAULT_STATE :: GameState {
        snake = Snake {
            direction = .Left,
            body_len = 2,
            body = {
                1 = { GRID_WIDTH / 2, GRID_HEIGHT / 2},
                0 = { 1 + GRID_WIDTH / 2, GRID_HEIGHT / 2}
            },
        },
    }

    state := DEFAULT_STATE

    spawn_fruit(&state)

    start := rl.GetTime()
    for !rl.WindowShouldClose() {

        if state.snake.dead == true && rl.IsKeyPressed(.ENTER) {
            state = DEFAULT_STATE
            start = rl.GetTime()
        }

        update_snake_direction(&state)

        if !state.snake.dead && rl.GetTime() - start > 1.0 / SNAKE_VELOCITY {
            start = rl.GetTime()
            update_snake_position(&state)
        }

        rl.BeginDrawing()

        {
            rl.ClearBackground(rl.DARKGRAY)
            draw(&state)
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
