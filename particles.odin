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

Particle :: struct
{
    position: vec2,
    velocity: vec2,
    color: vec4,

    life: f32,
}

create_particle :: proc() -> Particle
{
    return Particle {
        position = vec2{0,0},
        velocity = vec2{0,0},
        color = create_vec4(1),
        life = 0,
    }
}

Particle_Generator :: struct
{
    particles: [dynamic]Particle,
    count: u32,

    last_used_particle: u32

    shader: Shader,
    texture: Texture2D,
    VAO: u32
}

create_particle_generator :: proc(shader: Shader, texture: Texture2D, count: u32) -> Particle_Generator
{
    particle_generator: Particle_Generator

    particle_generator.shader = shader
    particle_generator.texture = texture
    particle_generator.count = count

    // init
    VBO: u32

    quad := []f32{
        0.0, 1.0, 0.0, 1.0,
        1.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 0.0,

        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 1.0, 1.0,
        1.0, 0.0, 1.0, 0.0,
    }

    gl.GenVertexArrays(1, &particle_generator.VAO)
    gl.GenBuffers(1, &VBO)
    gl.BindVertexArray(particle_generator.VAO)

    // fill buffer
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(quad) * size_of(f32), &quad[0], gl.STATIC_DRAW)
    //set attributes
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), uintptr(0))
    gl.BindVertexArray(0)

    for i in 0..<particle_generator.count
    {
        append(&particle_generator.particles, create_particle())
    }

    return particle_generator
}

update_particles :: proc(dt: f64, obj: ^GameObject, new_particles: u32, offset := vec2{0,0})
{

}

draw_particles :: proc()
{

}

next_free_particle :: proc() -> u32
{

    
    return 0
}

respawn_particle :: proc(particle: ^Particle, obj: ^GameObject, offset := vec2{0,0})
{

}