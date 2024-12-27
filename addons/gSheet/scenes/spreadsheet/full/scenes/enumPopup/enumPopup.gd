@tool
extends Window
signal selectedItem 

var item
var dict
var dictNames
var forCol


func _on_Button2_pressed():
	visible = false
	pass # Replace with function body.


func _on_ItemList_item_selected(index):
	$VBoxContainer/HBoxContainer/select.disabled = false
	item = index
	pass # Replace with function body.


func _on_ItemList_nothing_selected():
	$VBoxContainer/HBoxContainer/select.disabled = true
	pass # Replace with function body.


func _on_select_pressed():
	var ret = $VBoxContainer/ItemList.get_item_text(item)
	visible = false
	emit_signal("selectedItem",dict[ret],forCol,dictNames[item])


func _on_ItemList_item_activated(index):
	_on_select_pressed()
