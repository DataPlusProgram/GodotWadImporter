# Copyright (c) 2022-2024 Mansur Isaev and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
# Magic numbers, but otherwise the SpinBox does not work correctly.
const INT32_MIN = -2147483648
const INT32_MAX =  2147483647

## Handle [annotation @GDScript.@export_category] property.
class InspectorPropertyCategory extends InspectorProperty:
	var _container: VBoxContainer = null
	var _title: Label = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)
		self.set_theme_type_variation(&"InspectorPropertyCategory")

		_container = VBoxContainer.new()
		self.set_meta(&"property_container", _container)

		_title = Label.new()
		_title.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		_title.set_name("Title")
		_title.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		_title.set_text(get_property().capitalize())
		_container.add_child(_title, false, Node.INTERNAL_MODE_FRONT)

		self.add_child(_container)

	func _enter_tree() -> void:
		_title.add_theme_stylebox_override(&"normal", get_theme_stylebox(&"header"))

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["usage"] == PROPERTY_USAGE_CATEGORY

## Handle [annotation @GDScript.@export_group] property.
class InspectorPropertyGroup extends InspectorProperty:
	signal toggled(expanded: bool)

	var _container: VBoxContainer = null
	var _button: Button = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)
		self.set_theme_type_variation(&"InspectorPropertyGroup")

		var vbox := VBoxContainer.new()

		_container = VBoxContainer.new()
		_container.hide() # By default group is collapsed.
		vbox.add_child(_container)
		self.set_meta(&"property_container", _container)

		_button = Button.new()
		_button.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		_button.set_name("Button")
		_button.set_toggle_mode(true)
		_button.set_flat(true)
		_button.set_text_alignment(HORIZONTAL_ALIGNMENT_LEFT)
		_button.set_text(get_property().capitalize())
		_button.toggled.connect(_on_button_toggled)
		vbox.add_child(_button, false, Node.INTERNAL_MODE_FRONT)

		self.add_child(vbox)

	func _enter_tree() -> void:
		_button.set_button_icon(get_theme_icon(&"collapsed"))

	func _on_button_toggled(expanded: bool) -> void:
		_button.set_button_icon(get_theme_icon(&"expanded") if expanded else get_theme_icon(&"collapsed"))
		_container.set_visible(expanded)

		toggled.emit(expanded)

	func set_toggled(toggled: bool) -> void:
		_button.set_pressed(toggled)

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["usage"] == PROPERTY_USAGE_GROUP

## Handle [annotation @GDScript.@export_subgroup] property.
class InspectorPropertySubgroup extends InspectorPropertyGroup:
	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)
		self.set_theme_type_variation(&"InspectorPropertySubGroup")

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["usage"] == PROPERTY_USAGE_SUBGROUP

## Handle [bool] property.
class InspectorPropertyBool extends InspectorProperty:
	var check_box: CheckBox = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		check_box = create_bool_control(set_value, get_value, is_editable())
		create_flow_container(property["name"], check_box)

	static func _static_init() -> void:
		InspectorPropertyType.register_type(TYPE_BOOL, "bool", create_bool_control)

	static func create_bool_control(setter: Callable, getter: Callable, editable: bool) -> CheckBox:
		var check_box := CheckBox.new()
		check_box.set_disabled(not editable)
		check_box.set_text("On")
		check_box.set_pressed_no_signal(getter.call())

		check_box.toggled.connect(func(value: bool) -> void:
			setter.call(value)
			check_box.set_pressed_no_signal(getter.call())
		)

		return check_box

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["type"] == TYPE_BOOL

