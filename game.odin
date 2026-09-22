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

    _sp = create_sprite_renderer(sprite_shader)

    // load textures
    rm_create_texture2d("assets/images/awesomeface.png", true, "face")
    rm_create_texture2d("assets/images/background.jpg", false, "background")
    rm_create_texture2d("assets/images/block.png", false, "block")
    rm_create_texture2d("assets/images/block_solid.png", false, "block_solid")

    // load levels
    one := create_and_load_level("assets/levels/one.lvl", game.width, game.height / 2)
    two := create_and_load_level("assets/levels/two.lvl", game.width, game.height / 2)
    three := create_and_load_level("assets/levels/three.lvl", game.width, game.height / 2)
    four := create_and_load_level("assets/levels/four.lvl", game.width, game.height / 2)

    append(&game.levels, one)
    append(&game.levels, two)
    append(&game.levels, three)
    append(&game.levels, four)
}

update :: proc(game: ^Game, dt: f64)
{

}

input :: proc(game: ^Game, window: glfw.WindowHandle, dt: f64)
{
    
}

render :: proc(game: ^Game)
{
    if game.state == .Active
    {
        draw_sprite(_sp, rm_get_texture2d("background"), vec2{0,0}, vec2{f32(game.width), f32(game.height)}, 0)
    }

    draw_level(&game.levels[game.level], _sp)
}