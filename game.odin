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

Game :: struct
{
    state: Game_State,
    keys: [1024]bool,
    width, height: u32,
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

update :: proc(game: ^Game, dt: f64)
{

}

input :: proc(game: ^Game, window: glfw.WindowHandle, dt: f64)
{
    
}

render :: proc(game: ^Game)
{

}