extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(ev):
	if Input.is_key_pressed(KEY_K):
		print("i")
		visible = !visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#	pass
