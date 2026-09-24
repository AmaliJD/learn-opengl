package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"
import "core:math/linalg"

import "vendor:glfw"
import gl "vendor:OpenGL"
import "glx"
import stbi "vendor:stb/image"


// ----------------------------------------------------------------------------------------------------------- game data
player: GameObject
PLAYER_VELOCITY :: f32(500)
PLAYER_SIZE :: vec2{100, 20}

ball: Ball_GameObject
INITIAL_BALL_VELOCITY :: vec2{100, -350}
BALL_RADIUS :: 12.5

Direction :: enum
{
    Up, Right, Down, Left
}

// ----------------------------------------------------------------------------------------------------------- game class
Game :: struct
{
    state: Game_State,
    keys: [1024]bool,
    width, height: u32,

    levels: [dynamic]Level,
    level: u32
}

Game_State :: enum
{
    Active,
    Menu,
    Win
}

create_game :: proc(width, height: u32) -> Game
{
    return Game {
        state = .Active,
        width = width,
        height = height,
    }
}

init_game :: proc(game: ^Game)
{
    projection := linalg.matrix_ortho3d(0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, -1, 1)

    rm_create_shader("assets/shaders/sprite.vert", "assets/shaders/sprite.frag", "sprite")
    sprite_shader := rm_get_shader("sprite")
    use_shader(sprite_shader)

    shader_set_int(sprite_shader, "image", 0)
    shader_set_mat4(sprite_shader, "projection", projection)

    sp = create_sprite_renderer(sprite_shader)

    // load textures
    rm_create_texture2d("assets/images/awesomeface.png", true, "face")
    rm_create_texture2d("assets/images/background.jpg", false, "background")
    rm_create_texture2d("assets/images/block.png", false, "block")
    rm_create_texture2d("assets/images/block_solid.png", false, "block_solid")
    rm_create_texture2d("assets/images/paddle.png", true, "paddle")

    // load levels
    one := create_and_load_level("assets/levels/one.lvl", game.width, game.height / 2)
    two := create_and_load_level("assets/levels/two.lvl", game.width, game.height / 2)
    three := create_and_load_level("assets/levels/three.lvl", game.width, game.height / 2)
    four := create_and_load_level("assets/levels/four.lvl", game.width, game.height / 2)

    append(&game.levels, one)
    append(&game.levels, two)
    append(&game.levels, three)
    append(&game.levels, four)

    // setup player
    player_pos := vec2{
        f32(game.width) / 2 - PLAYER_SIZE.x / 2,
        f32(game.height) - PLAYER_SIZE.y
    }
    player = create_gameobject(player_pos, PLAYER_SIZE, rm_get_texture2d("paddle"))

    // setup ball
    ball_pos := player_pos + vec2{
        PLAYER_SIZE.x / 2 - BALL_RADIUS,
        -BALL_RADIUS * 2
    }
    ball = create_gameobject_ball(ball_pos, BALL_RADIUS, INITIAL_BALL_VELOCITY, rm_get_texture2d("face"))
}

update :: proc(game: ^Game, dt: f64)
{
    move_ball(&ball, dt, game.width)
    check_all_collisions(game)
}

input :: proc(game: ^Game, window: glfw.WindowHandle, dt: f64)
{
    if game.state == .Active
    {
        velocity := PLAYER_VELOCITY * f32(dt)

        if game.keys[glfw.KEY_A] || game.keys[glfw.KEY_LEFT]
        {
            if player.position.x >= 0
            {
                player.position.x -= velocity
                if ball.stuck do ball.position.x -= velocity
            }
        }
        if game.keys[glfw.KEY_D] || game.keys[glfw.KEY_RIGHT]
        {
            if player.position.x <= f32(game.width) - player.size.x
            {
                player.position.x += velocity
                if ball.stuck do ball.position.x += velocity
            }
        }
        if game.keys[glfw.KEY_SPACE]
        {
            ball.stuck = false
        }
    }
}

render :: proc(game: ^Game)
{
    if game.state == .Active
    {
        draw_sprite(rm_get_texture2d("background"), vec2{0,0}, vec2{f32(game.width), f32(game.height)}, 0)
        draw_level(&game.levels[game.level])
        draw_gameobject(player)
        draw_gameobject(ball)
    }
}

check_all_collisions :: proc(game: ^Game)
{
    if ball.stuck do return

    // ball brick collisions
    for &brick in game.levels[game.level].bricks
    {
        if !brick.destroyed
        {
            collision_detected, collision_direction, displacement := check_collision(ball, brick)
            if collision_detected
            {
                if !brick.solid
                {
                    brick.destroyed = true
                }
                
                if collision_direction == .Left || collision_direction == .Right
                {
                    ball.velocity.x = -ball.velocity.x

                    penetration := ball.radius - displacement.x
                    ball.position.x += collision_direction == .Left ? penetration : -penetration
                }
                else
                {
                    ball.velocity.y = -ball.velocity.y

                    penetration := ball.radius - displacement.y
                    ball.position.y += collision_direction == .Down ? penetration : -penetration
                }
            }
        }
    }

    // ball paddle collisions
    collision_detected, collision_direction, displacement := check_collision(ball, player)
    if collision_detected
    {
        center_paddle := player.position.x + player.size.x / 2
        distance := (ball.position.x + ball.radius) - center_paddle
        percentage := distance / (player.size.x / 2)

        strength := f32(2)
        prev_velocity := ball.velocity
        ball.velocity.x = INITIAL_BALL_VELOCITY.x * percentage * strength
        ball.velocity.y = -math.abs(ball.velocity.y)
        ball.velocity = linalg.normalize(ball.velocity) * linalg.length(prev_velocity)
    }

    // ball bottom edge collision
    if ball.position.y >= f32(game.height)
    {
        reset_level(game)
        reset_player(game)
    }
}

get_vector_direction :: proc(target: vec2) -> Direction
{
    compass := []vec2 {
        vec2{0, 1},
        vec2{1, 0},
        vec2{0, -1},
        vec2{-1, 0},
    }

    max: f32
    best_match := -1

    for i in 0..<4
    {
        dot_product := linalg.dot(linalg.normalize(target), compass[i])
        if dot_product > max
        {
            max = dot_product
            best_match = i
        }
    }

    return Direction(best_match)
}

reset_level :: proc(game: ^Game)
{
    switch game.level
    {
        case 0:
            load_level(&game.levels[0], "assets/levels/one.lvl", game.width, game.height / 2)
        case 1:
            load_level(&game.levels[1], "assets/levels/two.lvl", game.width, game.height / 2)
        case 2:
            load_level(&game.levels[2], "assets/levels/three.lvl", game.width, game.height / 2)
        case 3:
            load_level(&game.levels[3], "assets/levels/fout.lvl", game.width, game.height / 2)
    }
}

reset_player :: proc(game: ^Game)
{
    player.size = PLAYER_SIZE
    player.position = vec2 {
        f32(game.width) / 2 - PLAYER_SIZE.x / 2,
        f32(game.height) - PLAYER_SIZE.y
    }
    reset_ball(&ball,
        player.position + vec2{
            PLAYER_SIZE.x / 2 - BALL_RADIUS,
            -BALL_RADIUS * 2
        },
        INITIAL_BALL_VELOCITY,
    )
}