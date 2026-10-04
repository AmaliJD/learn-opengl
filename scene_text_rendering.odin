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

/*
    FOR MORE EFFICIENT IMPLEMENTATION:
    Use a dynamic atlas
*/

text_rendering_scene :: proc(window: glfw.WindowHandle)
{
    piazzolla := "assets/fonts/Piazzolla-Regular.otf"
    betania := "assets/fonts/BetaniaPatmos-Regular.otf"
    telex := "assets/fonts/Telex-Regular.ttf"

    font_data, err := os.read_entire_file(piazzolla, context.temp_allocator)
    if err != nil
    {
        fmt.printf("Error Reading TTF File: %s", err)
    }

    font_info: tt.fontinfo
    ok := tt.InitFont(
        &font_info,
        raw_data(font_data),
        tt.GetFontOffsetForIndex(raw_data(font_data), 0)
    )
    if !ok
    {
        fmt.printf("Error Initializing Font")
    }

    font_height: f32 = 48 * 4//48
    scale := tt.ScaleForPixelHeight(&font_info, font_height)
    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1) // each glyph has 1 byte per pixel

    for i in 0..<128
    {
        codepoint := rune(i)

        width, height: i32
        xoff, yoff: i32

        bitmap := tt.GetCodepointBitmap(
            &font_info,
            scale, scale,
            codepoint,
            &width, &height,
            &xoff, &yoff,
        )

        advance_width: i32
        left_side_bearing: i32
        tt.GetCodepointHMetrics(
            &font_info,
            codepoint,
            &advance_width,
            &left_side_bearing,
        )

        if width <= 0 || height <= 0
        {
            characters[i] = Character {
                size = { 0, 0 },
                bearing = { xoff, -yoff },
                advance = f32(advance_width) * scale
            }

            tt.FreeBitmap(bitmap, nil)
            continue
        }

        texture: u32
        gl.GenTextures(1, &texture)
        gl.BindTexture(gl.TEXTURE_2D, texture)
        gl.TexImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RED,
            width, height,
            0,
            gl.RED,
            gl.UNSIGNED_BYTE,
            bitmap,
        )

        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

        characters[i] = Character {
                texture = texture,
                size = { width, height },
                bearing = { xoff, -yoff },
                advance = f32(advance_width) * scale
            }

        tt.FreeBitmap(bitmap, nil)
    }

    gl.BindTexture(gl.TEXTURE_2D, 0)

    gl.Enable(gl.CULL_FACE)
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    // VBO and VAO for texture quads
    VAO, VBO: u32
    gl.GenVertexArrays(1, &VAO)
    gl.GenBuffers(1, &VBO)
    gl.BindVertexArray(VAO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * 6 * 4, nil, gl.DYNAMIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    // shader
    shader := create_shader("assets/shaders/text.vert", "assets/shaders/text.frag")
    use_shader(shader)
    projection: mat4 = linalg.matrix_ortho3d(0, SCREEN_WIDTH, 0, SCREEN_HEIGHT, -1, 1)
    shader_set_mat4(shader, "projection", projection)

    defer
    {
        gl.DeleteVertexArrays(1, &VAO)
        gl.DeleteBuffers(1, &VBO)
    }

    for !glfw.WindowShouldClose(window)
    {
        curr_frame_time := glfw.GetTime()
        delta_time = curr_frame_time - prev_frame_time
        prev_frame_time = curr_frame_time

        // input
        process_input(window)

        // render
        gl.ClearColor(rgba(BG))
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        render_text(shader, "Amali Delauney", 25, 25, 2 * .25, vec3{.5, .8, .2}, VAO, VBO)
        render_text(shader, "(C) LearnOpenGL.com", 620, 570, .5 * .25, vec3{.3, .7, .9}, VAO, VBO)

        // end
        glfw.PollEvents()
        glfw.SwapBuffers(window)
    }
}

render_text :: proc(shader: Shader, text: string, x, y, scale: f32, color: vec3, VAO, VBO: u32)
{
    use_shader(shader)
    shader_set_vec3(shader, "textColor", color)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindVertexArray(VAO)

    _x := x

    for r in text
    {
        ch := characters[i32(r)]

        xpos := _x + f32(ch.bearing.x) * scale
        ypos := y - f32(ch.size.y - ch.bearing.y) * scale

        w := f32(ch.size.x) * scale
        h := f32(ch.size.y) * scale

        if ch.size.x > 0 && ch.size.y > 0
        {
            vertices := [6][4]f32 {
                {xpos,     ypos + h, 0, 0},
                {xpos,     ypos,     0, 1},
                {xpos + w, ypos,     1, 1},

                {xpos,     ypos + h, 0, 0},
                {xpos + w, ypos,     1, 1},
                {xpos + w, ypos + h, 1, 0},
            }

            gl.BindTexture(gl.TEXTURE_2D, ch.texture)
            gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
            gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * len(vertices[0]) * size_of(f32), &vertices[0])

            gl.BindBuffer(gl.ARRAY_BUFFER, 0)

            gl.DrawArrays(gl.TRIANGLES, 0, 6)
        }

        _x += ch.advance * scale
    }

    gl.BindVertexArray(0)
    gl.BindTexture(gl.TEXTURE_2D, 0)
}