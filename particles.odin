package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"
import "core:math/linalg"
import "core:math/rand"

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

    last_used_particle: u32,
    delay: f32,

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

update_particles :: proc(dt: f64, obj: ^GameObject, spawn_count: u32, offset := vec2{0,0})
{
    dt32 := f32(dt)

    // spawn new particles
    pg.delay -= dt32
    if pg.delay <= 0
    {
        for i in 0..<spawn_count
        {
            next_particle := next_free_particle()
            respawn_particle(&pg.particles[next_particle], obj, offset)
        }

        pg.delay = .005
    }
    
    // update all particles
    for &p in pg.particles
    {
        p.life -= dt32
        if p.life > 0
        {
            p.position -= p.velocity * dt32
            p.color.a -= dt32 * 2.5
        }
    }
}

draw_particles :: proc()
{
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE) // additive blending

    use_shader(pg.shader)
    for &p in pg.particles
    {
        if p.life > 0
        {
            shader_set_vec2(pg.shader, "offset", p.position)
            shader_set_vec4(pg.shader, "color", p.color)
            bind_texture(pg.texture)
            gl.BindVertexArray(pg.VAO)
            gl.DrawArrays(gl.TRIANGLES, 0, 6)
            gl.BindVertexArray(0)
        }
    }

    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA) // default blending
}

next_free_particle :: proc() -> u32
{
    // search from last used particle (usually results in next free found)
    for i in pg.last_used_particle..<pg.count
    {
        if pg.particles[i].life <= 0
        {
            pg.last_used_particle = i
            return i
        }
    }

    // if not found, search from 0
    for i in 0..<pg.last_used_particle
    {
        if pg.particles[i].life <= 0
        {
            pg.last_used_particle = i
            return i
        }
    }

    // if not found, override particle 0

    pg.last_used_particle = 0
    return 0
}

respawn_particle :: proc(particle: ^Particle, obj: ^GameObject, offset := vec2{0,0})
{
    random := vec2{f32(rand.int32_range(-70, 71)) / 10, f32(rand.int32_range(-70, 71)) / 10}
    r_color := f32(rand.int32_range(0, 101)) / 100 + .5
    particle.position = obj.position + offset + random
    particle.color = vec4{r_color, r_color, r_color, 1}
    particle.life = .5
    particle.velocity = obj.velocity * .1
}