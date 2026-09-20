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

lighting_scene :: proc(window: glfw.WindowHandle)
{
    //cam = create_camera(vec3{0, 0, 3})

    gl.Enable(gl.DEPTH_TEST)

    // shader
    lighting_shader : Shader = create_shader("assets/shaders/lighting.vert", "assets/shaders/lighting.frag")
    light_source_shader : Shader = create_shader("assets/shaders/light_source.vert", "assets/shaders/light_source.frag")

    vertices: []f32 = {
        // positions          // normals           // texture coords
        -0.5, -0.5, -0.5,     0.0,  0.0, -1.0,    0.0, 0.0,
        0.5, -0.5, -0.5,     0.0,  0.0, -1.0,    1.0, 0.0,
        0.5,  0.5, -0.5,     0.0,  0.0, -1.0,    1.0, 1.0,
        0.5,  0.5, -0.5,     0.0,  0.0, -1.0,    1.0, 1.0,
        -0.5,  0.5, -0.5,     0.0,  0.0, -1.0,    0.0, 1.0,
        -0.5, -0.5, -0.5,     0.0,  0.0, -1.0,    0.0, 0.0,

        -0.5, -0.5,  0.5,     0.0,  0.0,  1.0,    0.0, 0.0,
        0.5, -0.5,  0.5,     0.0,  0.0,  1.0,    1.0, 0.0,
        0.5,  0.5,  0.5,     0.0,  0.0,  1.0,    1.0, 1.0,
        0.5,  0.5,  0.5,     0.0,  0.0,  1.0,    1.0, 1.0,
        -0.5,  0.5,  0.5,     0.0,  0.0,  1.0,    0.0, 1.0,
        -0.5, -0.5,  0.5,     0.0,  0.0,  1.0,    0.0, 0.0,

        -0.5,  0.5,  0.5,    -1.0,  0.0,  0.0,    1.0, 0.0,
        -0.5,  0.5, -0.5,    -1.0,  0.0,  0.0,    1.0, 1.0,
        -0.5, -0.5, -0.5,    -1.0,  0.0,  0.0,    0.0, 1.0,
        -0.5, -0.5, -0.5,    -1.0,  0.0,  0.0,    0.0, 1.0,
        -0.5, -0.5,  0.5,    -1.0,  0.0,  0.0,    0.0, 0.0,
        -0.5,  0.5,  0.5,    -1.0,  0.0,  0.0,    1.0, 0.0,

        0.5,  0.5,  0.5,     1.0,  0.0,  0.0,    1.0, 0.0,
        0.5,  0.5, -0.5,     1.0,  0.0,  0.0,    1.0, 1.0,
        0.5, -0.5, -0.5,     1.0,  0.0,  0.0,    0.0, 1.0,
        0.5, -0.5, -0.5,     1.0,  0.0,  0.0,    0.0, 1.0,
        0.5, -0.5,  0.5,     1.0,  0.0,  0.0,    0.0, 0.0,
        0.5,  0.5,  0.5,     1.0,  0.0,  0.0,    1.0, 0.0,

        -0.5, -0.5, -0.5,     0.0, -1.0,  0.0,    0.0, 1.0,
        0.5, -0.5, -0.5,     0.0, -1.0,  0.0,    1.0, 1.0,
        0.5, -0.5,  0.5,     0.0, -1.0,  0.0,    1.0, 0.0,
        0.5, -0.5,  0.5,     0.0, -1.0,  0.0,    1.0, 0.0,
        -0.5, -0.5,  0.5,     0.0, -1.0,  0.0,    0.0, 0.0,
        -0.5, -0.5, -0.5,     0.0, -1.0,  0.0,    0.0, 1.0,

        -0.5,  0.5, -0.5,     0.0,  1.0,  0.0,    0.0, 1.0,
        0.5,  0.5, -0.5,     0.0,  1.0,  0.0,    1.0, 1.0,
        0.5,  0.5,  0.5,     0.0,  1.0,  0.0,    1.0, 0.0,
        0.5,  0.5,  0.5,     0.0,  1.0,  0.0,    1.0, 0.0,
        -0.5,  0.5,  0.5,     0.0,  1.0,  0.0,    0.0, 0.0,
        -0.5,  0.5, -0.5,     0.0,  1.0,  0.0,    0.0, 1.0,
    }

    // cube VAO
    cube_VAO: u32
    gl.GenVertexArrays(1, &cube_VAO)
    gl.BindVertexArray(cube_VAO)

    // VBO (for both cube and light)
    VBO: u32
    gl.GenBuffers(1, &VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32), &vertices[0], gl.STATIC_DRAW)

    // cube - shader attribute mapping
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(0))
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(3 * size_of(f32)))
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8 * size_of(f32), uintptr(6 * size_of(f32)))
    gl.EnableVertexAttribArray(2)

    // light VA (same VBO)
    light_VAO : u32
    gl.GenVertexArrays(1, &light_VAO)
    gl.BindVertexArray(light_VAO)

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)

    // light - shader attribute mapping
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(0))
    gl.EnableVertexAttribArray(0)

    defer
    {
        gl.DeleteVertexArrays(1, &cube_VAO)
        gl.DeleteVertexArrays(1, &light_VAO)
        gl.DeleteBuffers(1, &VBO)
    }

    // load textures
    diffuse_map: u32 = load_texture("assets/images/container2.png")
    specular_map: u32 = load_texture("assets/images/container2_specular.png")

    use_shader(lighting_shader)
    shader_set_int(lighting_shader, "material.diffuse", 0)
    shader_set_int(lighting_shader, "material.specular", 1)

    cube_positions := []vec3 {
        vec3{ 0.0,  0.0,   0.0 },
        vec3{ 2.0,  5.0, -15.0 },
        vec3{-1.5, -2.2,  -2.5 },
        vec3{-3.8, -2.0, -12.3 },
        vec3{ 2.4, -0.4,  -3.5 },
        vec3{-1.7,  3.0,  -7.5 },
        vec3{ 1.3, -2.0,  -2.5 },
        vec3{ 1.5,  2.0,  -2.5 },
        vec3{ 1.5,  0.2,  -1.5 },
        vec3{-1.3,  1.0,  -1.5 },
    }

    point_light_positions := []vec3 {
        vec3{ 0.7,  0.2,   2.0 },
        vec3{ 2.3, -3.3,  -4.0 },
        vec3{-4.0,  2.0, -12.0 },
        vec3{ 0.0,  0.0,  -3.0 },
    }

    point_light_colors := []vec3 {
        vec3{ 1, 1, 1 },
        vec3{ 1, .5, .5 },
        vec3{ .3, .9, 1.5 },
        vec3{ .9, 1, .3 },
    }

    // render loop
    for !glfw.WindowShouldClose(window)
    {
        curr_frame_time := glfw.GetTime()
        delta_time = curr_frame_time - prev_frame_time
        prev_frame_time = curr_frame_time

        // input
        process_input(window)

        // rendering
        gl.ClearColor(rgba(BG))
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        orbit_radius : f32 = 3
        time32 := f32(glfw.GetTime() * 1)
        //light_source_pos = orbit_radius * vec3{math.cos(time32),  math.sin(time32), 0}

        use_shader(lighting_shader)
        shader_set_vec3(lighting_shader, "view_pos", cam.position)
        shader_set_float(lighting_shader, "material.shininess", 32)

        directional_light_color := vec3{1, 1, 1}
        //shader_set_bool(lighting_shader,  "directional_light.enabled", true)
        shader_set_vec3(lighting_shader, "directional_light.direction", light_source_pos - vec3{0, 0, 0})
        shader_set_vec3(lighting_shader, "directional_light.ambient", directional_light_color * 0.05)
        shader_set_vec3(lighting_shader, "directional_light.diffuse", directional_light_color * 0.4)
        shader_set_vec3(lighting_shader, "directional_light.specular", directional_light_color * 0.5)

        point_light_constant: f32 = .1
        point_light_linear: f32 = 0.2
        point_light_quadratic: f32 = 0.2
        shader_set_bool(lighting_shader,  "point_lights[0].enabled", true)
        shader_set_vec3(lighting_shader, "point_lights[0].position", point_light_positions[0])
        shader_set_vec3(lighting_shader, "point_lights[0].ambient",  point_light_colors[0] * 0.05)
        shader_set_vec3(lighting_shader, "point_lights[0].diffuse",  point_light_colors[0] * 0.8)
        shader_set_vec3(lighting_shader, "point_lights[0].specular", point_light_colors[0] * 1)
        shader_set_float(lighting_shader, "point_lights[0].constant", point_light_constant)
        shader_set_float(lighting_shader, "point_lights[0].linear", point_light_linear)
        shader_set_float(lighting_shader, "point_lights[0].quadratic", point_light_quadratic)

        shader_set_bool(lighting_shader,  "point_lights[1].enabled", true)
        shader_set_vec3(lighting_shader, "point_lights[1].position", point_light_positions[1])
        shader_set_vec3(lighting_shader, "point_lights[1].ambient",  point_light_colors[1] * 0.05)
        shader_set_vec3(lighting_shader, "point_lights[1].diffuse",  point_light_colors[1] * 0.8)
        shader_set_vec3(lighting_shader, "point_lights[1].specular", point_light_colors[1] * 1)
        shader_set_float(lighting_shader, "point_lights[1].constant", point_light_constant)
        shader_set_float(lighting_shader, "point_lights[1].linear", point_light_linear)
        shader_set_float(lighting_shader, "point_lights[1].quadratic", point_light_quadratic)

        shader_set_bool(lighting_shader,  "point_lights[2].enabled", true)
        shader_set_vec3(lighting_shader,  "point_lights[2].position", point_light_positions[2])
        shader_set_vec3(lighting_shader,  "point_lights[2].ambient",  point_light_colors[2] * 0.05)
        shader_set_vec3(lighting_shader,  "point_lights[2].diffuse",  point_light_colors[2] * 0.8)
        shader_set_vec3(lighting_shader,  "point_lights[2].specular", point_light_colors[2] * 1)
        shader_set_float(lighting_shader, "point_lights[2].constant", point_light_constant)
        shader_set_float(lighting_shader, "point_lights[2].linear", .09)
        shader_set_float(lighting_shader, "point_lights[2].quadratic", .032)

        shader_set_bool(lighting_shader,  "point_lights[3].enabled", true)
        shader_set_vec3(lighting_shader,  "point_lights[3].position", point_light_positions[3])
        shader_set_vec3(lighting_shader,  "point_lights[3].ambient",  point_light_colors[3] * 0.05)
        shader_set_vec3(lighting_shader,  "point_lights[3].diffuse",  point_light_colors[3] * 0.8)
        shader_set_vec3(lighting_shader,  "point_lights[3].specular", point_light_colors[3] * 1)
        shader_set_float(lighting_shader, "point_lights[3].constant", point_light_constant)
        shader_set_float(lighting_shader, "point_lights[3].linear", point_light_linear)
        shader_set_float(lighting_shader, "point_lights[3].quadratic", point_light_quadratic)
        
        spot_light_color := vec3{1, 1, 1}
        shader_set_bool(lighting_shader,  "spot_light.enabled", true)
        shader_set_vec3(lighting_shader,  "spot_light.position", cam.position)
        shader_set_vec3(lighting_shader,  "spot_light.direction", cam.forward)
        shader_set_vec3(lighting_shader,  "spot_light.ambient", spot_light_color * 0)
        shader_set_vec3(lighting_shader,  "spot_light.diffuse", spot_light_color * 1)
        shader_set_vec3(lighting_shader,  "spot_light.specular", spot_light_color * 1)
        shader_set_float(lighting_shader, "spot_light.constant", 1)
        shader_set_float(lighting_shader, "spot_light.linear", .09)
        shader_set_float(lighting_shader, "spot_light.quadratic", .032)
        shader_set_float(lighting_shader, "spot_light.hard_cutoff", math.cos(linalg.to_radians(f32(10))))
        shader_set_float(lighting_shader, "spot_light.soft_cutoff", math.cos(linalg.to_radians(f32(15))))

        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, diffuse_map)
        gl.ActiveTexture(gl.TEXTURE1)
        gl.BindTexture(gl.TEXTURE_2D, specular_map)

        projection : mat4 = MAT4_IDENTITY * linalg.matrix4_perspective(linalg.to_radians(cam.fov), SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100)
        view : mat4 = camera_get_view_matrix(&cam)
        model := MAT4_IDENTITY

        // render cubes
        shader_set_mat4(lighting_shader, "projection", projection)
        shader_set_mat4(lighting_shader, "view", view)
        shader_set_mat4(lighting_shader, "model", model)
        
        gl.BindVertexArray(cube_VAO)
        for i in 0..<10
        {
            angle: f32 = 20 * f32(i)
            trans := linalg.matrix4_translate(cube_positions[i])
            rot := linalg.matrix4_rotate(linalg.to_radians(angle), vec3{1, .3, .5})
            model = MAT4_IDENTITY * trans * rot
            shader_set_mat4(lighting_shader, "model", model)

            gl.DrawArrays(gl.TRIANGLES, 0, 36)
        }

        // render lights
        use_shader(light_source_shader)
        shader_set_mat4(light_source_shader, "projection", projection)
        shader_set_mat4(light_source_shader, "view", view)

        gl.BindVertexArray(light_VAO)
        for i in 0..<len(point_light_positions)
        {
            trans := linalg.matrix4_translate(point_light_positions[i])
            scl := linalg.matrix4_scale(vec3{.2, .2, .2})
            model = MAT4_IDENTITY * trans * scl
            shader_set_mat4(light_source_shader, "model", model)
            shader_set_vec3(light_source_shader, "light_color", point_light_colors[i])

            gl.DrawArrays(gl.TRIANGLES, 0, 36)
        }

        // end
        glfw.PollEvents()
        glfw.SwapBuffers(window)
    }
}