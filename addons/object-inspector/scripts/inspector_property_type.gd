# Copyright (c) 2022-2024 Mansur Isaev and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
@tool
class_name InspectorPropertyType


static var _declarations: Dictionary = {}


static func register_type(type: Variant.Type, name: StringName, constructor: Callable) -> void:
	assert(constructor.is_valid(), "Invalid constructor Callable.")

	if constructor.is_valid():
		_declarations[type] = {"type": type, "name": name, "constructor": constructor}

static func unregister_type(type: Variant.Type) -> bool:
	return _declarations.erase(type)


static func get_type_list() -> Array[Dictionary]:
	var type_list: Array[Dictionary] = []

	for type: Variant.Type in _declarations:
		type_list.push_back({"type": type, "name": _declarations[type]["name"]})

	return type_list


static func is_valid_type(type: Variant.Type) -> bool:
	return _declarations.has(type)

static func create_control(type: Variant.Type, setter: Callable, getter: Callable, editable: bool) -> Control:
	var value: Variant = getter.call()

	if value == null:
		value = type_convert(null, type)
	elif type == TYPE_NIL:
		type = typeof(value)

	var decl: Dictionary = _declarations.get(type, {})
	if decl.is_empty():
		return null

	var constructor: Callable = decl["constructor"]
	if not constructor.is_valid():
		return null

	return constructor.call(setter, getter, editable)
