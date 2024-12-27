# Copyright (c) 2022-2024 Mansur Isaev and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
class_name InspectorPropertyPaginator
extends VBoxContainer


const PAGE_SIZE: int = 20


var _hseparator: HSeparator = null
var _footer: HBoxContainer = null

var _page_first: Button = null
var _page_prev: Button = null

var _page_edit: LineEdit = null
var _page_label: Label = null

var _page_next: Button = null
var _page_last: Button = null


var _element_count: int = -1

var _current_page: int = 0
var _page_count: int = 0

var _element_constructor: Callable


func _init(element_constructor: Callable) -> void:
	self.set_theme_type_variation(&"InspectorPropertyPaginator")

	_element_constructor = element_constructor

	_footer = HBoxContainer.new()
	_footer.set_name("Footer")
	_footer.set_h_size_flags(Control.SIZE_SHRINK_CENTER)
	_footer.hide()

	_page_first = Button.new()
	_page_first.set_name("PageFirst")
	_page_first.set_flat(true)
	_page_first.set_disabled(true)
	_page_first.pressed.connect(_on_page_first_pressed)
	_footer.add_child(_page_first)

	_page_prev = Button.new()
	_page_prev.set_name("PagePrev")
	_page_prev.set_flat(true)
	_page_prev.set_disabled(true)
	_page_prev.pressed.connect(_on_page_prev_pressed)
	_footer.add_child(_page_prev)

	_page_edit = LineEdit.new()
	_page_edit.set_text("0")
	_page_edit.text_submitted.connect(_on_page_edit_text_submitted)
	_footer.add_child(_page_edit)

	_page_label = Label.new()
	_page_label.set_name("PageCount")
	_page_label.set_text("/ 42")
	_footer.add_child(_page_label)

	_page_next = Button.new()
	_page_next.set_name("PageNext")
	_page_next.set_flat(true)
	_page_next.pressed.connect(_on_page_next_pressed)
	_footer.add_child(_page_next)

	_page_last = Button.new()
	_page_last.set_name("PageLast")
	_page_last.set_flat(true)
	_page_last.pressed.connect(_on_page_last_pressed)
	_footer.add_child(_page_last)

	_hseparator = HSeparator.new()
	_hseparator.hide()
	self.add_child(_hseparator, false, Node.INTERNAL_MODE_BACK)

	self.add_child(_footer, false, Node.INTERNAL_MODE_BACK)


func _enter_tree() -> void:
	_page_first.set_button_icon(get_theme_icon(&"page_first"))
	_page_prev.set_button_icon(get_theme_icon(&"page_prev"))
	_page_next.set_button_icon(get_theme_icon(&"page_next"))
	_page_last.set_button_icon(get_theme_icon(&"page_last"))


func set_element_count(element_count: int) -> void:
	element_count = maxi(element_count, 0)
	if _element_count == element_count:
		return

	_hseparator.set_visible(element_count > PAGE_SIZE)
	_footer.set_visible(_hseparator.is_visible())

	_page_count = float(element_count - 1) / PAGE_SIZE
	_page_label.set_text("/ %d" % _page_count)

	_current_page = clampi(_current_page, 0, _page_count)
	_page_edit.set_text(str(_current_page))

	_element_count = element_count

	update_elements()

func get_element_count() -> int:
	return _element_count


func get_page_count() -> int:
	return _page_count


func create_element(index: int) -> Control:
	return _element_constructor.call(index)


func update_elements() -> void:
	for i: int in get_child_count():
		var child: Node = get_child(i)
		if child is Control:
			child.queue_free()

	var begin: int = _current_page * PAGE_SIZE
	var end: int = mini(begin + PAGE_SIZE, _element_count)

	while begin < end:
		var control: Control = create_element(begin)
		if is_instance_valid(control):
			add_child(control)

		begin += 1


func set_current_page(page: int) -> void:
	page = clampi(page, 0, get_page_count())
	if _current_page == page:
		return

	_page_first.set_disabled(page == 0)
	_page_prev.set_disabled(_page_first.is_disabled())
	_page_next.set_disabled(page == get_page_count())
	_page_last.set_disabled(_page_next.is_disabled())

	_current_page = page
	_page_edit.set_text(str(page))

	update_elements()

func get_current_page() -> int:
	return _current_page


func _on_page_first_pressed() -> void:
	set_current_page(0)


func _on_page_prev_pressed() -> void:
	set_current_page(get_current_page() - 1)


func _on_page_edit_text_submitted(text: String) -> void:
	if not text.is_valid_int():
		return

	set_current_page(text.to_int())


func _on_page_next_pressed() -> void:
	set_current_page(get_current_page() + 1)


func _on_page_last_pressed() -> void:
	set_current_page(get_page_count())
