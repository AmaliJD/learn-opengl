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
import ma "vendor:miniaudio"

Audio_Engine :: struct
{
    engine: ^ma.engine,
    device: ^ma.device,
    resource_manager: ^ma.resource_manager,

    managed_sounds: map[string]^ma.sound,
    one_shot_sounds: map[string]cstring,
}
audio_engine: Audio_Engine


// -------------------------------------------------------------------------------------------------- create / destroy

create_audio_engine :: proc() -> Audio_Engine
{
    ae: Audio_Engine
    result: ma.result
    engine := new(ma.engine)

    result = ma.engine_init(nil, engine)
    if result != .SUCCESS
    {
        fmt.printfln("create_audio(): Error inititalizing audio engine")
        free(engine)
        return ae
    }

    ae.engine = engine
    ae.device = ma.engine_get_device(ae.engine)
    ae.resource_manager = ma.engine_get_resource_manager(ae.engine)

    return ae
}

destroy_audio_engine :: proc(ae: ^Audio_Engine)
{
    for name, &sound in ae.managed_sounds
    {
        remove_sound(name)
    }

    free(ae.engine)
}


// -------------------------------------------------------------------------------------------------- managed sounds
add_sound :: proc(path: cstring, name: string)
{
    result: ma.result
    sound := new(ma.sound)

    result = ma.sound_init_from_file(audio_engine.engine, path, ma.sound_flags{}, nil, nil, sound)
    if result != .SUCCESS
    {
        fmt.printfln("add_sound(): Error inititalizing sound at path: %s", path)
        free(sound)
        return
    }

    audio_engine.managed_sounds[name] = sound
}

remove_sound :: proc(name: string)
{
    sound := audio_engine.managed_sounds[name]
    ma.sound_uninit(sound)
    free(sound)

    delete_key(&audio_engine.managed_sounds, name)
}

play_sound :: proc(name: string, loop :b32= false)
{
    ma.sound_start(audio_engine.managed_sounds[name])
    set_sound_loop(name, loop)
}

stop_sound :: proc(name: string)
{
    ma.sound_stop(audio_engine.managed_sounds[name])
}

restart_sound :: proc(name: string)
{
    ma.sound_seek_to_pcm_frame(audio_engine.managed_sounds[name], 0)
}

set_sound_loop :: proc(name: string, loop: b32)
{
    ma.sound_set_looping(audio_engine.managed_sounds[name], loop)
}

// -------------------------------------------------------------------------------------------------- one shot sounds
add_sound_one_shot :: proc(path: cstring, name: string)
{
    audio_engine.one_shot_sounds[name] = path
}

remove_sound_one_shot :: proc(name: string)
{
    delete_key(&audio_engine.one_shot_sounds, name)
}

play_sound_one_shot :: proc(name: string)
{
    ma.engine_play_sound(audio_engine.engine, audio_engine.one_shot_sounds[name], nil)
}