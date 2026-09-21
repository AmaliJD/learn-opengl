package main

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32

create_vec3 :: proc
{
    create_vec3_xy_z
}

@(private="file")
create_vec3_xy_z :: proc(xy: vec2, z: f32) -> vec3
{
    return vec3{xy.x, xy.y, z}
}

mat2 :: matrix[2, 2]f32
mat3 :: matrix[3, 3]f32
mat4 :: matrix[4, 4]f32