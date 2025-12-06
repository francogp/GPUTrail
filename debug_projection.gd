@tool
extends EditorScript

func _run():
	var t = Transform2D(0.0, Vector2(100, 200)) # Pos (100, 200), Rot 0
	var p = Projection(t)
	print("Transform2D: ", t)
	print("Projection: ", p)
	print("Col 3 (Origin?): ", p.w) # Projection columns are x,y,z,w accessibl?
    # Projection is accessed by .x, .y, .z, .w which are Vector4 columns.
	print("Col 0: ", p.x)
	print("Col 1: ", p.y)
	print("Col 2: ", p.z)
	print("Col 3: ", p.w)