## Handle [int] or [float] property.
class InspectorPropertyNumber extends InspectorProperty:
	var spin_box: SpinBox = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		if property["type"] == TYPE_INT:
			spin_box = create_int_control(set_value, get_value, is_editable())
		else:
			spin_box = create_float_control(set_value, get_value, is_editable())

		if property["hint"] == PROPERTY_HINT_RANGE:
			var split: PackedStringArray = get_hint_string().split(',', false)

			spin_box.set_min(split[0].to_float() if split.size() >= 1 and split[0].is_valid_float() else INT32_MIN)
			spin_box.set_max(split[1].to_float() if split.size() >= 2 and split[1].is_valid_float() else INT32_MAX)
			spin_box.set_step(split[2].to_float() if split.size() >= 3 and split[2].is_valid_float() else 1.0 if property["type"] == TYPE_INT else 0.001)

		create_flow_container(property["name"], spin_box)

	static func _static_init() -> void:
		InspectorPropertyType.register_type(TYPE_INT, "int", create_int_control)
		InspectorPropertyType.register_type(TYPE_FLOAT, "float", create_float_control)

	static func create_int_control(setter: Callable, getter: Callable, editable: bool) -> SpinBox:
		var spin_box := SpinBox.new()
		spin_box.set_editable(editable)
		spin_box.set_min(INT32_MIN)
		spin_box.set_max(INT32_MAX)
		spin_box.set_step(1.0)
		spin_box.set_use_rounded_values(true)
		spin_box.set_value_no_signal(getter.call())

		spin_box.value_changed.connect(func(value: int) -> void:
			setter.call(value)
			spin_box.set_value_no_signal(getter.call())
		)

		return spin_box

	static func create_float_control(setter: Callable, getter: Callable, editable: bool) -> SpinBox:
		var spin_box := SpinBox.new()
		spin_box.set_editable(editable)
		spin_box.set_min(INT32_MIN)
		spin_box.set_max(INT32_MAX)
		spin_box.set_step(0.001)
		spin_box.set_value_no_signal(getter.call())

		spin_box.value_changed.connect(func(value: float) -> void:
			setter.call(value)
			spin_box.set_value_no_signal(getter.call())
		)

		return spin_box

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["type"] == TYPE_INT or property["type"] == TYPE_FLOAT

## Handle [String] or [StringName] property.
class InspectorPropertyString extends InspectorProperty:
	var line_edit: LineEdit = null
	var choose_file: Button = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		if property["type"] == TYPE_STRING:
			line_edit = create_string_control(set_value, get_value, editable)
		else:
			line_edit = create_string_name_control(set_value, get_value, editable)

		var hint: PropertyHint = property["hint"]
		if not is_hint_file_or_dir(hint):
			create_flow_container(property["name"], line_edit)
			return

		line_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)

		var hbox := HBoxContainer.new()
		hbox.add_child(line_edit)
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)

		var hint_string: String = property["hint_string"]

		setter = func(text: String) -> void:
			line_edit.set_text(set_and_return_value(text))

		choose_file = Button.new()
		choose_file.pressed.connect(func() -> void:
			var file_dialog := FileDialog.new()

			match hint:
				PROPERTY_HINT_FILE, PROPERTY_HINT_GLOBAL_FILE:
					file_dialog.set_access(FileDialog.ACCESS_RESOURCES if hint == PROPERTY_HINT_FILE else FileDialog.ACCESS_FILESYSTEM)
					file_dialog.set_current_path(get_value())
					file_dialog.set_file_mode(FileDialog.FILE_MODE_OPEN_FILE)
					file_dialog.file_selected.connect(setter)
				_:
					file_dialog.set_access(FileDialog.ACCESS_RESOURCES if hint == PROPERTY_HINT_DIR else FileDialog.ACCESS_FILESYSTEM)
					file_dialog.set_current_dir(get_value())
					file_dialog.set_file_mode(FileDialog.FILE_MODE_OPEN_DIR)
					file_dialog.dir_selected.connect(setter)

			file_dialog.add_filter(hint_string)
			# Free after hide.
			file_dialog.visibility_changed.connect(func() -> void:
				if not file_dialog.is_visible():
					file_dialog.queue_free()
			)
			self.add_child(file_dialog)

			file_dialog.popup_centered_ratio(0.5)
		)
		hbox.add_child(choose_file)
		create_flow_container(property["name"], hbox)

	func _enter_tree() -> void:
		if is_instance_valid(choose_file):
			choose_file.set_button_icon(get_theme_icon(&"file", &"Inspector"))

	static func _static_init() -> void:
		InspectorPropertyType.register_type(TYPE_STRING, "String", create_string_control)
		InspectorPropertyType.register_type(TYPE_STRING_NAME, "StringName", create_string_name_control)

	static func _create_line_edit(setter: Callable, getter: Callable, editable: bool, string_name: bool) -> LineEdit:
		var line_edit := LineEdit.new()
		line_edit.set_editable(editable)
		line_edit.set_text(getter.call())

		if string_name:
			line_edit.set_placeholder("StringName")
			line_edit.text_changed.connect(func(value: StringName) -> void:
				var caret: int = line_edit.get_caret_column()

				setter.call(value)
				line_edit.set_text(getter.call())
				line_edit.set_caret_column(caret)
			)
		else:
			line_edit.text_changed.connect(func(value: String) -> void:
				var caret: int = line_edit.get_caret_column()

				setter.call(value)
				line_edit.set_text(getter.call())
				line_edit.set_caret_column(caret)
			)

		return line_edit

	static func create_string_control(setter: Callable, getter: Callable, editable: bool) -> LineEdit:
		return _create_line_edit(setter, getter, editable, false)

	static func create_string_name_control(setter: Callable, getter: Callable, editable: bool) -> LineEdit:
		return _create_line_edit(setter, getter, editable, true)

	static func is_hint_file_or_dir(hint: PropertyHint) -> bool:
		return hint == PROPERTY_HINT_FILE or hint == PROPERTY_HINT_DIR or\
			hint == PROPERTY_HINT_GLOBAL_FILE or hint == PROPERTY_HINT_GLOBAL_DIR

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["type"] == TYPE_STRING or property["type"] == TYPE_STRING_NAME

