tool
extends Camera2D



func _process(delta):
	var vp = $"../..".rect_size
	zoom =   Vector2(1.0,1.0) / (vp /$"../Label".rect_size)
	
#	pass
