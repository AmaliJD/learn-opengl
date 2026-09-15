package main

import "core:fmt"
import "base:runtime"
import "core:math"

import "vendor:glfw"
import gl "vendor:OpenGL"
import ma "vendor:miniaudio"

SCREEN_WIDTH :: f32(800)
SCREEN_HEIGHT :: f32(600)

main :: proc()
{
    // glfw
    if !glfw.Init() {
        return
    } defer glfw.Terminate()

    // window
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window := glfw.CreateWindow(i32(SCREEN_WIDTH), i32(SCREEN_HEIGHT), "Dungeon Slime", nil, nil)
    if window == nil {
        return
    }
    glfw.SetWindowSizeLimits(window, 320, 180, glfw.DONT_CARE, glfw.DONT_CARE)
    glfw.MakeContextCurrent(window)

    glfw.SetKeyCallback(window, key_callback)
    glfw.SetCursorPosCallback(window, mouse_callback)
    glfw.SetScrollCallback(window, scroll_callback)
    glfw.SetInputMode(window, glfw.CURSOR, glfw.CURSOR_DISABLED)

    // opengl
    gl.load_up_to(3, 3, glfw.gl_set_proc_address)
    glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
    
    // render loop
    render_loop(window)
}