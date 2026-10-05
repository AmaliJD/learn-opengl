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
    post_processor: Post_Processor

    post_processor.shader = shader
    post_processor.width = width
    post_processor.height = height

    // initialize renderbuffer/framebuffer object
    gl.GenFramebuffers(1, &post_processor.MSFBO)
    gl.GenFramebuffers(1, &post_processor.FBO)
    gl.GenRenderbuffers(1, &post_processor.RBO)

    // initialize renderbuffer storage with a multisampled color buffer (don't need a depth/stencil buffer)
    gl.BindFramebuffer(gl.FRAMEBUFFER, post_processor.MSFBO)
    gl.BindRenderbuffer(gl.RENDERBUFFER, post_processor.RBO)
    gl.RenderbufferStorageMultisample(gl.RENDERBUFFER, 4, gl.RGB, width, height)
    gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.RENDERBUFFER, post_processor.RBO)
    if gl.CheckFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE
    {
        fmt.printfln("Error: create_post_processor() - Failed to initialize MSFBO")
    }

    // also initialize the FBO/texture to blit multisampled color-buffer to; used for shader operations (for postprocessing effects)
    gl.BindFramebuffer(gl.FRAMEBUFFER, post_processor.FBO)
    post_processor.texture = create_texture2d(width, height)
    gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, post_processor.texture.id, 0) // attach texture to framebuffer as its color attachment
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

    gl.GenVertexArrays(1, &post_processor.VAO)
    gl.GenBuffers(1, &VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)
    gl.BindVertexArray(post_processor.VAO)
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindVertexArray(0)

    // --------------------------- set uniforms
    use_shader(shader)
    shader_set_int(shader, "scene", 0)
    offset: f32 = 1.0 / 300.0
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
        1.0/16.0, 2.0/16.0, 1/16.0,
        2.0/16.0, 4.0/16.0, 2/16.0,
        1.0/16.0, 2.0/16.0, 1/16.0,
    }
    shader_set_float_array(shader, "blur_kernel", blur_kernel[:])

    return post_processor
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

pp_render :: proc(time: f64)
{
    use_shader(pp.shader)
    shader_set_float(pp.shader, "time", f32(time))
    shader_set_bool(pp.shader, "confuse", pp.confuse)
    shader_set_bool(pp.shader, "chaos", pp.chaos)
    shader_set_bool(pp.shader, "shake", pp.shake)

    gl.ActiveTexture(gl.TEXTURE0)
    bind_texture(pp.texture)
    gl.BindVertexArray(pp.VAO)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    gl.BindVertexArray(0)
}