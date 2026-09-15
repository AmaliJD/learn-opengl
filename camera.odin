package main

import "core:math/linalg"
import "core:fmt"
import "core:math"

// -------------------------------------------------------------------------------------------------- data

@(private="file") DEFAULT_YAW         :: f32(-90)
@(private="file") DEFAULT_PITCH       :: f32(0)
@(private="file") DEFAULT_SPEED       :: f32(10)
@(private="file") DEFAULT_SENSITIVITY :: f32(0.1)
@(private="file") DEFAULT_FOV         :: f32(45)    // zoom

WORLD_UP :: vec3{ 0, 1, 0 }

Camera :: struct
{
    position, forward, up, right, world_forward, world_right: vec3,
    yaw, pitch, fov: f32,
    movement: Camera_Move_Params,
}

Camera_Move_Params :: struct
{
    speed, cursor_sensitivity: f32,
    local_move_mode: bool,
}

Camera_Move_Direction :: enum
{
    Forward, Backward, Left, Right, Up, Down
}


// -------------------------------------------------------------------------------------------------- camera procs

create_camera :: proc(position := vec3{0,0,0}, up := vec3{0,1,0}, yaw := DEFAULT_YAW, pitch := DEFAULT_PITCH) -> Camera
{
    camera: Camera

    camera.position = position
    camera.up = up

    camera.yaw = yaw
    camera.pitch = pitch

    camera.forward = vec3{0,0,-1}
    camera.fov = DEFAULT_FOV

    camera.movement.speed = DEFAULT_SPEED
    camera.movement.cursor_sensitivity = DEFAULT_SENSITIVITY
    camera.movement.local_move_mode = true

    update_camera_axes(&camera)

    return camera
}

camera_get_view_matrix :: proc(camera: ^Camera) -> mat4
{
    return linalg.matrix4_look_at(camera.position, camera.position + camera.forward, camera.up)
}

@(private="file")
update_camera_axes :: proc(camera: ^Camera)
{
    forward_direction := vec3 {
        math.cos(linalg.to_radians(camera.yaw)) * math.cos(linalg.to_radians(camera.pitch)),
        math.sin(linalg.to_radians(camera.pitch)),
        math.sin(linalg.to_radians(camera.yaw)) * math.cos(linalg.to_radians(camera.pitch)),
    }

    camera.forward = linalg.normalize(forward_direction)
    camera.right = linalg.normalize(linalg.cross(camera.forward, WORLD_UP))
    camera.up = linalg.normalize(linalg.cross(camera.right, camera.forward))

    camera.world_forward = linalg.normalize(linalg.cross(WORLD_UP, camera.right))
    camera.world_right = -linalg.normalize(linalg.cross(WORLD_UP, camera.world_forward))
}


// -------------------------------------------------------------------------------------------------- input processing

camera_keyboard_move :: proc(camera: ^Camera, move_direction: Camera_Move_Direction, delta_time: f64)
{
    speed := camera.movement.speed * f32(delta_time)

    switch move_direction
    {
        case .Forward:
            camera.position += speed * (camera.movement.local_move_mode ? camera.forward : camera.world_forward)
        case .Backward:
            camera.position -= speed * (camera.movement.local_move_mode ? camera.forward : camera.world_forward)
        case .Left:
            camera.position -= speed * (camera.movement.local_move_mode ? camera.right : camera.world_right)
        case .Right:
            camera.position += speed * (camera.movement.local_move_mode ? camera.right : camera.world_right)
        case .Up:
            camera.position += speed * (camera.movement.local_move_mode ? camera.up : WORLD_UP)
        case .Down:
            camera.position -= speed * (camera.movement.local_move_mode ? camera.up : WORLD_UP)
    }
}

camera_cursor_look :: proc(camera: ^Camera, x_offset, y_offset: f32)
{
    adj_x_offset := x_offset * camera.movement.cursor_sensitivity
    adj_y_offset := y_offset * camera.movement.cursor_sensitivity

    camera.yaw += adj_x_offset
    camera.pitch -= adj_y_offset

    camera.pitch = math.clamp(camera.pitch, -89, 89)

    update_camera_axes(camera)
}

camera_scroll_zoom :: proc(camera: ^Camera, y_offset: f32)
{
    camera.fov -= y_offset
    camera.fov = math.clamp(camera.fov, 1, 45)
}