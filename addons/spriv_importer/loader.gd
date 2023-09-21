@tool
extends EditorPlugin

var import_plugin: EditorImportPlugin

func _enter_tree():
	import_plugin = preload("importer.gd").new()
	add_import_plugin(import_plugin)

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_import_plugin(import_plugin)
	import_plugin = null
