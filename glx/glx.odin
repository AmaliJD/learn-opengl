package glx

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"

import "vendor:glfw"
import gl "vendor:OpenGL"

set_wireframe :: proc(value: bool)
{
    gl.PolygonMode(gl.FRONT_AND_BACK, value ? gl.LINE : gl.FILL)
}