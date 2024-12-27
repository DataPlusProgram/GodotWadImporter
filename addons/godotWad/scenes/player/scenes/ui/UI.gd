extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	
	if event.type is InputEventKey:
		if event.keycode == KEY_W && event.button_pressed == false:
			visible = !visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pass
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass
