package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

import "vendor:glfw"
import gl "vendor:OpenGL"
import "glx"
import stbi "vendor:stb/image"

POWERUP_SIZE :: vec2{60, 20}
POWERUP_VELOCITY :: vec2{0, 150}

Powerup_Type :: enum
{
    Speed,
    Sticky,
    Pass_Through,
    Size_Up,
    Confuse,
    Chaos
}

Powerup :: struct
{
    using gameobject: GameObject,
    type: Powerup_Type,
    duration: f64,
    activated: bool,
}

create_powerup :: proc(type: Powerup_Type, color: vec3, duration: f64, position: vec2, texture: Texture2D) -> Powerup
{
    powerup: Powerup

    powerup.gameobject = create_gameobject(position, POWERUP_SIZE, texture, color, POWERUP_VELOCITY)
    powerup.type = type
    powerup.duration = duration

    return powerup
}

spawn_powerups :: proc(powerups: ^[dynamic]Powerup, block: GameObject)
{
    if powerup_spawn_true(25)
    {
        append(powerups, create_powerup(.Speed, vec3{.5,.5,1}, 0, block.position, rm_get_texture2d("powerup_speed")))
    }

    if powerup_spawn_true(40)
    {
        append(powerups, create_powerup(.Sticky, vec3{1,.5,1}, 8, block.position, rm_get_texture2d("powerup_sticky")))
    }

    if powerup_spawn_true(50)
    {
        append(powerups, create_powerup(.Pass_Through, vec3{.5,1,.5}, 5, block.position, rm_get_texture2d("powerup_pass")))
    }

    if powerup_spawn_true(60)
    {
        append(powerups, create_powerup(.Size_Up, vec3{1,.6,.4}, 0, block.position, rm_get_texture2d("powerup_size")))
    }

    if powerup_spawn_true(50)
    {
        append(powerups, create_powerup(.Confuse, vec3{1,.3,.3}, 8, block.position, rm_get_texture2d("powerup_confuse")))
    }

    if powerup_spawn_true(30)
    {
        append(powerups, create_powerup(.Chaos, vec3{.9,.25,.25}, 8, block.position, rm_get_texture2d("powerup_chaos")))
    }
}

update_powerups :: proc(powerups: ^[dynamic]Powerup, dt: f64)
{
    delete_count: i32

    for &powerup, i in powerups
    {
        powerup.position += powerup.velocity * f32(dt)

        if powerup.activated
        {
            powerup.duration -= dt

            if powerup.duration <= 0
            {
                powerup.activated = false

                #partial switch powerup.type
                {
                    case .Sticky:
                        if !powerups_contains_activated_of_type(powerups[:], .Sticky)
                        {
                            ball.sticky = false
                            player.color = create_vec3(1)
                        }

                    case .Pass_Through:
                        if !powerups_contains_activated_of_type(powerups[:], .Pass_Through)
                        {
                            ball.pass_through = false
                            ball.color = create_vec3(1)
                        }

                    case .Confuse:
                        if !powerups_contains_activated_of_type(powerups[:], .Confuse)
                        {
                            pp.confuse = false
                        }

                    case .Chaos:
                        if !powerups_contains_activated_of_type(powerups[:], .Chaos)
                        {
                            pp.chaos = false
                        }
                }
            }
        }
    }

    for i := len(powerups) - 1; i >= 0; i -= 1
    {
        if powerups[i].destroyed && !powerups[i].activated
        {
            unordered_remove(powerups, i)
        }
    }
}

powerups_contains_activated_of_type :: proc(powerups: []Powerup, type: Powerup_Type) -> bool
{
    for powerup in powerups
    {
        if powerup.type == type && powerup.activated
        {
            return true
        }
    }

    return false
}

powerup_spawn_true :: proc(odds: u32) -> bool
{
    return rand.uint32_range(0, odds) == 0
}

activate_powerup :: proc(powerup: ^Powerup)
{
    switch powerup.type
    {
        case .Speed:
            ball.velocity *= 1.2

        case .Sticky:
            ball.sticky = true
            player.color = vec3{1, .5, 1}

        case .Pass_Through:
            ball.pass_through = true
            ball.color = vec3{1, .5, .5}

        case .Size_Up:
            player.size.x += 50

        case .Confuse:
            if !pp.chaos
            {
                pp.confuse = true
            }

        case .Chaos:
            if !pp.confuse
            {
                pp.chaos = true
            }
    }
}

draw_powerups :: proc(powerups: []Powerup)
{
    for &powerup in powerups
    {
        if !powerup.destroyed
        {
            draw_gameobject(powerup)
        }
    }
}