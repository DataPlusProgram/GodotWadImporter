tool
extends Viewport


func _physics_process(delta):
	size = get_parent().rect_size - Vector2(10,10)
