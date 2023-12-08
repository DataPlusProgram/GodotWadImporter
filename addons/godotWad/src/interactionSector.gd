extends ItemList


func _ready():
	addText("test")


func _input(ev):
	if Input.is_key_pressed(KEY_K):
		visible = !visible




func addText(txt):
	add_item(String(get_item_count()))
	add_item(txt)
