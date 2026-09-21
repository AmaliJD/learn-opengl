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

Texture2D :: struct
{
    id: u32,

    width, height: i32,

    internal_format: i32,
    image_format: u32,

    wrap_s, wrap_t: i32,
    filter_min, filter_max: i32,
}

create_texture2d :: proc(path: cstring, alpha: bool) -> Texture2D
{
    texture: Texture2D

    // initialize struct values
    gl.GenTextures(1, &texture.id)

    texture.width = 0
    texture.height = 0

    texture.internal_format = alpha ? gl.RGBA : gl.RGB
    texture.image_format = alpha ? gl.RGBA : gl.RGB

    texture.wrap_s = gl.REPEAT
    texture.wrap_t = gl.REPEAT

    texture.filter_min = gl.LINEAR
    texture.filter_max = gl.LINEAR

    // load image
    width, height: i32
    nr_channels: i32
    data := stbi.load(path, &width, &height, &nr_channels, 0)
    if data == nil
    {
        fmt.printf("Error loading image data\n")
        stbi.image_free(data)
        return texture
    }

    texture.width = width
    texture.height = height
    
    // create gl texture
    gl.BindTexture(gl.TEXTURE_2D, texture.id)
    gl.TexImage2D(gl.TEXTURE_2D, 0, texture.internal_format, texture.width, texture.height, 0, texture.image_format, gl.UNSIGNED_BYTE, data)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, texture.wrap_s)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, texture.wrap_t)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, texture.filter_min)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, texture.filter_max)

    gl.BindTexture(gl.TEXTURE_2D, 0) // unbind texture

    return texture
}

bind_texture :: proc(texture: Texture2D)
{
    gl.BindTexture(gl.TEXTURE_2D, texture.id)
}