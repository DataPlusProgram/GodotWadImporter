# Copyright (c) 2022-2024 Mansur Isaev and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
## [InspectorProperty] class for [Array].
class_name InspectorPropertyArray
extends InspectorProperty


const InspectorProperties = preload("res://addons/object-inspector/scripts/inspector_properties.gd")
const Paginator = preload("res://addons/object-inspector/scripts/inspector_property_paginator.gd")

const INT32_MIN: int = InspectorProperties.INT32_MIN
const INT32_MAX: int = InspectorProperties.INT32_MAX


var _container: VBoxContainer = null
var _array_control: InspectorPropertyTypeArray = null


func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
	super(object, property, editable, setter, getter)
	self.set_theme_type_variation(&"InspectorPropertyArray")

	_container = VBoxContainer.new()
	_container.set_name("Container")

	var header := HBoxContainer.new()
	header.set_name("Header")
	_container.add_child(header)

	var label := Label.new()
	label.set_name("Label")
	label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	label.set_text(String(property["name"]).capitalize())
	label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
	label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	label.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	label.set_stretch_ratio(0.75)
	header.add_child(label)

	_array_control = create_array_control(set_value, get_value, editable)
	_array_control.set_name("Property")
	_array_control.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_array_control.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	header.add_child(_array_control)

	self.add_child(_container)


static func is_valid_type(type: Variant.Type) -> bool:
	return InspectorPropertyType.is_valid_type(type)

static func can_handle(object: Object, property: Dictionary, _editable: bool) -> bool:
	if property["type"] == TYPE_ARRAY:
		var array: Array = object.get(property["name"])
		var array_type := array.get_typed_builtin()

		return array_type == TYPE_NIL or is_valid_type(array_type)

	const TYPE_PACKED_ARRAY: PackedByteArray = [
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_PACKED_COLOR_ARRAY,
	]

	return TYPE_PACKED_ARRAY.has(property["type"])


static func _static_init() -> void:
	InspectorProperty.declare_property(InspectorPropertyArray.can_handle, InspectorPropertyArray.new)
	InspectorPropertyType.register_type(TYPE_ARRAY, "Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_BYTE_ARRAY, "PackedByteArray", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_FLOAT32_ARRAY, "PackedFloat32Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_FLOAT64_ARRAY, "PackedFloat64Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_INT32_ARRAY, "PackedInt32Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_INT64_ARRAY, "PackedInt64Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_STRING_ARRAY, "PackedStringArray", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_VECTOR2_ARRAY, "PackedVector2Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_VECTOR3_ARRAY, "PackedVector3Array", create_array_control)
	InspectorPropertyType.register_type(TYPE_PACKED_COLOR_ARRAY, "PackedColorArray", create_array_control)