## Handle [String] or [StringName] property with [param @export_multiline] annotation.
class InspectorPropertyMultiline extends InspectorProperty:
	var text_edit: TextEdit = null
	var maximize: Button = null

	var window: AcceptDialog = null
	var window_text_edit: TextEdit = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		var container := VBoxContainer.new()
		container.set_name("Container")

		var label := Label.new()
		label.set_name("Label")
		label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
		label.set_text(property["name"].capitalize())
		label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		label.set_stretch_ratio(0.75)
		container.add_child(label)

		var hbox := HBoxContainer.new()
		hbox.set_name("Property")
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		hbox.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		container.add_child(hbox)

		text_edit = TextEdit.new()
		text_edit.set_editable(editable)
		text_edit.set_name("TextEdit")
		text_edit.set_text(get_value())
		text_edit.set_tooltip_text(text_edit.get_text())
		text_edit.set_line_wrapping_mode(TextEdit.LINE_WRAPPING_BOUNDARY)
		text_edit.set_custom_minimum_size(Vector2(0.0, 96.0))
		text_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		text_edit.set_v_size_flags(Control.SIZE_EXPAND_FILL)
		text_edit.text_changed.connect(_on_text_edit_text_changed)
		hbox.add_child(text_edit)

		maximize = Button.new()
		maximize.set_name("Maximize")
		maximize.set_flat(true)
		maximize.set_v_size_flags(Control.SIZE_SHRINK_CENTER)
		maximize.pressed.connect(_on_maximize_pressed)
		hbox.add_child(maximize)

		self.add_child(container)

	func _enter_tree() -> void:
		maximize.set_button_icon(get_theme_icon(&"maximize", &"Inspector"))

	func _on_text_edit_text_changed() -> void:
		var column: int = text_edit.get_caret_column()
		var line: int = text_edit.get_caret_line()

		text_edit.set_text(set_and_return_value(text_edit.get_text()))
		text_edit.set_caret_column(column)
		text_edit.set_caret_line(line)

	func _on_window_confirmed() -> void:
		var column: int = window_text_edit.get_caret_column()
		var line: int = window_text_edit.get_caret_line()

		window_text_edit.set_text(set_and_return_value(window_text_edit.get_text()))
		window_text_edit.set_caret_column(column)
		window_text_edit.set_caret_line(line)
		text_edit.set_text(window_text_edit.get_text())

	func _on_maximize_pressed() -> void:
		if not is_instance_valid(window):
			window = AcceptDialog.new()
			window.set_name("EditTextDialog")
			window.set_title("Text edit")
			window.set_min_size(Vector2(640, 480))
			window.add_cancel_button("Cancel")
			window.set_ok_button_text("Save")
			window.confirmed.connect(_on_window_confirmed)

			window_text_edit = TextEdit.new()
			window_text_edit.set_editable(is_editable())
			window_text_edit.set_name("TextEdit")
			window_text_edit.set_text(get_value())
			window.add_child(window_text_edit)

			self.add_child(window)

		window_text_edit.set_text(get_value())
		window.popup_centered_clamped(Vector2(640, 480))

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["hint"] == PROPERTY_HINT_MULTILINE_TEXT and (property["type"] == TYPE_STRING or property["type"] == TYPE_STRING_NAME)

