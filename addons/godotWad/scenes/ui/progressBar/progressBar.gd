@tool
extends Window

var total = "0"

@onready var itemList : ItemList = $VBoxContainer/ItemList
@onready var countLabel = $VBoxContainer/Label2
@onready var timeLable = $VBoxContainer/HSplitContainer/Label2
func setProgress(value):
	$VBoxContainer/ProgressBar.value = value

func setTotal(value):
	if itemList == null:
		return
	total = str(value)
	
func setLoaded(value):
	if itemList == null:
		return
	countLabel.text = str(value) + "/" + total

func setArr(arr):
	
	if itemList == null:
		return
	
	itemList.clear()
	for i in arr:
		itemList.add_item(i)


func setTime(time):
	if itemList == null:
		return
	timeLable.text = str(time)

func _ready():
	popup_centered()
	grab_focus()


func _on_close_requested():
	hide()
