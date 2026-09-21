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

Sprite_Renderer :: struct
{
    shader: Shader,
    quad_VAO: u32,
}

create_sprite_renderer :: proc(shader: Shader) -> Sprite_Renderer
{
    sp: Sprite_Renderer
    sp.shader = shader

    // init
    VBO: u32
    vertices := []f32{
        // position   // texture coordinates
        0.0, 1.0,     0.0, 1.0,
        1.0, 0.0,     1.0, 0.0,
        0.0, 0.0,     0.0, 0.0,

        0.0, 1.0,     0.0, 1.0,
        1.0, 1.0,     1.0, 1.0,
        1.0, 0.0,     1.0, 0.0,
    }

    gl.GenVertexArrays(1, &sp.quad_VAO)
    gl.GenBuffers(1, &VBO)

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)

    gl.BindVertexArray(sp.quad_VAO)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    return sp
}

destroy_sprite_renderer :: proc(sp: ^Sprite_Renderer)
{
    gl.DeleteVertexArrays(1, &sp.quad_VAO)
}

draw_sprite :: proc(sp: Sprite_Renderer, texture: Texture2D, position: vec2, size := vec2{10, 10}, rotate :f32= 0, color := vec3{1,1,1})
{
    use_shader(sp.shader)

    trans := linalg.matrix4_translate(create_vec3(position, 0))

    trans_tl := linalg.matrix4_translate(vec3{.5 * size.x, .5 * size.y, 0})
    rot := linalg.matrix4_rotate(linalg.to_radians(rotate), vec3{0,0,1})
    trans_center := linalg.matrix4_translate(vec3{-.5 * size.x, -.5 * size.y, 0})

    scl := linalg.matrix4_scale(create_vec3(size, 1))

    model := MAT4_IDENTITY * trans * trans_tl * rot * trans_center * scl

    shader_set_mat4(sp.shader, "model", model)
    shader_set_vec3(sp.shader, "spriteColor", color)

    gl.ActiveTexture(gl.TEXTURE0)
    bind_texture(texture)

    gl.BindVertexArray(sp.quad_VAO)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    gl.BindVertexArray(0)
}