## Handle [Vector2] or [Vector2i] property.
class InspectorPropertyVector2 extends InspectorProperty:
	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		var box: BoxContainer = null
		if property["type"] == TYPE_VECTOR2:
			box = create_vector2_control(set_value, get_value, editable)
		else:
			box = create_vector2i_control(set_value, get_value, editable)

		box.set_h_size_flags(Control.SIZE_EXPAND_FILL)

		var label: Label = create_flow_container(property["name"], box).get_node(^"Label")
		label.set_v_size_flags(Control.SIZE_SHRINK_BEGIN)

	static func _static_init() -> void:
		InspectorPropertyType.register_type(TYPE_VECTOR2, "Vector2", create_vector2_control)
		InspectorPropertyType.register_type(TYPE_VECTOR2I, "Vector2i", create_vector2i_control)

	static func _create_vector2_control(setter: Callable, getter: Callable, editable: bool, is_vector2i: bool) -> BoxContainer:
		var box := BoxContainer.new()
		box.set_h_size_flags(Control.SIZE_EXPAND_FILL)

		var value: Vector2 = getter.call()

		var x_spin := SpinBox.new()
		x_spin.set_editable(editable)
		x_spin.set_name("X")
		x_spin.set_prefix("x")
		x_spin.set_min(INT32_MIN)
		x_spin.set_max(INT32_MAX)
		x_spin.set_step(1.0 if is_vector2i else 0.001)
		x_spin.set_use_rounded_values(is_vector2i)
		x_spin.set_value_no_signal(value.x)
		x_spin.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		box.add_child(x_spin)

		var y_spin: SpinBox = x_spin.duplicate()
		y_spin.set_name("Y")
		y_spin.set_prefix("y")
		y_spin.set_value_no_signal(value.y)
		box.add_child(y_spin)

		var value_changed: Callable
		if is_vector2i:
			value_changed = func(_value) -> void:
				setter.call(Vector2i(x_spin.get_value(), y_spin.get_value()))
				var vector2i: Vector2i = getter.call()

				x_spin.set_value_no_signal(vector2i.x)
				y_spin.set_value_no_signal(vector2i.y)
		else:
			value_changed = func(_value) -> void:
				setter.call(Vector2(x_spin.get_value(), y_spin.get_value()))
				value = getter.call()

				x_spin.set_value_no_signal(value.x)
				y_spin.set_value_no_signal(value.y)

		x_spin.value_changed.connect(value_changed)
		y_spin.value_changed.connect(value_changed)

		return box

	static func create_vector2_control(setter: Callable, getter: Callable, editable: bool) -> BoxContainer:
		return _create_vector2_control(setter, getter, editable, false)

	static func create_vector2i_control(setter: Callable, getter: Callable, editable: bool) -> BoxContainer:
		return _create_vector2_control(setter, getter, editable, true)

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["type"] == TYPE_VECTOR2 or property["type"] == TYPE_VECTOR2I

