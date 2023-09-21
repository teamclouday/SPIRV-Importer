@tool
extends EditorImportPlugin

enum ShaderTypes {
	VERTEX,
	FRAGMENT,
	TESSELATION_CONTROL,
	TESSELATION_EVALUATION,
	COMPUTE,
}

enum Presets { DEFAULT }

func _get_importer_name():
	return "teamclouday.spirvloader"
	
func _get_visible_name():
	return "SPIRV Loader"
	
func _get_recognized_extensions():
	return ["spv"]
	
func _get_save_extension():
	return "res"
	
func _get_resource_type():
	return "RDShaderSPIRV"

func _get_preset_count():
	return Presets.size()

func _get_priority():
	return 1.0

func _get_preset_name(preset_index):
	match preset_index:
		Presets.DEFAULT:
			return "Default"
		_:
			return "Unkown"

func _get_import_order():
	return 0
	
func _get_option_visibility(path, option_name, options):
	return true

func _get_import_options(path, preset_index):
	match preset_index:
		Presets.DEFAULT:
			return [{
				"name": "shader_type",
				"default_value": "COMPUTE",
				"property_hint": PROPERTY_HINT_ENUM,
				"hint_string": "VERTEX,FRAGMENT,TESSELATION_CONTROL,TESSELATION_EVALUATION,COMPUTE",
				"usage": PROPERTY_USAGE_EDITOR,
			}]
		_:
			return []

func _import(source_file, save_path, options, platform_variants, gen_files):
	var data = FileAccess.get_file_as_bytes(source_file)
	if data == null:
		return FileAccess.get_open_error()

	var shader = RDShaderSPIRV.new()
	match options.shader_type:
		"VERTEX":
			shader.set_stage_bytecode(RenderingDevice.SHADER_STAGE_VERTEX, data)
		"FRAGMENT":
			shader.set_stage_bytecode(RenderingDevice.SHADER_STAGE_FRAGMENT, data)
		"TESSELATION_CONTROL":
			shader.set_stage_bytecode(RenderingDevice.SHADER_STAGE_TESSELATION_CONTROL, data)
		"TESSELATION_EVALUATION":
			shader.set_stage_bytecode(RenderingDevice.SHADER_STAGE_TESSELATION_EVALUATION, data)
		"COMPUTE":
			shader.set_stage_bytecode(RenderingDevice.SHADER_STAGE_COMPUTE, data)
	
	return ResourceSaver.save(shader, "%s.%s" % [save_path, _get_save_extension()])
