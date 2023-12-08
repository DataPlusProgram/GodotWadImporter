tool
extends WindowDialog

var total = "0"

func setProgress(value):
	$VBoxContainer/ProgressBar.value = value

func setTotal(value):
	total = String(value)
	
func setLoaded(value):
	$VBoxContainer/TextEdit.text = String(value) + "/" + total

func setArr(arr):
	var string = ""

	for i in arr:
		string += String(i) + "\n"

	$VBoxContainer/ItemList.text = string

func setTime(time):
	$VBoxContainer/HSplitContainer/Label2.text = String(time)
