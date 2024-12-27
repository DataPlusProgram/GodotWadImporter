# Copyright (c) 2022-2024 Mansur Isaev and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.

@tool
## A custom control used to edit properties of an object.
class_name Inspector
extends VBoxContainer

## Emitted when object changed.
signal object_changed(object: Object)

@export var show_internal : bool = false
@export
var _readonly := false:
	set = set_readonly,
	get = is_readonly

@export
var _search_enabled := true:
	set = set_search_enabled,
	get = is_search_enabled

@export
var _category_enadled: bool = true:
	set = set_category_enabled,
	get = is_category_enabled

@export
var _group_enabled: bool = true:
	set = set_group_enabled,
	get = is_group_enabled

@export
var _subgroup_enabled: bool = true:
	set = set_subgroup_enabled,
	get = is_subgroup_enabled

var _object : Object = null
var _valid_properties: Array[Dictionary] = []

var _search : LineEdit = null

var _scroll_container : ScrollContainer = null
var _container : VBoxContainer = null

var _group_states: Dictionary = {}
var _subgroup_states: Dictionary = {}


func _init() -> void:
	self.set_theme_type_variation(&"Inspector")

	# INFO: Required for static initialization.
	load("res://addons/object-inspector/scripts/inspector_property_array.gd")
	load("res://addons/object-inspector/scripts/inspector_property_dictionary.gd")

	_search = LineEdit.new()
	_search.set_placeholder("Filter Properties")
	_search.set_editable(false)
	_search.set_clear_button_enabled(true)
	_search.set_visible(is_search_enabled())
	_search.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_search.text_changed.connect(_on_filter_text_chnaged)
	self.add_child(_search)

	_scroll_container = ScrollContainer.new()
	_scroll_container.set_horizontal_scroll_mode(ScrollContainer.SCROLL_MODE_DISABLED)
	_scroll_container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_scroll_container.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	self.add_child(_scroll_container)


func _enter_tree() -> void:
	_search.set_right_icon(get_theme_icon(&"search"))

## Set Inspector readonly.
func set_readonly(value: bool) -> void:
	if _readonly != value:
		_readonly = value
		self.update_inspector()

## Return [param true] if Inspector is readonly.
func is_readonly() -> bool:
	return _readonly

## Set search line visible.
func set_search_enabled(value: bool) -> void:
	_search_enabled = value
	_search.set_visible(value)

## Return [param true] if search line is enabled.
func is_search_enabled() -> bool:
	return _search_enabled

## Set edited object.
func set_object(object: Object) -> void:
	if is_same(_object, object):
		return

	if is_instance_valid(_object) and _object.property_list_changed.is_connected(_update_property_list):
		_object.property_list_changed.disconnect(_update_property_list)

	if is_instance_valid(object) and not object.property_list_changed.is_connected(_update_property_list):
		var error: Error = object.property_list_changed.connect(_update_property_list)
		assert(error == OK, error_string(error))

	_object = object

	_group_states.clear()
	_subgroup_states.clear()

	object_changed.emit(object)
	_update_property_list()

## Set category handling enabled.
func set_category_enabled(enabled: bool) -> void:
	if _category_enadled == enabled:
		return

	_category_enadled = enabled
	update_inspector()

## Returns [param true] if category handling is enabled.
func is_category_enabled() -> bool:
	return _category_enadled

## Set group handling enabled.
func set_group_enabled(enabled: bool) -> void:
	if _group_enabled == enabled:
		return

	_group_enabled = enabled
	update_inspector()

## Returns [param true] if group handling is enabled.
func is_group_enabled() -> bool:
	return _group_enabled

## Set sub-group handling enabled.
func set_subgroup_enabled(enabled: bool) -> void:
	if _subgroup_enabled == enabled:
		return

	_subgroup_enabled = enabled
	update_inspector()

## Returns [param true] if sub-group handling is enabled.
func is_subgroup_enabled() -> bool:
	return _subgroup_enabled

## Return edited object.
func get_object() -> Object:
	return _object

## Clear edited object.
func clear() -> void:
	self.set_object(null)

## Return [param true] if property is valid.
## Override for custom available properties.
func is_valid_property(property: Dictionary) -> bool:
	const PROPERTY_USAGE = PROPERTY_USAGE_SCRIPT_VARIABLE + PROPERTY_USAGE_DEFAULT
	const PROPERTY_USAGE_ENUM = PROPERTY_USAGE + PROPERTY_USAGE_CLASS_IS_ENUM

	if property["usage"] == PROPERTY_USAGE_CATEGORY:
		return is_category_enabled()

	elif property["usage"] == PROPERTY_USAGE_GROUP:
		return is_group_enabled()

	elif property["usage"] == PROPERTY_USAGE_SUBGROUP:
		return is_subgroup_enabled()

	elif property["hint"] == PROPERTY_HINT_ENUM:
		return property["usage"] == PROPERTY_USAGE_ENUM or property["usage"] == PROPERTY_USAGE_ENUM + PROPERTY_USAGE_READ_ONLY

	return property["usage"] == PROPERTY_USAGE or property["usage"] == PROPERTY_USAGE + PROPERTY_USAGE_READ_ONLY

## Return [Control] for property.
func create_property_control(object: Object, property: Dictionary) -> Control:
	var readonly: bool = is_readonly() or property["usage"] & PROPERTY_USAGE_READ_ONLY
	return InspectorProperty.create_property(object, property, not readonly)

