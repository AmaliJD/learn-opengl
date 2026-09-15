package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"

import "vendor:glfw"
import gl "vendor:OpenGL"

MAX_BONE_INFLUENCE :: 4

Vertex :: struct
{
    position: vec3,
    normal: vec3,
    tex_coords: vec2,
    tangent: vec3,
    bit_tangent: vec3,

    bone_ids: [MAX_BONE_INFLUENCE]i32,
    weights: [MAX_BONE_INFLUENCE]f32,
}

Texture :: struct
{
    id: u32,
    path: string,
    type: Texture_Type,
}

Texture_Type :: enum
{
    Diffuse, Specular, Normal, Height
}

Mesh :: struct
{
    vertices: []Vertex,
    indices: []u32,
    textures: []Texture,

    VAO, VBO, EBO: u32,
}

create_mesh :: proc(vertices: []Vertex, indices: []u32, textures: []Texture) -> Mesh
{
    mesh: Mesh

    mesh.vertices = make([]Vertex, len(vertices))
    copy(mesh.vertices, vertices)

    mesh.indices = make([]u32, len(indices))
    copy(mesh.indices, indices)

    mesh.textures = make([]Texture, len(textures))
    copy(mesh.textures, textures)

    create_mesh_buffers(&mesh)

    return mesh
}

@(private="file")
create_mesh_buffers :: proc(mesh: ^Mesh)
{
    gl.GenVertexArrays(1, &mesh.VAO)
    gl.GenBuffers(1, &mesh.VBO)
    gl.GenBuffers(1, &mesh.EBO)

    gl.BindVertexArray(mesh.VAO)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(mesh.vertices) * size_of(Vertex), &mesh.vertices[0], gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.EBO)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(mesh.indices) * size_of(u32), &mesh.indices[0], gl.STATIC_DRAW)

    // position attribute
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), uintptr(0))

    // normal attribute
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, normal))

    // tex_coords attribute
    gl.EnableVertexAttribArray(2)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tex_coords))

    // tangent attribute
    gl.EnableVertexAttribArray(3)
    gl.VertexAttribPointer(3, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tangent))

    // bit_tangent attribute
    gl.EnableVertexAttribArray(4)
    gl.VertexAttribPointer(4, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, bit_tangent))

    // bone_ids attribute
    gl.EnableVertexAttribArray(5)
    gl.VertexAttribIPointer(5, MAX_BONE_INFLUENCE, gl.INT, size_of(Vertex), offset_of(Vertex, bone_ids))

    // weights attribute
    gl.EnableVertexAttribArray(6)
    gl.VertexAttribPointer(6, MAX_BONE_INFLUENCE, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, weights))

    gl.BindVertexArray(0)
}

draw_mesh :: proc(mesh: Mesh, shader: Shader)
{
    diffuse_tex_counter: u32 = 0
    specular_tex_counter: u32 = 0
    normal_tex_counter: u32 = 0
    height_tex_counter: u32 = 0

    // potentially can be pulled out and done once at shader creation?
    for i in i32(0)..<i32(len(mesh.textures))
    {
        gl.ActiveTexture(gl.TEXTURE0 + u32(i))

        num: u32
        switch mesh.textures[i].type
        {
            case .Diffuse:
                num = diffuse_tex_counter
                diffuse_tex_counter += 1
                shader_set_int(shader, strings.clone_to_cstring(fmt.tprintf("material.diffuse_tex_%d", num)), i)
                
            case .Specular:
                num = specular_tex_counter
                specular_tex_counter += 1
                shader_set_int(shader, strings.clone_to_cstring(fmt.tprintf("material.specular_tex_%d", num)), i)

            case .Normal:
                num = normal_tex_counter
                normal_tex_counter += 1
                shader_set_int(shader, strings.clone_to_cstring(fmt.tprintf("material.normal_tex_%d", num)), i)

            case .Height:
                num = height_tex_counter
                height_tex_counter += 1
                shader_set_int(shader, strings.clone_to_cstring(fmt.tprintf("material.height_tex_%d", num)), i)
        }
        gl.BindTexture(gl.TEXTURE_2D, mesh.textures[i].id)
    }

    // draw mesh
    gl.BindVertexArray(mesh.VAO)
    gl.DrawElements(gl.TRIANGLES, i32(len(mesh.indices)), gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)

    gl.ActiveTexture(gl.TEXTURE0)
}