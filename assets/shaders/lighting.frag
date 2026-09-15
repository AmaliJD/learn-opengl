#version 330 core
out vec4 Frag_Color;

in vec3 o_frag_pos;
in vec3 o_normal;
in vec2 o_tex_coords;

uniform vec3 view_pos;

struct Material
{
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};
uniform Material material;

struct Directional_Light
{
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    bool enabled;
};
uniform Directional_Light directional_light;
vec3 Calculate_Directional_Light(Directional_Light light, vec3 normal, vec3 view_direction);

struct Point_Light
{
    vec3 position;

    // attenuation
    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    bool enabled;
};
#define MAX_POINT_LIGHTS 4
uniform Point_Light point_lights[MAX_POINT_LIGHTS];
vec3 Calculate_Point_Light(Point_Light light, vec3 normal, vec3 frag_pos, vec3 view_direction);

struct Spot_Light
{
    vec3 position;
    vec3 direction;

    float hard_cutoff;
    float soft_cutoff;

    // attenuation
    float constant;
    float linear;
    float quadratic;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    bool enabled;
};
uniform Spot_Light spot_light;
vec3 Calculate_Spot_Light(Spot_Light light, vec3 normal, vec3 frag_pos, vec3 view_direction);

void main()
{
    vec3 normal = normalize(o_normal);
    vec3 view_direction = normalize(view_pos - o_frag_pos);

    // Directional Light
    vec3 result = Calculate_Directional_Light(directional_light, normal, view_direction);

    // Point Lights
    for (int i = 0; i < MAX_POINT_LIGHTS; i++)
    {
        result += Calculate_Point_Light(point_lights[i], normal, o_frag_pos, view_direction);
    }

    // Spot Light
    result += Calculate_Spot_Light(spot_light, normal, o_frag_pos, view_direction);

    // Glance
    float view_alignment = dot(view_direction, normal);
    view_alignment = clamp(view_alignment / 0.2, 0.0, 1.0);

    float normal_alignment = abs(dot(vec3(0, 1, 0), normal));
    float z_alignment = dot(vec3(0, 0, -1), normal);
    vec3 edge_color = mix(vec3(1.5, 0, 0), vec3(0, 0, 3), normal_alignment);
    edge_color =  mix(edge_color, vec3(.45, 1.5, 0), sign(z_alignment) * abs(pow(z_alignment, 3)));

    if (view_alignment >= 0)
    {
        result = mix(edge_color, result, view_alignment);
    }

    Frag_Color = vec4(result, 1.0);
}

vec3 Calculate_Directional_Light(Directional_Light light, vec3 normal, vec3 view_direction)
{
    if (!light.enabled)
    {
        return vec3(0.0);
    }

    vec3 light_direction = normalize(-light.direction);

    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, o_tex_coords));

    // diffuse
    float normal_alignment = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = light.diffuse * normal_alignment * vec3(texture(material.diffuse, o_tex_coords));

    // specular
    vec3 reflect_direction = reflect(-light_direction, normal);
    float view_alignment = pow(max(dot(view_direction, reflect_direction), 0.0), material.shininess);
    vec3 specular = light.specular * view_alignment * vec3(texture(material.diffuse, o_tex_coords));

    return (ambient + diffuse + specular);
}

vec3 Calculate_Point_Light(Point_Light light, vec3 normal, vec3 frag_pos, vec3 view_direction)
{
    if (!light.enabled)
    {
        return vec3(0.0);
    }

    vec3 light_direction = normalize(light.position - frag_pos);

    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, o_tex_coords));

    // diffuse
    float normal_alignment = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = light.diffuse * normal_alignment * vec3(texture(material.diffuse, o_tex_coords));

    // specular
    vec3 reflect_direction = reflect(-light_direction, normal);
    float view_alignment = pow(max(dot(view_direction, reflect_direction), 0.0), material.shininess);
    vec3 specular = light.specular * view_alignment * vec3(texture(material.diffuse, o_tex_coords));

    // attenuation
    float distance = length(light.position - frag_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));

    return (ambient + diffuse + specular) * attenuation;
}

vec3 Calculate_Spot_Light(Spot_Light light, vec3 normal, vec3 frag_pos, vec3 view_direction)
{
    if (!light.enabled)
    {
        return vec3(0.0);
    }

    vec3 light_direction = normalize(light.position - frag_pos);

    // ambient
    vec3 ambient = light.ambient * vec3(texture(material.diffuse, o_tex_coords));

    // diffuse
    float normal_alignment = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = light.diffuse * normal_alignment * vec3(texture(material.diffuse, o_tex_coords));

    // specular
    vec3 reflect_direction = reflect(-light_direction, normal);
    float view_alignment = pow(max(dot(view_direction, reflect_direction), 0.0), material.shininess);
    vec3 specular = light.specular * view_alignment * vec3(texture(material.diffuse, o_tex_coords));

    // attenuation
    float distance = length(light.position - frag_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));

    // light cone
    float theta = dot(light_direction, normalize(-light.direction));
    float epsilon = light.hard_cutoff - light.soft_cutoff;
    float cutoff_intensity = clamp((theta - light.soft_cutoff) / epsilon, 0.0, 1.0);

    diffuse *= cutoff_intensity;
    specular *= cutoff_intensity;

    if (theta > light.soft_cutoff)
    {
        diffuse *= cutoff_intensity;
        specular *= cutoff_intensity;
        return (ambient + diffuse + specular) * attenuation;
    }
    else
    {
        return vec3(0);
    }
}