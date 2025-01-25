shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 indicator_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.4;
    float thickness = 0.1;
    
    vec2 uv = UV - center;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    
    float circle = smoothstep(radius + thickness, radius - thickness, dist);
    float arc = step(angle, progress * 6.28318530718);
    
    COLOR = indicator_color;
    COLOR.a *= circle * arc;
} 