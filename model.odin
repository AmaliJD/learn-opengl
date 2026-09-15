package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"

import "vendor:glfw"
import gl "vendor:OpenGL"

@(private="file")
textures: [dynamic]Texture

Model :: struct
{
    meshes: []Mesh,
    directory: string,
}

create_model :: proc(path: string) -> Model
{
    // load model from path

    model: Model
    return model
}

draw_model :: proc(model: Model, shader: Shader)
{
    for i in 0..<len(model.meshes)
    {
        draw_mesh(model.meshes[i], shader)
    }
}