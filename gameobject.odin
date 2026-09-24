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

GameObject :: struct
{
    position: vec2,
    size: vec2,
    velocity: vec2,

    color: vec3,
    rotation: f32,
    solid: bool,
    destroyed: bool,

    sprite: Texture2D,
}

create_gameobject :: proc
{
    create_gameobject_default,
    create_gameobject_params,
}

@(private="file")
create_gameobject_default :: proc() -> GameObject
{
    return create_gameobject_params(vec2{0,0}, vec2{1,1}, Texture2D{})
}

@(private="file")
create_gameobject_params :: proc(pos, size: vec2, sprite: Texture2D, color := vec3{1,1,1}, velocity := vec2{0,0}) -> GameObject
{
    go: GameObject

    go.position = pos
    go.size = size
    go.velocity = velocity
    go.color = color
    go.rotation = 0
    go.solid = false
    go.destroyed = false
    go.sprite = sprite

    return go
}

draw_gameobject :: proc(go: GameObject)
{
    draw_sprite(go.sprite, go.position, go.size, go.rotation, go.color)
}

check_collision :: proc
{
    check_collision_box_box,
    check_collision_circle_box,
}

@(private="file")
check_collision_box_box :: proc(go1, go2: GameObject) -> bool
{
    collision_x := go1.position.x + go1.size.x >= go2.position.x &&
                   go2.position.x + go2.size.x >= go1.position.x

    collision_y := go1.position.y + go1.size.y >= go2.position.y &&
                   go2.position.y + go2.size.y >= go1.position.y

    return collision_x && collision_y
}

@(private="file")
check_collision_circle_box :: proc(ball: Ball_GameObject, go: GameObject) -> (bool, Direction, vec2)
{
    center := ball.position + create_vec2(ball.radius)
    aabb_half_extents := go.size / 2
    aabb_center := go.position + aabb_half_extents

    displacement_centers := center - aabb_center
    clamped := vec2{
        math.clamp(displacement_centers.x, -aabb_half_extents.x, aabb_half_extents.x),
        math.clamp(displacement_centers.y, -aabb_half_extents.y, aabb_half_extents.y)
    }

    closest := aabb_center + clamped
    displacement_closest := closest - center

    collision_detected := linalg.length(displacement_closest) < ball.radius

    if collision_detected
    {
        collision_direction := get_vector_direction(displacement_closest)
        return collision_detected, collision_direction, displacement_closest
    }
    else
    {
        return false, .Up, create_vec2(0)
    }
}