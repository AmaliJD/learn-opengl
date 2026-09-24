package main

import "core:fmt"
import "base:runtime"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:math/linalg"

import "vendor:glfw"
import gl "vendor:OpenGL"
import "glx"
import stbi "vendor:stb/image"

Level :: struct
{
    bricks: [dynamic]GameObject,
}

create_and_load_level :: proc(path: string, width, height: u32) -> Level
{
    level: Level

    load_level(&level, path, width, height)

    return level
}

load_level :: proc(level: ^Level, path: string, width, height: u32)
{
    // read from file
    data, err := os.read_entire_file(path, context.temp_allocator)
	if err != nil {
		fmt.printf("Error loading level data from path: %s\n", path)
		return
	}

    tile_data: [dynamic][dynamic]u32
    defer
    {
        for row in tile_data
        {
            delete(row)
        }
        delete(tile_data)
    }

    it := string(data)
    for line in strings.split_lines_iterator(&it)
    {
        line_it := line
        row: [dynamic]u32
        for word in strings.fields_iterator(&line_it)
        {
            value, ok := strconv.parse_uint(word)
            if !ok
            {
                fmt.printf("Invalid level data: %s\n", word)
                return
            }

            append(&row, u32(value))
        }
        
        append(&tile_data, row)
    }

    if len(tile_data) == 0
    {
        return
    }


    // init level
    clear(&level.bricks)

    height_bricks := len(tile_data)
    width_bricks := len(tile_data[0])

    unit_height := f32(height) / f32(height_bricks)
    unit_width := f32(width) / f32(width_bricks)

    for y := 0; y < height_bricks; y += 1
    {
        for x := 0; x < width_bricks; x += 1
        {
            if tile_data[y][x] == 1 // solid
            {
                pos := vec2{unit_width * f32(x), unit_height * f32(y)}
                size := vec2{unit_width, unit_height}

                go := create_gameobject(pos, size, rm_get_texture2d("block_solid"), vec3{.8, .8, .7})
                go.solid = true
                append(&level.bricks, go)
            }
            else if tile_data[y][x] > 1 // breakable
            {
                pos := vec2{unit_width * f32(x), unit_height * f32(y)}
                size := vec2{unit_width, unit_height}

                color := vec3{1,1,1}
                switch tile_data[y][x]
                {
                    case 2:
                        color = vec3{.2,.6,1}
                    case 3:
                        color = vec3{0,.7,0}
                    case 4:
                        color = vec3{.8,.8,.4}
                    case 5:
                        color = vec3{1,.5,0}
                }

                go := create_gameobject(pos, size, rm_get_texture2d("block"), color)
                append(&level.bricks, go)
            }
        }
    }
}

draw_level :: proc(level: ^Level)
{
    for tile in level.bricks
    {
        if !tile.destroyed
        {
            draw_gameobject(tile)
        }
    }
}

is_level_completed :: proc(level: ^Level) -> bool
{
    for tile in level.bricks
    {
        if !tile.solid && !tile.destroyed
        {
            return false
        }
    }

    return true
}