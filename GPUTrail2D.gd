@tool
@icon("bounce.svg")
class_name GPUTrail2D extends GPUParticles2D

## [br]A node for creating a ribbon trail effect in 2D.
## [br][color=purple]Ported from GPUTrail3D[/color]

# 2D Port NOTES:
# - Inherits GPUParticles2D
# - Uses "material" for the draw pass shader (trail_draw_pass_2d.gdshader)
# - Uses "process_material" for the particle process shader (trail_2d.gdshader)
# - No "draw_pass_1" mesh, uses standard particle quads deformed by shader.

# PUBLIC

# PRIVATE

const _DEFAULT_TEXTURE: String = "defaults/texture.tres"
const _DEFAULT_CURVE: String = "defaults/curve.tres"

## Length is the number of steps in the trail
@export var length: int = 100: set = _set_length
@export var length_seconds: float: set = _set_length

@export_category("Color / Texture")

@export var width: float = 20.0: set = _set_width
## The main texture of the trail.[br]
## [br]Set [member vertical_texture] to adjust for orientation[br]
##
## [br]Enable [member use_red_as_alpha] to use the red color channel as alpha
# We override the built-in texture property setter effectively by managing the shader uniform
@export var trail_texture: Texture: set = _set_texture
## Scolls the texture by applying an offset to the UV
@export var scroll: Vector2: set = _set_scroll
## A color ramp for modulating the color along the length of the trail
@export var color_ramp: GradientTexture1D: set = _set_color_ramp
## A curve for modulating the width along the length of the trail
@export var curve: CurveTexture: set = _set_curve
## Set [member vertical_texture] to adjust for orientation
@export var vertical_texture: bool = false: set = _set_vertical_texture
## Enable [member use_red_as_alpha] to use the red color channel of [member texture] as alpha
@export var use_red_as_alpha: bool = false: set = _set_use_red_as_alpha

@export_category("Mesh tweaks")

## Enable to improve the mapping of [member texture] to the trail
@export var dewiggle: bool = true: set = _set_dewiggle
## Enable to improve the mapping of [member texture] to the trail
@export var clip_overlaps: bool = true: set = _set_clip_overlaps
## Enable [member snap_to_transform] to snap the trail start to the nodes position. 
@export var snap_to_transform: bool = false: set = _set_snap_to_transform

var _defaults_have_been_set: bool = false
var _uv_offset: Vector2 = Vector2.ZERO
var _flags: int = 0
var _prev_position: Vector2 = Vector2.ZERO
var _smooth_direction: Vector2 = Vector2(1.0, 0.0)


func _ready() -> void:
	if not _defaults_have_been_set:
		_defaults_have_been_set = true

		amount = length
		lifetime = length
		explosiveness = 1.0 # emits all particles at once

		# the main fps is default
		var refresh_rate: float = DisplayServer.screen_get_refresh_rate(DisplayServer.MAIN_WINDOW_ID)
		fixed_fps = int(refresh_rate) if refresh_rate > 0.0 else 60

		# Process Material (Particle Physics/Logic)
		process_material = ShaderMaterial.new()
		process_material.shader = preload("shaders/trail_2d.gdshader")

		# Draw Material (CanvasItem Shader)
		material = ShaderMaterial.new()
		material.shader = preload("shaders/trail_draw_pass_2d.gdshader")

		# We need to ensure local_coords is false so particles stay in world space
		local_coords = false
		
		# Enable trail mode to connect particles as a ribbon
		trail_enabled = true
		trail_lifetime = 1.0

		if FileAccess.file_exists(_DEFAULT_TEXTURE):
			trail_texture = preload(_DEFAULT_TEXTURE).duplicate(true)

		if FileAccess.file_exists(_DEFAULT_CURVE):
			curve = preload(_DEFAULT_CURVE).duplicate(true)

		material.resource_local_to_scene = true
		process_material.resource_local_to_scene = true

	# Fix culling issues by setting a large bounding rect
	# Since trails move away from the node, the default rect at (0,0) is insufficient.
	visibility_rect = Rect2(Vector2(-10000.0, -10000.0), Vector2(20000.0, 20000.0))

	# Apply properties
	length = length
	vertical_texture = vertical_texture
	use_red_as_alpha = use_red_as_alpha
	dewiggle = dewiggle
	clip_overlaps = clip_overlaps
	snap_to_transform = snap_to_transform

	# Initial update
	_update_shader_params()

	# Ensure emitting is on
	emitting = true
	restart()


