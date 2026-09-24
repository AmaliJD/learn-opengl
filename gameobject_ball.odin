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

Ball_GameObject :: struct
{
    using gameobject: GameObject,
    radius: f32,
    stuck: bool,
}

create_gameobject_ball :: proc
{
    create_gameobject_ball_default,
    create_gameobject_ball_params,
}

@(private="file")
create_gameobject_ball_default :: proc() -> Ball_GameObject
{
    go := create_gameobject()
    return create_gameobject_ball_params(go.position, 12.5, go.velocity, go.sprite)
}

@(private="file")
create_gameobject_ball_params :: proc(pos: vec2, radius: f32, velocity: vec2, sprite: Texture2D) -> Ball_GameObject
{
    ball: Ball_GameObject

    ball.gameobject = create_gameobject(pos, vec2{radius * 2, radius * 2}, sprite, vec3{1,1,1}, velocity)
    ball.radius = radius
    ball.stuck = true

    return ball
}

move_ball :: proc(ball: ^Ball_GameObject, dt: f64, window_width: u32) -> vec2
{
    if !ball.stuck
    {
        ball.position += ball.velocity * f32(dt)

        if ball.position.x <= 0
        {
            ball.velocity.x = -ball.velocity.x
            ball.position.x = 0
        }
        else if ball.position.x + ball.size.x >= f32(window_width)
        {
            ball.velocity.x = -ball.velocity.x
            ball.position.x = f32(window_width) - ball.size.x
        }

        if ball.position.y <= 0
        {
            ball.velocity.y = -ball.velocity.y
            ball.position.y = 0
        }
    }

    return ball.position
}

reset_ball :: proc(ball: ^Ball_GameObject, position, velocity: vec2)
{
    ball.position = position
    ball.velocity = velocity
    ball.stuck = true
}