## Handle [Vector3] or [Vector3i] property.
class InspectorPropertyVector3 extends InspectorProperty:
	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		var box: BoxContainer = null
		if property["type"] == TYPE_VECTOR3I:
			box = create_vector3i_control(set_value, get_value, editable)
		else:
			box = create_vector3_control(set_value, get_value, editable)

		create_flow_container(property["name"], box).add_to_group(&"vertical")

	static func _static_init() -> void:
		InspectorPropertyType.register_type(TYPE_VECTOR3, "Vector3", create_vector3_control)
		InspectorPropertyType.register_type(TYPE_VECTOR3I, "Vector3i", create_vector3i_control)

	static func _create_vector3_control(setter: Callable, getter: Callable, editable: bool, is_vector3i: bool) -> BoxContainer:
		var box := BoxContainer.new()
		box.add_to_group(&"vertical")

		var value: Vector3 = getter.call()

		var x_spin := SpinBox.new()
		x_spin.set_editable(editable)
		x_spin.set_name("X")
		x_spin.set_prefix("x")
		x_spin.set_min(INT32_MIN)
		x_spin.set_max(INT32_MAX)
		x_spin.set_step(1.0 if is_vector3i else 0.001)
		x_spin.set_use_rounded_values(is_vector3i)
		x_spin.set_value_no_signal(value.x)
		x_spin.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		box.add_child(x_spin)

		var y_spin: SpinBox = x_spin.duplicate()
		y_spin.set_name("Y")
		y_spin.set_prefix("y")
		y_spin.set_value_no_signal(value.y)
		box.add_child(y_spin)

		var z_spin: SpinBox = x_spin.duplicate()
		z_spin.set_name("Z")
		z_spin.set_prefix("z")
		z_spin.set_value_no_signal(value.z)
		box.add_child(z_spin)

		var on_value_changed: Callable
		if is_vector3i:
			on_value_changed = func(_value) -> void:
				setter.call(Vector3i(x_spin.get_value(), y_spin.get_value(), z_spin.get_value()))
				var vector3i: Vector3i = getter.call()

				x_spin.set_value_no_signal(vector3i.x)
				y_spin.set_value_no_signal(vector3i.y)
				z_spin.set_value_no_signal(vector3i.z)
		else:
			on_value_changed = func(_value) -> void:
				setter.call(Vector3(x_spin.get_value(), y_spin.get_value(), z_spin.get_value()))
				value = getter.call()

				x_spin.set_value_no_signal(value.x)
				y_spin.set_value_no_signal(value.y)
				z_spin.set_value_no_signal(value.z)

		x_spin.value_changed.connect(on_value_changed)
		y_spin.value_changed.connect(on_value_changed)
		z_spin.value_changed.connect(on_value_changed)

		return box

	static func create_vector3_control(setter: Callable, getter: Callable, editable: bool) -> BoxContainer:
		return _create_vector3_control(setter, getter, editable, false)

	static func create_vector3i_control(setter: Callable, getter: Callable, editable: bool) -> BoxContainer:
		return _create_vector3_control(setter, getter, editable, true)

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["type"] == TYPE_VECTOR3 or property["type"] == TYPE_VECTOR3I

## Handle [Color] property.
class InspectorPropertyColor extends InspectorProperty:
	var color_picker: ColorPickerButton = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		color_picker = create_color_control(set_value, get_value, editable)
		color_picker.set_edit_alpha(get_hint() == PROPERTY_HINT_COLOR_NO_ALPHA)

		create_flow_container(property["name"], color_picker)

	static func _static_init() -> void:
		InspectorPropertyType.register_type(TYPE_COLOR, "Color", create_color_control)

	static func create_color_control(setter: Callable, getter: Callable, editable: bool) -> ColorPickerButton:
		var color_picker := ColorPickerButton.new()
		color_picker.set_disabled(not editable)
		color_picker.set_pick_color(getter.call())

		color_picker.color_changed.connect(func(value: Color) -> void:
			setter.call(value)
			color_picker.set_pick_color(getter.call())
		)

		var picker: ColorPicker = color_picker.get_picker()
		picker.set_presets_visible(false)

		return color_picker

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["type"] == TYPE_COLOR

