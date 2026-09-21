package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:math"

import "vendor:glfw"
import gl "vendor:OpenGL"


Shader :: u32

create_shader :: proc(vertex_path, fragment_path: string) -> Shader
{
    // read source files
    vertex_shader_source_raw, err_vert := os.read_entire_file(vertex_path, context.temp_allocator)
    fragment_shader_source_raw, err_frag := os.read_entire_file(fragment_path, context.temp_allocator)
    
    if err_vert != nil
    {
        fmt.printf("Error reading vertex path: %v\n", err_vert)
    }
    if err_frag != nil
    {
        fmt.printf("Error reading fragment path: %v\n", err_frag)
    }

    vertex_shader_source := strings.clone_to_cstring(string(vertex_shader_source_raw))
    fragment_shader_source := strings.clone_to_cstring(string(fragment_shader_source_raw))
    
    // compile 
    success: i32
    info_log: [512]byte

    vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
    gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil)
    gl.CompileShader(vertex_shader)

    fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
    gl.ShaderSource(fragment_shader, 1, &fragment_shader_source, nil)
    gl.CompileShader(fragment_shader)

    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
    if success == 0
    {
        gl.GetShaderInfoLog(vertex_shader, 512, nil, &info_log[0])
        fmt.printf("Error compiling vertex shader: %s\n", string(info_log[:]))
    }
    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success)
    if success == 0
    {
        gl.GetShaderInfoLog(fragment_shader, 512, nil, &info_log[0])
        fmt.printf("Error compiling fragment shader: %s\n", string(info_log[:]))
    }

    // build shader program
    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)

    gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success);
    if success == 0
    {
        gl.GetProgramInfoLog(shader_program, 512, nil, &info_log[0])
        fmt.printf("Error linking shader program: %s\n", string(info_log[:]))
    }

    gl.DeleteShader(vertex_shader)
    gl.DeleteShader(fragment_shader)

    return Shader(shader_program)
}

use_shader :: proc(shader: Shader)
{
    gl.UseProgram(shader)
}


// -------------------------------------------------------------------------------------------------- set uniform parameters

shader_set_bool :: proc(shader: Shader, name: cstring, value: bool)
{
    gl.Uniform1i(gl.GetUniformLocation(shader, name), i32(value))
}

shader_set_int :: proc(shader: Shader, name: cstring, value: i32)
{
    gl.Uniform1i(gl.GetUniformLocation(shader, name), value)
}

shader_set_float :: proc(shader: Shader, name: cstring, value: f32)
{
    gl.Uniform1f(gl.GetUniformLocation(shader, name), value)
}

shader_set_mat4 :: proc(shader: Shader, name: cstring, value: matrix[4, 4]f32)
{
    value_addressable := value
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader, name), 1, false, &value_addressable[0, 0])
}


shader_set_vec2 :: proc
{
    shader_set_vec2_2f,
    shader_set_vec2_2fv,
}

@private
shader_set_vec2_2f :: proc(shader: Shader, name: cstring, x, y: f32)
{
    gl.Uniform2f(gl.GetUniformLocation(shader, name), x, y)
}

@private
shader_set_vec2_2fv :: proc(shader: Shader, name: cstring, value: vec2)
{
    value_addressable := value
    gl.Uniform2fv(gl.GetUniformLocation(shader, name), 1, &value_addressable[0])
}


shader_set_vec3 :: proc
{
    shader_set_vec3_3f,
    shader_set_vec3_3fv,
}

@(private="file")
shader_set_vec3_3f :: proc(shader: Shader, name: cstring, x, y, z: f32)
{
    gl.Uniform3f(gl.GetUniformLocation(shader, name), x, y, z)
}

@(private="file")
shader_set_vec3_3fv :: proc(shader: Shader, name: cstring, value: vec3)
{
    value_addressable := value
    gl.Uniform3fv(gl.GetUniformLocation(shader, name), 1, &value_addressable[0])
}


shader_set_vec4 :: proc
{
    shader_set_vec4_4f,
    shader_set_vec4_4fv,
}

@(private="file")
shader_set_vec4_4f :: proc(shader: Shader, name: cstring, x, y, z, w: f32)
{
    gl.Uniform4f(gl.GetUniformLocation(shader, name), x, y, z, w)
}

@(private="file")
shader_set_vec4_4fv :: proc(shader: Shader, name: cstring, value: vec4)
{
    value_addressable := value
    gl.Uniform4fv(gl.GetUniformLocation(shader, name), 1, &value_addressable[0])
}