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

breakout_scene :: proc(window: glfw.WindowHandle)
{
    glfw.SetKeyCallback(window, key_callback_breakout)
    gl.Enable(gl.BLEND);
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

    Breakout = create_game(u32(SCREEN_WIDTH), u32(SCREEN_HEIGHT))

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