## Handle [param enum] property.
class InspectorPropertyEnum extends InspectorProperty:
	var option_button: OptionButton = null

	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		option_button = OptionButton.new()
		option_button.set_disabled(not editable)
		option_button.set_clip_text(true)

		var hint_split: PackedStringArray = String(property["hint_string"]).split(",", false)

		for i: int in hint_split.size():
			var split := hint_split[i].split(":", false)

			# If key-value pair.
			if split.size() > 1 and split[1].is_valid_int():
				option_button.add_item(split[0], split[1].to_int())
			else:
				option_button.add_item(split[0], i)

		option_button.select(option_button.get_item_index(get_value()))
		option_button.get_popup().id_pressed.connect(_on_id_pressed)

		create_flow_container(property["name"], option_button)

	func _on_id_pressed(id: int) -> void:
		option_button.select(option_button.get_item_index(set_and_return_value(id)))

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["hint"] == PROPERTY_HINT_ENUM and property["type"] == TYPE_INT

## Handle [int] property with [param @export_flags] annotation.
class InspectorPropertyFlags extends InspectorProperty:
	func _init(object: Object, property: Dictionary, editable: bool, setter: Callable, getter: Callable) -> void:
		super(object, property, editable, setter, getter)

		var vbox := VBoxContainer.new()
		var value: int = get_value()

		var split : PackedStringArray = String(property["hint_string"]).split(",", false)
		for i in split.size():
			var check_box := CheckBox.new()
			check_box.set_disabled(not editable)
			check_box.set_text(split[i])
			check_box.set_pressed(value & (1 << i))

			check_box.toggled.connect(func(pressed: bool) -> void:
				if pressed:
					set_value(get_value() | (1 << i))
				else:
					set_value(get_value() & ~(1 << i))

				check_box.set_pressed(get_value() & 1 << i)
			)

			vbox.add_child(check_box)

		var label: Label = create_flow_container(property["name"], vbox).get_node(^"Label")
		label.set_v_size_flags(Control.SIZE_SHRINK_BEGIN)

	static func can_handle(_object: Object, property: Dictionary, _editable: bool) -> bool:
		return property["hint"] == PROPERTY_HINT_FLAGS and property["type"] == TYPE_INT


static func _static_init() -> void:
	InspectorProperty.declare_property(InspectorPropertyCategory.can_handle, InspectorPropertyCategory.new)
	InspectorProperty.declare_property(InspectorPropertyGroup.can_handle, InspectorPropertyGroup.new)
	InspectorProperty.declare_property(InspectorPropertySubgroup.can_handle, InspectorPropertySubgroup.new)
	InspectorProperty.declare_property(InspectorPropertyBool.can_handle, InspectorPropertyBool.new)
	InspectorProperty.declare_property(InspectorPropertyNumber.can_handle, InspectorPropertyNumber.new)
	InspectorProperty.declare_property(InspectorPropertyString.can_handle, InspectorPropertyString.new)
	InspectorProperty.declare_property(InspectorPropertyMultiline.can_handle, InspectorPropertyMultiline.new)
	InspectorProperty.declare_property(InspectorPropertyVector2.can_handle, InspectorPropertyVector2.new)
	InspectorProperty.declare_property(InspectorPropertyVector3.can_handle, InspectorPropertyVector3.new)
	InspectorProperty.declare_property(InspectorPropertyColor.can_handle, InspectorPropertyColor.new)
	InspectorProperty.declare_property(InspectorPropertyEnum.can_handle, InspectorPropertyEnum.new)
	InspectorProperty.declare_property(InspectorPropertyFlags.can_handle, InspectorPropertyFlags.new)
