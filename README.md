# LearnOpenGL (https://learnopengl.com/)

Following the LearnOpenGL tutorial + translating all the C++ code to Odin

<br>

## Getting Started: (https://learnopengl.com/Getting-started/OpenGL)

Getting started teaches you the basics of using VAOs and VBOs to render 2D  and 3D shapes, and using shaders for coloring and texturing.

https://github.com/user-attachments/assets/a47abff2-e092-4897-84d2-37e48b0e6352

<br>

## Lighting: (https://learnopengl.com/Lighting/Colors)

I added an effect in the fragment shader to color any side of a cube facing away from the camera at a great enough angle. The color depends on the normal direction of the face. I called the effect *glance* color as it ends up highlighting faces you are seeing at a glance.

https://github.com/user-attachments/assets/4670e809-e3be-405d-bf8e-d964715837f8

<br>

## Text Rendering: (https://learnopengl.com/In-Practice/Text-Rendering)

The font used here is **Piazzolla** from HT Fonts

<img width="797" height="597" alt="Screenshot 2026-10-06 205539" src="https://github.com/user-attachments/assets/1a18c16d-811c-4c0a-934e-12e523a2bcb7" />

<br>
<br>

## Breakout Game: (https://learnopengl.com/In-Practice/2D-Game/Breakout)

Unlike most of the previous code where I was translating the C++ OOP example code into Odin code, I did not use the IrrKlang library for audio. Instead I used Odin's vendor included library *miniaudio* and wrote my own abstractions around that.

The Audio_Engine struct contains a map of miniaudio _sound_ structs for persistent audio (bg music) and a map of paths for one-shot audio (sfx)
```
Audio_Engine :: struct
{
    engine: ^ma.engine,
    device: ^ma.device,
    resource_manager: ^ma.resource_manager,

    managed_sounds: map[string]^ma.sound,
    one_shot_sounds: map[string]cstring,
}
```

It's a small thing but it felt very satisfying building a functional system in Odin for what is basically a rudimentary custom engine!

https://github.com/user-attachments/assets/eb221609-32a8-4336-9fec-a22d97df6ad9