func _process(delta: float) -> void:
	# Update Canvas Transform for the shader
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		var canvas_trans: Transform2D = get_canvas_transform() * get_global_transform().affine_inverse()
		var canvas_proj: Projection = Projection(canvas_trans)
		mat.set_shader_parameter("canvas_transform", canvas_proj)

	# Emission Transform and Direction
	var proc_mat: ShaderMaterial = process_material as ShaderMaterial
	if proc_mat:
		# Calculate movement direction
		var move_dir: Vector2 = global_position - _prev_position
		_prev_position = global_position
		
		# Only update direction with significant movement
		var move_len: float = move_dir.length()
		if move_len > 0.5:
			var new_dir: Vector2 = move_dir / move_len # Normalized
			# Smooth the direction change
			_smooth_direction = _smooth_direction.lerp(new_dir, 0.3).normalized()
		
		# Pass smoothed direction as uniform
		proc_mat.set_shader_parameter("move_direction", _smooth_direction)
		
		# Pass position transform
		var global_proj: Projection = Projection(global_transform)
		proc_mat.set_shader_parameter("emission_transform", global_proj)

	if snap_to_transform and mat:
		var snap_proj: Projection = Projection(global_transform)
		mat.set_shader_parameter("emmission_transform", snap_proj)

	# Handle UV scrolling
	_uv_offset += scroll * delta
	_uv_offset = _uv_offset.posmod(1.0)
	if mat:
		mat.set_shader_parameter("uv_offset", _uv_offset)


func _get_property_list() -> Array[Dictionary]:
	return [ {"name": "_defaults_have_been_set", "type": TYPE_BOOL, "usage": PROPERTY_USAGE_NO_EDITOR}]


func _update_shader_params() -> void:
	var mat: ShaderMaterial = material as ShaderMaterial
	if not mat:
		return
	mat.set_shader_parameter("tex", trail_texture)
	mat.set_shader_parameter("color_ramp", color_ramp)
	mat.set_shader_parameter("curve", curve)
	mat.set_shader_parameter("flags", _flags)

	var proc_mat: ShaderMaterial = process_material as ShaderMaterial
	if proc_mat:
		proc_mat.set_shader_parameter("width", width)


func _set_width(value: float) -> void:
	width = value
	var proc_mat: ShaderMaterial = process_material as ShaderMaterial
	if proc_mat:
		proc_mat.set_shader_parameter("width", width)


func _set_length(value: Variant) -> void:
	var fps: int = get_fixed_fps()
	if fps == 0:
		fps = 60
	
	if value is int:
		length = maxi(value, 1)
		length_seconds = float(length) / float(fps)
	elif value is float:
		length = maxi(int(value * float(fps)), 1)
		length_seconds = float(length) / float(fps)

	if _defaults_have_been_set:
		amount = length
		lifetime = float(length)

	restart()


# Setters
func _set_texture(value: Texture) -> void:
	trail_texture = value
	texture = value
	_uv_offset = Vector2.ZERO
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("tex", trail_texture)


func _set_scroll(value: Vector2) -> void:
	scroll = value


func _set_color_ramp(value: GradientTexture1D) -> void:
	color_ramp = value
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("color_ramp", color_ramp)


func _set_curve(value: CurveTexture) -> void:
	curve = value
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("curve", curve)


func _set_vertical_texture(value: bool) -> void:
	vertical_texture = value
	_flags = _set_flag(_flags, 0, value)
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flags", _flags)


func _set_use_red_as_alpha(value: bool) -> void:
	use_red_as_alpha = value
	_flags = _set_flag(_flags, 1, value)
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flags", _flags)


func _set_dewiggle(value: bool) -> void:
	dewiggle = value
	_flags = _set_flag(_flags, 3, value)
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flags", _flags)


func _set_snap_to_transform(value: bool) -> void:
	snap_to_transform = value
	_flags = _set_flag(_flags, 4, value)
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flags", _flags)


func _set_clip_overlaps(value: bool) -> void:
	clip_overlaps = value
	_flags = _set_flag(_flags, 5, value)
	var mat: ShaderMaterial = material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("flags", _flags)


func _set_flag(i: int, idx: int, value: bool) -> int:
	return (i & ~(1 << idx)) | (int(value) << idx)
