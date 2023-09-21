extends Node

@export var displayImage: TextureRect
@export var shaderSPV: RDShaderSPIRV

var device: RenderingDevice
var shaderRID: RID
var pipelineRID: RID
var viewSize: Vector2i

var renderTextureRID: RID
var renderTextureUniform: RDUniform
var renderTextureSetRID: RID

var storageBufferRID: RID
var storageBufferUniform: RDUniform
var storageBufferSetRID: RID

func _ready():
	device = RenderingServer.create_local_rendering_device()
	shaderRID = device.shader_create_from_spirv(shaderSPV)
	pipelineRID = device.compute_pipeline_create(shaderRID)
	
	_on_window_resize()
	get_tree().root.size_changed.connect(_on_window_resize)
	
func _on_window_resize():
	var viewport: Viewport = get_viewport()
	viewSize = Vector2i(viewport.size.x, viewport.size.y)
	
	if renderTextureRID.is_valid():
		device.free_rid(renderTextureRID)
		device.free_rid(renderTextureSetRID)
		
	var format = RDTextureFormat.new()
	format.width = viewSize.x;
	format.height = viewSize.y;
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var view = RDTextureView.new()
	var data = PackedByteArray()
	data.resize(viewSize.x * viewSize.y * 16)
	data.fill(0)
	
	renderTextureRID = device.texture_create(format, view, [data])
	renderTextureUniform = RDUniform.new()
	renderTextureUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	renderTextureUniform.binding = 0
	renderTextureUniform.add_id(renderTextureRID)

	renderTextureSetRID = device.uniform_set_create([renderTextureUniform], shaderRID, 0)
	
func _process(_delta):
	if device == null:
		return
	
	var randomData = PackedByteArray()
	randomData.resize(8)
	randomData.encode_float(0, randf())
	randomData.encode_float(4, randf())
	storageBufferRID = device.storage_buffer_create(8, randomData)
	
	storageBufferUniform = RDUniform.new()
	storageBufferUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	storageBufferUniform.binding = 0
	storageBufferUniform.add_id(storageBufferRID)
	
	storageBufferSetRID = device.uniform_set_create([storageBufferUniform], shaderRID, 1)
	
	var groupX = int(viewSize.x / floor(8))
	var groupY = int(viewSize.y / floor(8))
	
	var list = device.compute_list_begin()
	device.compute_list_bind_compute_pipeline(list, pipelineRID)
	
	device.compute_list_bind_uniform_set(list, renderTextureSetRID, 0)
	device.compute_list_bind_uniform_set(list, storageBufferSetRID, 1)
	
	device.compute_list_dispatch(list, groupX, groupY, 1)
	device.compute_list_end()
	
	device.submit()
	device.sync()
	
	device.free_rid(storageBufferSetRID)
	device.free_rid(storageBufferRID)
	
	var image = Image.create_from_data(viewSize.x, viewSize.y, false, Image.FORMAT_RGBAF, device.texture_get_data(renderTextureRID, 0))
	
	if displayImage.texture == null:
		displayImage.texture = ImageTexture.create_from_image(image)
		
	else:
		displayImage.texture.update(image)
