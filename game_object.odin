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

Game_Object :: struct
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
create_gameobject_default :: proc() -> Game_Object
{
    return create_gameobject_params(vec2{0,0}, vec2{1,1}, Texture2D{})
}

@(private="file")
create_gameobject_params :: proc(pos, size: vec2, sprite: Texture2D, color := vec3{1,1,1}, velocity := vec2{0,0}) -> Game_Object
{
    go: Game_Object

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

draw_gameobject :: proc(go: Game_Object)
{
    draw_sprite(go.sprite, go.position, go.size, go.rotation, go.color)
}