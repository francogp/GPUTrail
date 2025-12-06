extends Node2D

var time = 0.0

@onready var trail = $GPUTrail2D


func _process(delta):
	time += delta
	var r = 200.0
	var center = get_viewport_rect().size / 2.0
	# Lissajous curve movement
	trail.position = center + Vector2(cos(time * 3.0) * r, sin(time * 2.0) * r)
