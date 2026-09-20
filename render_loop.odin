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

cam: Camera

prev_mouse_x: f32 = SCREEN_WIDTH * .5
prev_mouse_y: f32 = SCREEN_HEIGHT * .5
mouse_init: bool

delta_time: f64
prev_frame_time: f64

light_source_pos := vec3 { 1.2, 1.0, 2.0 }
MAT4_IDENTITY : mat4 : 1

render_loop :: proc(window: glfw.WindowHandle)
{
    cam = create_camera(vec3{0, 0, 3})

    //basics_scene(window)
    //lighting_scene(window)
    //model_scene(window)
    text_rendering_scene(window)
}

process_input :: proc(window: glfw.WindowHandle)
{
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS
    {
        glfw.SetWindowShouldClose(window, true)
    }

    if glfw.GetKey(window, glfw.KEY_TAB) == glfw.PRESS
    {
        cam.movement.local_move_mode = !cam.movement.local_move_mode
    }

    if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS
    {
        camera_keyboard_move(&cam, .Forward, delta_time)
    }
    if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS
    {
        camera_keyboard_move(&cam, .Backward, delta_time)
    }
    if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS
    {
        camera_keyboard_move(&cam, .Left, delta_time)
    }
    if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS
    {
        camera_keyboard_move(&cam, .Right, delta_time)
    }
    if glfw.GetKey(window, glfw.KEY_SPACE) == glfw.PRESS
    {
        camera_keyboard_move(&cam, .Up, delta_time)
    }
    if glfw.GetKey(window, glfw.KEY_LEFT_SHIFT) == glfw.PRESS
    {
        camera_keyboard_move(&cam, .Down, delta_time)
    }
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32)
{
    gl.Viewport(0, 0, width, height)
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32)
{
    context = runtime.default_context()
}

mouse_callback :: proc "c" (window: glfw.WindowHandle, x_pos_64, y_pos_64: f64)
{
    context = runtime.default_context()

    x_pos := f32(x_pos_64)
    y_pos := f32(y_pos_64)

    if !mouse_init
    {
        prev_mouse_x = x_pos 
        prev_mouse_y = y_pos
        mouse_init = true
    }

    x_offset := x_pos - prev_mouse_x
    y_offset := y_pos - prev_mouse_y
    prev_mouse_x = x_pos
    prev_mouse_y = y_pos

    camera_cursor_look(&cam, x_offset, y_offset)
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64)
{
    context = runtime.default_context()

    camera_scroll_zoom(&cam, f32(y_offset))
}

load_texture :: proc(path: cstring) -> u32
{
    texture: u32
    gl.GenTextures(1, &texture)

    width, height, nr_components: i32
    data := stbi.load(path, &width, &height, &nr_components, 0)
    if data != nil
    {
        format: gl.GL_Enum
        if nr_components == 1 {
            format = gl.GL_Enum(gl.RED)
        }
        else if nr_components == 3 {
            format = gl.GL_Enum(gl.RGB)
        }
        else if nr_components == 4 {
            format = gl.GL_Enum(gl.RGBA)
        }

        gl.BindTexture(gl.TEXTURE_2D, texture)
        gl.TexImage2D(gl.TEXTURE_2D, 0, i32(format), width, height, 0, u32(format), gl.UNSIGNED_BYTE, data)
        gl.GenerateMipmap(gl.TEXTURE_2D)

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    }
    else
    {
        fmt.printf("Failed to load data from path: %s\n", path)
    }

    stbi.image_free(data)
    
    return texture
}