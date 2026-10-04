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

Post_Processor :: struct
{
    shader: Shader,
    texture: Texture2D,
    width, height: i32,
    
    confuse: bool,
    chaos: bool,
    shake: bool,

    MSFBO: u32,
    FBO: u32,
    RBO: u32,
    VAO: u32
}

pp: Post_Processor

create_post_processor :: proc(shader: Shader, width, height: i32) -> Post_Processor
{
    _pp: Post_Processor

    _pp.shader = shader
    _pp.width = width
    _pp.height = height

    // initialize renderbuffer/framebuffer object
    gl.GenFramebuffers(1, &_pp.MSFBO)
    gl.GenFramebuffers(1, &_pp.FBO)
    gl.GenRenderbuffers(1, &_pp.RBO)

    // initialize renderbuffer storage with a multisampled color buffer (don't need a depth/stencil buffer)
    gl.BindFramebuffer(gl.FRAMEBUFFER, pp.MSFBO)
    gl.BindRenderbuffer(gl.RENDERBUFFER, pp.RBO)
    gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, 4, gl.RGB, width, height)
    gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, _pp.RBO)
    if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE
    {
        fmt.printfln("Error: create_post_processor() - Failed to initialize MSFBO")
    }

    // also initialize the FBO/texture to blit multisampled color-buffer to; used for shader operations (for postprocessing effects)
    gl.BindFramebuffer(gl.FRAMEBUFFER, _pp.FBO)
    _pp.texture = create_texture2d(width, height)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, _pp.texture.id, 0) // attach texture to framebuffer as its color attachment
    if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE
    {
        fmt.printfln("Error: create_post_processor() - Failed to initialize FBO")
    }

    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

    // --------------------------- configure quad VAO/VBO
    VBO: u32
    vertices := []f32 {
        // pos      // tex
        -1.0, -1.0, 0.0, 0.0,
         1.0,  1.0, 1.0, 1.0,
        -1.0,  1.0, 0.0, 1.0,

        -1.0, -1.0, 0.0, 0.0,
         1.0, -1.0, 1.0, 0.0,
         1.0,  1.0, 1.0, 1.0,
    }

    gl.GenVertexArrays(1, &_pp.VAO)
    gl.GenBuffers(1, &VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)
    gl.BindVertexArray(_pp.VAO)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    // --------------------------- set uniforms
    use_shader(shader)
    shader_set_int(shader, "scene", 0)
    offset: f32 = 1 / 300
    offsets: [9][2]f32 = {
        { -offset,   offset  },  // top-left
        {  0,        offset  },  // top-center
        {  offset,   offset  },  // top-right
        { -offset,   0       },  // center-left
        {  0,        0       },  // center-center
        {  offset,   0       },  // center-right
        { -offset, -offset   },  // bottom-left
        {  0,       -offset  },  // bottom-center
        {  offset,  -offset  },  // bottom-right
    }
    shader_set_vec2_array(shader, "offsets", offsets[:])

    edge_kernel: [9]i32 = {
        -1, -1, -1,
        -1,  8, -1,
        -1, -1, -1
    }
    shader_set_int_array(shader, "edge_kernel", edge_kernel[:])

    blur_kernel := [9]f32{
        1/16, 2/16, 1/16,
        2/16, 4/16, 2/16,
        1/16, 2/16, 1/16,
    }
    shader_set_float_array(shader, "blur_kernel", blur_kernel[:])

    return _pp
}

pp_begin_render :: proc()
{
    gl.BindFramebuffer(gl.FRAMEBUFFER, pp.MSFBO)
    gl.ClearColor(0, 0, 0, 1)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}

pp_end_render :: proc()
{
    gl.BindFramebuffer(gl.READ_FRAMEBUFFER, pp.MSFBO)
    gl.BindFramebuffer(gl.DRAW_FRAMEBUFFER, pp.FBO)
    gl.BlitFramebuffer(0, 0, pp.width, pp.height, 0, 0, pp.width, pp.height, gl.COLOR_BUFFER_BIT, gl.NEAREST)
    gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

pp_render :: proc(dt: f64)
{
    use_shader(pp.shader)
    shader_set_float(pp.shader, "time", f32(dt))
    shader_set_bool(pp.shader, "confuse", pp.confuse)
    shader_set_bool(pp.shader, "chaos", pp.chaos)
    shader_set_bool(pp.shader, "shake", pp.shake)

    gl.ActiveTexture(gl.TEXTURE0)
    bind_texture(pp.texture)
    gl.BindVertexArray(pp.VAO)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    gl.BindVertexArray(0)
}