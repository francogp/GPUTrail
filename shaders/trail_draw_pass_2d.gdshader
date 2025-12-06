shader_type canvas_item;

render_mode unshaded, skip_vertex_transform;

uniform sampler2D tex : repeat_enable, source_color, hint_default_white;
uniform sampler2D color_ramp : repeat_disable, source_color, hint_default_white;
uniform sampler2D curve : repeat_disable, hint_default_white;
uniform mat4 canvas_transform = mat4(1.0);
uniform vec2 uv_offset = vec2(0);
uniform int flags = 0;

// Flag definitions - evaluated once as floats for branchless operations
#define f_vertical_texture  float(flags & 1)
#define f_use_red_as_alpha  float((flags >> 1) & 1)
#define f_dewiggle          float((flags >> 3) & 1)

varying float scale_interp;
varying vec2 base_uv_out;

void vertex(){
    // Recover 4 corner positions from MODEL_MATRIX
    vec2 a_left = MODEL_MATRIX[0].xy;
    vec2 a_right = MODEL_MATRIX[1].xy;
    vec2 b_left = MODEL_MATRIX[2].xy;
    vec2 b_right = MODEL_MATRIX[3].xy;
    
    // Trail age for fade (branchless)
    float index = INSTANCE_CUSTOM.w;
    float total = max(INSTANCE_CUSTOM.z, 2.0);  // Branchless min check
    float trail_t = clamp((index - 1.0) / total, 0.0, 1.0);
    
    // Width curve modulation
    float h = textureLod(curve, vec2(trail_t, 0.0), 0.0).x;
    scale_interp = h;
    
    // Interpolate quad corners based on UV
    vec2 top = mix(a_left, a_right, UV.x);
    vec2 bottom = mix(b_left, b_right, UV.x);
    
    // Apply width modulation
    vec2 center = (top + bottom) * 0.5;
    vec2 final_top = center + (top - center) * h;
    vec2 final_bottom = center + (bottom - center) * h;
    
    vec2 final_pos = mix(final_top, final_bottom, UV.y);
    
    VERTEX = final_pos;
    
    // Store trail_t for fragment
    UV.x = trail_t;
    base_uv_out = UV;
}

void fragment(){
    vec2 base_uv = base_uv_out;
    
    // Dewiggle: branchless UV adjustment
    // When dewiggle is enabled and scale_interp > 0.001, divide UV by scale_interp
    float dewiggle_factor = mix(1.0, 1.0 / max(scale_interp, 0.001), f_dewiggle * step(0.001, scale_interp));
    base_uv *= dewiggle_factor;
    
    base_uv -= uv_offset;
    
    // Vertical texture: branchless swap
    // When vertical_texture is enabled, swap x and y
    base_uv = mix(base_uv, base_uv.yx, f_vertical_texture);
    
    // Sample texture
    vec4 T = texture(tex, base_uv);
    
    // Use red as alpha: branchless selection
    // When enabled: rgb = vec3(1.0), a = T.r
    // When disabled: keep T as-is
    vec4 color = mix(T, vec4(1.0, 1.0, 1.0, T.r), f_use_red_as_alpha);
    
    // Apply color ramp
    vec4 ramp = texture(color_ramp, vec2(base_uv_out.x, 0.0));
    color *= ramp;
    
    // Fade based on age
    color.a *= (1.0 - base_uv_out.x);
    
    COLOR = color;
}
