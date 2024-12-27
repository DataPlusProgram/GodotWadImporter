@tool
extends SubViewport


func _physics_process(delta):
	size = get_parent().size - Vector2(10,10)
