shader_type particles;
render_mode keep_data, disable_force, disable_velocity;

uniform mat4 emission_transform;
uniform float width = 20.0;
uniform vec2 move_direction = vec2(1.0, 0.0);

void process() {
    float amount = LIFETIME;
    
    // Current emitter position
    vec2 origin = emission_transform[3].xy;
    
    // Width direction is perpendicular to movement
    vec2 width_dir = vec2(-move_direction.y, move_direction.x);
    
    // Apply width (branchless: use max instead of if)
    float w = max(width, 1.0);
    width_dir *= (w * 0.5);
    
    vec2 a_pos = origin + width_dir;
    vec2 b_pos = origin - width_dir;
    
    // Initialize on first frame (branchless where possible)
    // CUSTOM.w starts at 0.0, so first frame initialization is required
    float is_first_frame = step(CUSTOM.w, 0.0);  // 1.0 if first frame, 0.0 otherwise
    
    CUSTOM.w = mix(CUSTOM.w, float(INDEX) + 1.0, is_first_frame);
    CUSTOM.z = mix(CUSTOM.z, amount, is_first_frame);
    
    // First frame sets all corners to current position
    vec4 init_a = vec4(a_pos.x, a_pos.y, 0.0, 0.0);
    vec4 init_b = vec4(b_pos.x, b_pos.y, 0.0, 0.0);
    vec4 init_b_origin = vec4(b_pos.x, b_pos.y, 0.0, 1.0);
    
    TRANSFORM[0] = mix(TRANSFORM[0], init_a, is_first_frame);
    TRANSFORM[1] = mix(TRANSFORM[1], init_a, is_first_frame);
    TRANSFORM[2] = mix(TRANSFORM[2], init_b, is_first_frame);
    TRANSFORM[3] = mix(TRANSFORM[3], init_b_origin, is_first_frame);
    
    // Cycle reset (branchless)
    float reset_cycle = step(amount + 0.5, CUSTOM.w);  // 1.0 if needs reset
    CUSTOM.w = mix(CUSTOM.w, 1.0, reset_cycle);
    
    // HEAD check (w close to 1.0)
    float is_head = step(0.9, CUSTOM.w) * step(CUSTOM.w, 1.1);
    
    // HEAD: Reset both edges to current
    TRANSFORM[0] = mix(TRANSFORM[0], init_a, is_head);
    TRANSFORM[1] = mix(TRANSFORM[1], init_a, is_head);
    TRANSFORM[2] = mix(TRANSFORM[2], init_b, is_head);
    TRANSFORM[3] = mix(TRANSFORM[3], init_b_origin, is_head);
    
    // SECOND check (w close to 2.0)
    float is_second = step(1.9, CUSTOM.w) * step(CUSTOM.w, 2.1);
    
    // SECOND: Update right edge only
    TRANSFORM[1] = mix(TRANSFORM[1], init_a, is_second);
    TRANSFORM[3] = mix(TRANSFORM[3], init_b_origin, is_second);
    
    CUSTOM.w += 1.0;
}
