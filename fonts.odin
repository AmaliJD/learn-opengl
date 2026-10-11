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

Character :: struct
{
    texture: u32,
    size: [2]i32,
    bearing: [2]i32,
    advance: f32,
}

characters := [128]Character{} // used for text rendering scene

// ------------------------------------------------------------------ breakout - tet renderer
Text_Renderer :: struct
{
    characters: map[rune]Character,
    shader: Shader,

    VAO: u32,
    VBO: u32,
}

tr: Text_Renderer

create_text_renderer :: proc(width, height: u32) -> Text_Renderer
{
    text_render: Text_Renderer

    // shader
    rm_create_shader("assets/shaders/text.vert", "assets/shaders/text.frag", "text")
    text_render.shader = rm_get_shader("text")

    use_shader(text_render.shader)
    projection: mat4 = linalg.matrix_ortho3d(0, f32(width), f32(height), 0, -1, 1)
    shader_set_mat4(text_render.shader, "projection", projection)
    shader_set_int(text_render.shader, "text", 0)

    gl.GenVertexArrays(1, &text_render.VAO)
    gl.GenBuffers(1, &text_render.VBO)
    gl.BindVertexArray(text_render.VAO)
    gl.BindBuffer(gl.ARRAY_BUFFER, text_render.VBO)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * 6 * 4, nil, gl.DYNAMIC_DRAW)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    return text_render
}

tr_load_font :: proc(path: string, size: f32)
{
    clear(&tr.characters)

    font_data, err := os.read_entire_file(path, context.temp_allocator)
    if err != nil
    {
        fmt.printf("tr_load_font(): Error Reading TTF File: %s", err)
    }

    font_info: tt.fontinfo
    ok := tt.InitFont(
        &font_info,
        raw_data(font_data),
        tt.GetFontOffsetForIndex(raw_data(font_data), 0)
    )
    if !ok
    {
        fmt.printf("tr_load_font(): Error Initializing Font")
    }

    scale := tt.ScaleForPixelHeight(&font_info, size)
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
            tr.characters[codepoint] = Character {
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

        tr.characters[codepoint] = Character {
            texture = texture,
            size = { width, height },
            bearing = { xoff, -yoff },
            advance = f32(advance_width) * scale
        }

        tt.FreeBitmap(bitmap, nil)
    }

    gl.BindTexture(gl.TEXTURE_2D, 0)
}

tr_render_text :: proc(text: string, x, y, scale: f32, color := vec3{1,1,1})
{
    use_shader(tr.shader)
    shader_set_vec3(tr.shader, "textColor", color)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindVertexArray(tr.VAO)

    _x := x

    for r in text
    {
        ch := tr.characters[r]

        xpos := _x + f32(ch.bearing.x) * scale
        //ypos := y + f32(ch.size.y - ch.bearing.y) * scale
        ypos := y + f32(tr.characters['H'].bearing.y - ch.bearing.y) * scale

        w := f32(ch.size.x) * scale
        h := f32(ch.size.y) * scale

        if ch.size.x > 0 && ch.size.y > 0
        {
            vertices := [6][4]f32 {
                {xpos,     ypos + h, 0, 1},
                {xpos + w, ypos,     1, 0},
                {xpos,     ypos,     0, 0},

                {xpos,     ypos + h, 0, 1},
                {xpos + w, ypos + h, 1, 1},
                {xpos + w, ypos,     1, 0},
            }

            gl.BindTexture(gl.TEXTURE_2D, ch.texture)
            gl.BindBuffer(gl.ARRAY_BUFFER, tr.VBO)
            gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(vertices) * len(vertices[0]) * size_of(f32), &vertices[0])

            gl.BindBuffer(gl.ARRAY_BUFFER, 0)

            gl.DrawArrays(gl.TRIANGLES, 0, 6)
        }

        _x += ch.advance * scale
    }

    gl.BindVertexArray(0)
    gl.BindTexture(gl.TEXTURE_2D, 0)
}