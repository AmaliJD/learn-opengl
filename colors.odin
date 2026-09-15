package main

Color :: [4]f32

CLEAR : Color = { 0.0, 0.0, 0.0, 0.0 }
WHITE : Color = { 1.0, 1.0, 1.0, 1.0 }
BLACK : Color = { 0.0, 0.0, 0.0, 1.0 }
RED : Color = { 1.0, 0.0, 0.0, 1.0 }

GRAY_15 : Color = { .15, .15, .15, 1.0 }
BG : Color = { .1, .12, .15, 1.0 } * .3

rgba :: proc(c: Color) -> (f32, f32, f32, f32)
{
    return c.r, c.g, c.b, c.a
}