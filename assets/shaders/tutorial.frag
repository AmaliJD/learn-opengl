#version 330 core
out vec4 Frag_Color;

in vec3 b_color;
in vec2 b_tex_coord;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    Frag_Color = mix(texture(texture1, b_tex_coord), texture(texture2, b_tex_coord), 0.2) * vec4(b_color, 1.0);
}