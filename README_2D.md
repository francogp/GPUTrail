# GPUTrail2D - 2D Trail System

A GPU-accelerated 2D ribbon trail system for Godot 4, ported from the 3D GPUTrail.

## New Files

| File | Description |
|------|-------------|
| `GPUTrail2D.gd` | Main script extending `GPUParticles2D` for ribbon trails |
| `shaders/trail_2d.gdshader` | Particle process shader for 2D trails |
| `shaders/trail_draw_pass_2d.gdshader` | Canvas item draw shader for 2D trail rendering |
| `example_2d.tscn` | Example scene demonstrating the trail |
| `example_2d.gd` | Movement script for the example |

## Features

- **Connected ribbon trail** - Smooth, connected polygon mesh (not separate sprites)
- **Movement-aligned width** - Trail width orients perpendicular to movement direction
- **Width curve** - Modulates trail thickness along its length
- **Color ramp** - Fades color/alpha along the trail
- **Dewiggle** - Improves texture mapping on curved sections
- **Vertical texture** - Option to rotate texture 90°
- **Use red as alpha** - Uses red channel for alpha transparency

## Usage

1. Add a `GPUTrail2D` node to your scene
2. Configure properties in the inspector:
   - `width` - Trail thickness in pixels
   - `length` - Number of trail segments
   - `curve` - Width modulation curve (CurveTexture)
   - `color_ramp` - Color/alpha fade (GradientTexture1D)
3. Move the node - the trail follows!

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `length` | int | Number of trail segments |
| `length_seconds` | float | Trail duration in seconds |
| `width` | float | Trail thickness in pixels |
| `trail_texture` | Texture | Main texture applied to trail |
| `scroll` | Vector2 | UV scroll speed |
| `color_ramp` | GradientTexture1D | Color/alpha along trail length |
| `curve` | CurveTexture | Width curve along trail length |
| `vertical_texture` | bool | Rotate texture 90° |
| `use_red_as_alpha` | bool | Use red channel as alpha |
| `dewiggle` | bool | Improve texture mapping |
| `clip_overlaps` | bool | Clip overlapping segments (partial support) |
| `snap_to_transform` | bool | Snap trail start to node position |

## Technical Implementation

### Particle Process Shader (`trail_2d.gdshader`)

- Uses `shader_type particles` with `keep_data` render mode
- Stores 4 corner positions in TRANSFORM columns for connected quads
- Implements cyclic buffer for trail history
- Calculates width perpendicular to movement direction
- **Branchless optimization** using `step()` and `mix()` instead of `if` statements

### Draw Pass Shader (`trail_draw_pass_2d.gdshader`)

- Uses `shader_type canvas_item` with `skip_vertex_transform`
- Reads 4 corners from MODEL_MATRIX
- Interpolates quad geometry for smooth ribbon
- Applies width curve, color ramp, and textures
- **Branchless optimization** for all flag-based options

### GDScript (`GPUTrail2D.gd`)

- Extends `GPUParticles2D`
- Tracks movement direction with smoothing (lerp factor 0.3)
- Passes uniforms to shaders each frame
- **Strong typing** on all variables and function signatures per AI_RULES.md

## Code Optimizations

### Strong Typing
All variables and functions have explicit types:
```gdscript
var _flags: int = 0
var _prev_position: Vector2 = Vector2.ZERO
func _process(delta: float) -> void:
```

### Branchless Shaders
Replaced `if` statements with `step()` + `mix()`:
```glsl
// Before
if (CUSTOM.w >= 0.9 && CUSTOM.w <= 1.1) {
    TRANSFORM[0] = init_a;
}

// After
float is_head = step(0.9, CUSTOM.w) * step(CUSTOM.w, 1.1);
TRANSFORM[0] = mix(TRANSFORM[0], init_a, is_head);
```

## Known Limitations

- **Clip Overlaps**: Partially implemented - may cause gaps in some curves
- **Snap to Transform**: Needs additional work
- Sharp direction changes during slow movement can cause minor visual artifacts
