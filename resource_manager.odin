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

Resource_Manager :: struct
{
    shaders: map[string]Shader,
    textures: map[string]Texture2D,
}

resource_manager := Resource_Manager{}

rm_create_shader :: proc(vertex_path, fragment_path, name: string)
{
    shader := create_shader(vertex_path, fragment_path)
    resource_manager.shaders[name] = shader
}

rm_get_shader :: proc(name: string) -> Shader
{
    return resource_manager.shaders[name]
}

rm_create_texture2d :: proc(path: cstring, alpha: bool, name: string)
{
    texture := create_texture2d(path, alpha)
    resource_manager.textures[name] = texture
}

rm_get_texture2d :: proc(name: string) -> Texture2D
{
    return resource_manager.textures[name]
}

rm_clear :: proc()
{
    for name, &shader in resource_manager.shaders
    {
        gl.DeleteProgram(shader)
    }

    for name, &texture in resource_manager.textures
    {
        gl.DeleteTextures(1, &texture.id)
    }

    clear(&resource_manager.shaders)
    clear(&resource_manager.textures)
}