class InspectorPropertyTypeArray extends Button:
	var _array: Variant = null
	var _array_type: Variant.Type = TYPE_NIL

	var _editable: bool = false

	var _panel: PanelContainer = null
	var _vbox: VBoxContainer = null

	var _hseparator: HSeparator = null
	var _size_spin: SpinBox = null
	var _paginator: Paginator = null

	func _init(array: Variant, editable: bool) -> void:
		self.set_theme_type_variation(&"InspectorPropertyArray")

		_array = array
		_array_type = get_array_type(array)

		_editable = editable

		self.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		self.set_text(array_to_string(array))
		self.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		self.set_toggle_mode(true)
		self.toggled.connect(_on_button_pressed)
		self.tree_exiting.connect(func() -> void:
			if is_instance_valid(_panel):
				_panel.queue_free()
		)

	func update_paginator() -> void:
		_size_spin.set_value_no_signal(_array.size())

		_paginator.set_element_count(_array.size())
		_paginator.update_elements()

	func set_array_size(new_size: int) -> void:
		if _array.size() == new_size:
			return

		var error: Error = _array.resize(new_size)
		assert(error == OK, error_string(error))

		self.set_text(array_to_string(_array))

		_hseparator.set_visible(new_size)
		_paginator.set_element_count(new_size)

	func set_value(index: int, value: Variant) -> void:
		if is_same(_array[index], value):
			return

		_array[index] = value
		_paginator.update_elements()

	func remove_value(index: int) -> void:
		if index < 0 or index > _array.size():
			return

		self.set_text(array_to_string(_array))

		_array.remove_at(index)
		_hseparator.set_visible(_array.size())

		update_paginator()

	func create_label(index: int) -> Label:
		var label := Label.new()
		label.set_name("Label")
		label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
		label.set_text(str(index))
		label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_stretch_ratio(0.75)

		return label

	func create_delete_button(index: int) -> Button:
		var delete := Button.new()
		delete.set_name("Delete")
		delete.set_button_icon(get_theme_icon(&"delete"))
		delete.pressed.connect(remove_value.bind(index))

		return delete

	func create_edit_button(index: int) -> MenuButton:
		const DELETE = -2

		var edit := MenuButton.new()
		edit.set_flat(false)
		edit.set_name("Edit")
		edit.set_button_icon(get_theme_icon(&"edit"))

		var popup: PopupMenu = edit.get_popup()

		for type: Dictionary in InspectorPropertyType.get_type_list():
			popup.add_item(type["name"], type["type"])

		popup.add_separator()
		popup.add_item("Delete", DELETE)
		popup.set_item_icon(-1, get_theme_icon(&"delete"))

		popup.id_pressed.connect(func(type: int) -> void:
			if type == DELETE:
				return remove_value(index)

			var value: Variant = type_convert(null, type)
			set_value(index, value)
		)

		return edit

	func create_element(index: int) -> Control:
		var value: Variant = _array[index]
		var value_type: Variant.Type = _array_type

		if value_type == TYPE_NIL:
			value_type = typeof(value)

		var setter: Callable = func(new_value: Variant) -> void:
			_array[index] = new_value
		var getter: Callable = func() -> Variant:
			return _array[index]

		var control: Control = create_control(value_type, setter, getter, _editable)
		if not is_instance_valid(control):
			return null

		control.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		control.set_v_size_flags(Control.SIZE_EXPAND_FILL)

		var hbox := HBoxContainer.new()

		var container := VBoxContainer.new()
		container.set_name("Container")
		container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		hbox.add_child(container)

		var header := BoxContainer.new()
		header.add_child(create_label(index))
		header.add_child(control)
		header.set_vertical(control.is_in_group(&"vertical"))
		container.add_child(header)

		if _array_type:
			hbox.add_child(create_delete_button(index))
		else:
			hbox.add_child(create_edit_button(index))

		return hbox

	func _on_button_pressed(expanded: bool) -> void:
		if not expanded:
			if is_instance_valid(_panel):
				_panel.queue_free()

			return

		_panel = PanelContainer.new()
		_panel.set_theme_type_variation(&"InspectorSubProperty")

		_vbox = VBoxContainer.new()
		_panel.add_child(_vbox)

		var hbox := HBoxContainer.new()
		hbox.set_name("SizeContainer")
		_vbox.add_child(hbox, false, Node.INTERNAL_MODE_FRONT)

		var label := Label.new()
		label.set_name("SizeLabel")
		label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
		label.set_text("Size:")
		label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_stretch_ratio(0.75)
		hbox.add_child(label)

		_size_spin = SpinBox.new()
		_size_spin.set_name("SizeSpinBox")
		_size_spin.set_min(0)
		_size_spin.set_max(INT32_MAX)
		_size_spin.set_step(1)
		_size_spin.set_use_rounded_values(true)
		_size_spin.set_value_no_signal(_array.size())
		_size_spin.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		_size_spin.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		_size_spin.value_changed.connect(set_array_size)
		hbox.add_child(_size_spin)

		_hseparator = HSeparator.new()
		_hseparator.set_visible(_array.size())
		_vbox.add_child(_hseparator)

		_paginator = Paginator.new(create_element)
		_paginator.set_name("Paginator")
		_vbox.add_child(_paginator)

		update_paginator()
		find_parent("Container").add_child(_panel)

	static func array_to_string(array: Variant) -> String:
		var array_name: String = " (size %d)" % array.size()

		if array is Array and array.is_typed():
			array_name = type_string(typeof(array)) + "[%s]" % type_string(array.get_typed_builtin()) + array_name
		else:
			array_name = type_string(typeof(array)) + array_name

		return array_name

	static func get_array_type(array: Variant) -> Variant.Type:
		if array is Array:
			return array.get_typed_builtin()

		match typeof(array):
			TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
				return TYPE_INT
			TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
				return TYPE_FLOAT
			TYPE_PACKED_STRING_ARRAY:
				return TYPE_STRING
			TYPE_PACKED_VECTOR2_ARRAY:
				return TYPE_VECTOR2
			TYPE_PACKED_VECTOR3_ARRAY:
				return TYPE_VECTOR3
			TYPE_PACKED_COLOR_ARRAY:
				return TYPE_COLOR

		return TYPE_NIL

	static func create_control(type: Variant.Type, setter: Callable, getter: Callable, editable: bool) -> Control:
		if type == TYPE_NIL:
			var label := Label.new()
			label.set_text(str(null))

			return label

		return InspectorPropertyType.create_control(type, setter, getter, editable)


static func create_array_control(_setter: Callable, getter: Callable, editable: bool) -> InspectorPropertyTypeArray:
	var array: Variant = getter.call()
	var array_control := InspectorPropertyTypeArray.new(array, editable)

	return array_control
