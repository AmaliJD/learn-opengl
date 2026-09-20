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

basics_scene :: proc(window: glfw.WindowHandle)
{
    //cam = create_camera(vec3{0, 0, 3})

    optimized_vertices : []f32 = {
        // positions        // tex coords   // color
        -0.5, -0.5,  0.5,   0.0, 0.0,       0, .2, 1,    // 0
         0.5, -0.5,  0.5,   1.0, 0.0,       .2, 0, 1,    // 1
         0.5,  0.5,  0.5,   1.0, 1.0,       1, .2, 0,    // 2
        -0.5,  0.5,  0.5,   0.0, 1.0,       1, 0, .2,    // 3
        -0.5, -0.5, -0.5,   1.0, 0.0,       1, 1, 0,    // 4
         0.5, -0.5, -0.5,   0.0, 0.0,       1, 1, 0,    // 5
         0.5,  0.5, -0.5,   0.0, 1.0,       0, 1, 1,    // 6
        -0.5,  0.5, -0.5,   1.0, 1.0,       0, 1, 1,    // 7
    }

    indeces : []u32 = {
        0, 1, 2, 2, 3, 0,
        1, 5, 6, 6, 2, 1,
        3, 2, 6, 6, 7, 3,
        4, 0, 3, 3, 7, 4,
        0, 1, 5, 5, 4, 0,
        4, 5, 6, 6, 7, 4,
    }

    // holds all the vertex attribute configuration for reuse
    VAO : u32
    defer {gl.DeleteVertexArrays(1, &VAO)}
    gl.GenVertexArrays(1, &VAO)
    gl.BindVertexArray(VAO)

    // vertex buffer - memory stored on GPU to hold the vertices
    VBO : u32
    defer {gl.DeleteBuffers(1, &VBO)}
    gl.GenBuffers(1, &VBO)
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
    gl.BufferData(gl.ARRAY_BUFFER, len(optimized_vertices) * size_of(f32), &optimized_vertices[0], gl.STATIC_DRAW)

    EBO : u32
    gl.GenBuffers(1, &EBO)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indeces) * size_of(u32), &indeces[0], gl.STATIC_DRAW)

    // shader attribute mapping
    gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(0))
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 3, gl.FLOAT, false, 8 * size_of(f32), uintptr(5 * size_of(f32)))
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(2, 2, gl.FLOAT, false, 8 * size_of(f32), uintptr(3 * size_of(f32)))
    gl.EnableVertexAttribArray(2)

    // shader
    shader : Shader = create_shader("assets/shaders/tutorial.vert", "assets/shaders/tutorial.frag")
    glx.set_wireframe(false)
    gl.Enable(gl.DEPTH_TEST)

    texture1: u32
    gl.GenTextures(1, &texture1)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture1)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    texture2: u32
    gl.GenTextures(1, &texture2)
    gl.ActiveTexture(gl.TEXTURE1)
    gl.BindTexture(gl.TEXTURE_2D, texture2)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    stbi.set_flip_vertically_on_load(1)

    im_width: i32
    im_height: i32
    nr_channels: i32
    im_data := stbi.load("assets/images/container.jpg", &im_width, &im_height, &nr_channels, 0)
    if im_data != nil
    {
        gl.ActiveTexture(gl.TEXTURE0)
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, im_width, im_height, 0, gl.RGB, gl.UNSIGNED_BYTE, im_data)
        gl.GenerateMipmap(gl.TEXTURE_2D)
    }
    stbi.image_free(im_data)
    im_data = stbi.load("assets/images/awesomeface.png", &im_width, &im_height, &nr_channels, 0)
    if im_data != nil
    {
        gl.ActiveTexture(gl.TEXTURE1)
        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, im_width, im_height, 0, gl.RGBA, gl.UNSIGNED_BYTE, im_data)
        gl.GenerateMipmap(gl.TEXTURE_2D)
    }
    stbi.image_free(im_data)

    use_shader(shader)
    shader_set_int(shader, "texture1", 0)
    shader_set_int(shader, "texture2", 1)

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

        // matrices
        identity : mat4 = 1
        projection : mat4 = identity * linalg.matrix4_perspective(linalg.to_radians(cam.fov), SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, 100)
        view : mat4 = camera_get_view_matrix(&cam)
        
        shader_set_mat4(shader, "view", view)
        shader_set_mat4(shader, "projection", projection)

        gl.BindVertexArray(VAO)
        trans := linalg.matrix4_translate(vec3{0,0,0})
        angle := f32(0)
        rot := linalg.matrix4_rotate(f32(glfw.GetTime()) * linalg.to_radians(angle), vec3{1,.3,.5})
        model := identity * trans * rot
        shader_set_mat4(shader, "model", model)

        // gl.DrawArrays(gl.TRIANGLES, 0, 36)
        gl.DrawElements(gl.TRIANGLES, i32(len(indeces)), gl.UNSIGNED_INT, nil)
        gl.BindVertexArray(0)

        // end
        glfw.PollEvents()
        glfw.SwapBuffers(window)
    }

    
}