## Update Inspector properties.
func update_inspector() -> void:
	if is_instance_valid(_container):
		_container.queue_free()

	_search.set_editable(is_instance_valid(_object))
	if not _search.is_editable():
		return

	_container = VBoxContainer.new()
	_container.set_name("Container")
	_container.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_container.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	_scroll_container.add_child(_container)

	var parent: Control = _container
	var category: Control = null
	var group: Control = null
	var subgroup: Control = null

	for property: Dictionary in _valid_properties:
		var control: Control = create_property_control(_object, property)
		if not is_instance_valid(control):
			continue

		# TODO: Do something. I really don't like all the code below...
		if property["usage"] == PROPERTY_USAGE_SUBGROUP:
			if is_instance_valid(group):
				parent = group.get_meta(&"property_container")
			elif is_instance_valid(category):
				parent = category.get_meta(&"property_container")
			else:
				parent = _container

			parent.add_child(control)

			parent = control.get_meta(&"property_container")
			assert(is_instance_valid(parent), "Subgroup property does not have `property_container` meta!")

			subgroup = control
			subgroup.call(&"set_toggled", _subgroup_states.get(property["name"], false))
			subgroup.set_meta(&"group", group)

			var error: Error = subgroup.connect(&"toggled", _on_subgroup_toggled.bind(property["name"]))
			assert(error == OK, error_string(error))

		elif property["usage"] == PROPERTY_USAGE_GROUP:
			if is_instance_valid(category):
				parent = category.get_meta(&"property_container")
			else:
				parent = _container

			parent.add_child(control)

			parent = control.get_meta(&"property_container")
			assert(is_instance_valid(parent), "Group property does not have `property_container` meta!")

			group = control
			group.call(&"set_toggled", _group_states.get(property["name"], false))
			group.set_meta(&"category", category)

			var error: Error = group.connect(&"toggled", _on_group_toggled.bind(property["name"]))
			assert(error == OK, error_string(error))

		elif property["usage"] == PROPERTY_USAGE_CATEGORY:
			_container.add_child(control)

			parent = control.get_meta(&"property_container")
			assert(is_instance_valid(parent), "Category property does not have `property_container` meta!")

			category = control

		else:
			control.set_meta(&"category", category)
			control.set_meta(&"group", group)
			control.set_meta(&"subgroup", subgroup)

			parent.add_child(control)

		property["control"] = control

# Potentially should be replaced by on-the-fly computing...
func _update_property_list() -> void:
	if is_instance_valid(_object):
		_valid_properties = _object.get_property_list()
	else:
		_valid_properties = []
	
	if !show_internal:
		var counter: int = 0
		# INFO: I know it's shitty code, but it works...
		var i: int = _valid_properties.size() - 1
		while i >= 0:
			var property: Dictionary = _valid_properties[i]
			if property["usage"] == PROPERTY_USAGE_SUBGROUP or property["usage"] == PROPERTY_USAGE_GROUP:
				if counter < 1:
					_valid_properties.remove_at(i)

				counter -= 1
			elif property["usage"] == PROPERTY_USAGE_CATEGORY:
				if counter < 1:
					_valid_properties.remove_at(i)

				counter = 0
			elif not is_valid_property(property):
				_valid_properties.remove_at(i)
			else:
				counter += 1

			i -= 1
	else :
		_valid_properties.reverse()

	update_inspector()

func _on_filter_text_chnaged(filter: String) -> void:
	for property: Dictionary in _valid_properties:
		var control: Control = property["control"]

		if filter.is_subsequence_ofn(property["name"]):
			if control.has_meta(&"category"):
				var category := control.get_meta(&"category") as Control
				if is_instance_valid(category):
					category.show()

			if control.has_meta(&"group"):
				var group := control.get_meta(&"group") as Control
				if is_instance_valid(group):
					group.show()

			if control.has_meta(&"subgroup"):
				var subgroup := control.get_meta(&"subgroup") as Control
				if is_instance_valid(subgroup):
					subgroup.show()

			control.show()

		else:
			control.hide()


func _on_group_toggled(expanded: bool, property: String) -> void:
	_group_states[property] = expanded

func _on_subgroup_toggled(expanded: bool, property: String) -> void:
	_subgroup_states[property] = expanded




#region property description
# Dictionary[[String: Dictionary[String: String]]
static var _descriptions: Dictionary = {}

## Adds a property description for the global name. Example:
## [codeblock]# Some script.gd...
## static func _static_init() -> void:
##     Inspector.add_description("ClassName", "some_value", "Property description.")
## [/codeblock]
static func add_description(global_name: String, property: String, description: String) -> void:
	_descriptions.get_or_add(global_name, {})[property] = description

## Similar to [method add_description] but takes an object of the [Script] class as an argument instead of global_name.
static func add_script_property_description(script: Script, property: String, description: String) -> void:
	if is_instance_valid(script):
		add_description(script.get_global_name(), property, description)

## Similar to [method add_description] but takes an object of the [Object] class as an argument instead of global_name.
static func add_object_description(object: Object, property: String, description: String) -> void:
	if is_instance_valid(object):
		add_script_property_description(object.get_script(), property, description)

## Returns the property description for the global name.
static func get_property_description(global_name: String, property: String) -> String:
	const NULL: Dictionary = {}

	return _descriptions.get(global_name, NULL).get(property, "")

## Similar to [method add_description] but takes an object of the [Script] class as an argument instead of global_name.
static func get_script_property_description(script: Script, property: String) -> String:
	while script:
		var desc: String = get_property_description(script.get_global_name(), property)
		if desc:
			return desc

		script = script.get_base_script()

	return ""

## Similar to [method add_description] but takes an object of the [Object] class as an argument instead of global_name.
static func get_object_property_description(object: Object, property: String) -> String:
	if is_instance_valid(object) and property:
		return get_script_property_description(object.get_script(), property)

	return ""
#endregion
