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

characters := [128]Character{}