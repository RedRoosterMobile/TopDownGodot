shader_type canvas_item;

uniform float force;
uniform float size;
uniform float thickness;
uniform vec2 center;
uniform sampler2D screen_texture: hint_screen_texture;
/*
void fragmentt() {
    float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 scaledUV = ( SCREEN_UV - vec2(0.5, 0.0) ) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
    float mask = (1.0 - smoothstep(size-0.1, size, length(scaledUV - center))) * 
                        smoothstep(size-thickness-0.1, size-thickness, length(scaledUV - center));
    vec2 disp = normalize(scaledUV - center) * force * mask;
    COLOR = texture(screen_texture, SCREEN_UV - disp);
}*/
void fragment() {
    float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    
    // Adjust both SCREEN_UV and center for aspect ratio
    vec2 scaledUV = (SCREEN_UV - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
    vec2 scaledCenter = (center - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
    
    float dist = length(scaledUV - scaledCenter);
    float mask = (1.0 - smoothstep(size - 0.1, size, dist)) * 
                 smoothstep(size - thickness - 0.1, size - thickness, dist);
    vec2 disp = normalize(scaledUV - scaledCenter) * force * mask;
    COLOR = texture(screen_texture, SCREEN_UV - disp);
}
