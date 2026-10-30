shader_type spatial;
render_mode unshaded;

uniform sampler2D sand : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D stone : source_color, filter_linear_mipmap, repeat_enable;
uniform float daylight = 1.0;
varying vec2 ground_position;

void vertex() {
    ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
    vec2 p = ground_position;
    vec2 uv = p / 5.0;
    float edge = sin(p.x * 0.23) * 2.2 + sin(p.x * 0.61) * 0.6;
    vec3 green = texture(grass, uv).rgb;
    vec3 beach = texture(sand, uv).rgb;
    vec3 mineral = texture(stone, uv).rgb;
    vec3 color = mix(green, mineral, smoothstep(-2.0, 5.0, p.x));
    color = mix(color, mineral * vec3(0.68, 0.76, 0.87),
        (1.0-smoothstep(-2.0, 4.0, p.x)) * (1.0-smoothstep(-21.0, -14.0, p.y+edge)));
    color = mix(color, beach, smoothstep(12.0, 21.0, p.y+edge));
    float path = 1.0-smoothstep(1.0, 2.4, abs(p.x - sin(p.y*0.13)*2.5));
    color = mix(color, beach * 0.87, path * 0.55);
    color *= 0.97 + 0.03*sin(p.x*0.83)*sin(p.y*0.71);
    ALBEDO = color * daylight;
}
