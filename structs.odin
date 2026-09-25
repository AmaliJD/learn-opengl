package main

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32

mat2 :: matrix[2, 2]f32
mat3 :: matrix[3, 3]f32
mat4 :: matrix[4, 4]f32

// --------------------------------------------------- vec2
create_vec2 :: proc
{
    create_vec2_x
}

@(private="file")
create_vec2_x :: proc(x: f32) -> vec2
{
    return vec2{x, x}
}

// --------------------------------------------------- vec3
create_vec3 :: proc
{
    create_vec3_x,
    create_vec3_xy_z
}

@(private="file")
create_vec3_x :: proc(x: f32) -> vec3
{
    return vec3{x, x, x}
}

@(private="file")
create_vec3_xy_z :: proc(xy: vec2, z: f32) -> vec3
{
    return vec3{xy.x, xy.y, z}
}

// --------------------------------------------------- vec4
create_vec4 :: proc
{
    create_vec4_x,
}

@(private="file")
create_vec4_x :: proc(x: f32) -> vec4
{
    return vec4{x, x, x, x}
}