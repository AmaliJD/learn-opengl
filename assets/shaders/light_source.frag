#version 330 core
out vec4 Frag_Color;

uniform vec3 light_color;

void main()
{
    Frag_Color = vec4(light_color, 1.0);
}