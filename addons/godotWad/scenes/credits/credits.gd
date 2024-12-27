extends Control


@export var values : PackedStringArray = ["test"]

func _ready() -> void:
	
	if get_parent() is Window:
		get_parent().close_requested.connect(_on_credits_window_close_requested)
	
	for i in values:
		$RichList.add_item(i)

func _process(delta: float) -> void:
	if get_parent() is Window:
		size = get_parent().size


func _on_credits_window_close_requested() -> void:
	get_parent().visible = false
	
