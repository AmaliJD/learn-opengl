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
import tt "vendor:stb/truetype"

Breakout: Game
Renderer: Sprite_Renderer

breakout_scene :: proc(window: glfw.WindowHandle)
{
    glfw.SetKeyCallback(window, key_callback_breakout)
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    Breakout = create_game(u32(SCREEN_WIDTH), u32(SCREEN_HEIGHT))

    init()

    for !glfw.WindowShouldClose(window)
    {
        curr_frame_time := glfw.GetTime()
        delta_time = curr_frame_time - prev_frame_time
        prev_frame_time = curr_frame_time
        glfw.PollEvents()

        // input
        input(&Breakout, window, delta_time)

        // update
        update(&Breakout, delta_time)

        // render
        gl.ClearColor(rgba(BG))
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
        render(&Breakout)

        // end
        glfw.SwapBuffers(window)
    }
}

key_callback_breakout :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32)
{
    context = runtime.default_context()

    if key == glfw.KEY_ESCAPE && action == glfw.PRESS
    {
        glfw.SetWindowShouldClose(window, true)
    }

    if key >= 0 && key < 1024
    {
        if action == glfw.PRESS do Breakout.keys[key] = true
        else if action == glfw.RELEASE do Breakout.keys[key] = false
    }
}

init :: proc()
{
    projection := linalg.matrix_ortho3d(0, SCREEN_WIDTH, SCREEN_HEIGHT, 0, -1, 1)

    rm_create_shader("assets/shaders/sprite.vert", "assets/shaders/sprite.frag", "sprite")
    sprite_shader := rm_get_shader("sprite")
    use_shader(sprite_shader)

    shader_set_int(sprite_shader, "image", 0)
    shader_set_mat4(sprite_shader, "projection", projection)

    Renderer = create_sprite_renderer(sprite_shader)
    rm_create_texture2d("assets/images/awesomeface.png", true, "face")
}