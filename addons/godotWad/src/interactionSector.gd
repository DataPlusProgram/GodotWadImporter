extends ItemList


func _ready():
	addText("test")


func _input(ev):
	if Input.is_key_pressed(KEY_K):
		visible = !visible

func _process(delta):
	if !visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#	pass


func addText(txt):
	add_item(String(get_item_count()))
	add_item(txt)
