shader_type spatial;
render_mode unshaded;
varying vec2 p;
void vertex() { p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
    float ripple = sin(p.y*2.0 + sin(p.x*0.4) + TIME*0.6);
    float crest = smoothstep(0.90, 1.0, ripple);
    ALBEDO = mix(vec3(0.19,0.43,0.48), vec3(0.50,0.70,0.65), crest*0.38);
}
