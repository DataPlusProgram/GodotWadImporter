# Copyright (c) 2022-2024 Mansur Isaev and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.

@tool
extends EditorPlugin


const INSPECTOR_CONTROL_NAME = "ObjectInspector"
const INSPECTOR_CONTROL_SCRIPT = "res://addons/object-inspector/scripts/inspector.gd"
const INSPECTOR_CONTROL_ICON = "res://addons/object-inspector/icons/inspector_container.svg"


func _enter_tree() -> void:
	add_custom_type(INSPECTOR_CONTROL_NAME, "VBoxContainer", load(INSPECTOR_CONTROL_SCRIPT), load(INSPECTOR_CONTROL_ICON))


func _exit_tree() -> void:
	remove_custom_type(INSPECTOR_CONTROL_NAME)
