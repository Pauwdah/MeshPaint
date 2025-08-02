@tool
class_name MeshPaintBrush
extends RayCast3D

## A [RayCast3D], used for painting on [PaintableMesh]es.

############################################################################
# NOT EXPORTED VARIABLES
############################################################################

## Static reference to the [MeshPaintBrush] object instance in the scene tree.
static var object_instance
static var isInTree: bool = false
## The brush that is used.
static var brush: Image
static var rect: Rect2i
static var paintable_mesh: PaintableMesh
static var collisionPoint: Vector3
static var collisionFaceIndex: int


############################################################################
# EXPORTED VARIABLES
############################################################################


############################################
# GROUP BRUSH SETTINGS
############################################

## Sets the color of the brush. Works on Runtime.
static var brush_color: Color
## Sets the size of the brush. Works on Runtime.
static var brush_size: int = 64:
	set(value):
		brush_size = value
		_resize_brush(value)

############################################
# GROUP BRUSH TEXTURE
############################################

## Sets brush usage to [param atlas_texutre]=[code]true[/code] or [param brush_texture]=[code]false[/code].
static var use_texture_atlas: bool = false:
	set(value):
		use_texture_atlas = value
		if Engine.is_editor_hint():
			MeshPaintBrush.object_instance.notify_property_list_changed()
		else:
			send_notify_after_ready()
		
	
## [AtlasTexture] used for the brush if [param use_texture_atlas] is [code]true[/code].
var atlas_texutre: AtlasTexture:
	set(value):
		atlas_texutre = value
		print("atlas_texutre changed")

## [Texture2D] used for the brush if [param use_texture_atlas] is [code]false[/code].
static var brush_texture: Texture2D = preload("res://addons/meshpaint/brushes/brush.png")
# @export var froce_brush_format: bool = false
# @export var forced_brush_format: Image.Format = Image.FORMAT_RGBA8

############################################
# GROUP RAY SETTINGS
############################################

static var ray_length_multiplier: float = 2
## If [code]true[/code], [param position] and [param target_position] can be set manually. [br]
## If [code]false[/code], ray will always project from active [Camera3D], to mouse position.
var use_custom_ray: bool = false:
	set(value):
		use_custom_ray = value
		if Engine.is_editor_hint():
			MeshPaintBrush.object_instance.notify_property_list_changed()
		else:
			send_notify_after_ready()
		

############################################
# GROUP INPUT
############################################

## If [code]true[/code], [param custom_input_action] will be used to paint instead of the default [enum Input.MOUSE_BUTTON_LEFT]
var use_custom_input_action: bool = false:
	set(value):
		use_custom_input_action = value
		if Engine.is_editor_hint():
			MeshPaintBrush.object_instance.notify_property_list_changed()
		else:
			send_notify_after_ready()
		
	
static var custom_input_action: String = "ui_select"
## Set [code]true[/code] at the end of [method _ready]. [br]
## Used to eliminate racing condition of [method Object.notify_property_list_changed]
static var isReady: bool = false

static func send_notify_after_ready():
	if isReady:
		MeshPaintBrush.object_instance.notify_property_list_changed()


func _get_property_list():
	if Engine.is_editor_hint():
		var return_array = []
		
		# GROUP BRUSH SETTINGS
		return_array.append_array([
			{"name": "Brush",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			},
			{"name": &"brush_size",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			},
			{"name": &"brush_color",
			"type": TYPE_COLOR,
			"usage": PROPERTY_USAGE_DEFAULT,
			}
			])

		# BRUSH TEXTURE SETTINGS
		return_array.append(
			{"name": "Brush Texture",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			})

		# return_array.append({
		# 	"name": &"use_texture_atlas",
		# 	"type": TYPE_BOOL,
		# 	"usage": PROPERTY_USAGE_DEFAULT,
		# 	})

		if use_texture_atlas:
			return_array.append({
			"name": &"atlas_texutre",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			})
		else:
			return_array.append({
			"name": &"brush_texture",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_DEFAULT,
			})

	
		# GROUP RAY SETTINGS
		return_array.append_array([
			{"name": "Brush Ray",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			},
			{"name": &"use_custom_ray",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
			}
			])
			
		
		if !use_custom_ray:
			return_array.append(
			{"name": &"ray_length_multiplier",
			"type": TYPE_FLOAT,
			"usage": PROPERTY_USAGE_DEFAULT,
			})

		# GROUP INPUT SETTINGS
		return_array.append_array([
			{"name": "Input",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			},
			{"name": &"use_custom_input_action",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT,
			}
			])
			
		
		if use_custom_input_action:
			return_array.append(
			{"name": &"custom_input_action",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			})
			

		return return_array


############################################################################
# FUNCTIONS
############################################################################


############################################
# PROTECTED
############################################

func _enter_tree() -> void:
	if MeshPaintBrush.isInTree:
		printerr("MESHPAINT: Only 1 Brush can be in Tree. Deleting surplus.")
		queue_free()
	else:
		isInTree = true
		object_instance = self

func _exit_tree() -> void:
	isInTree = false


func _ready():
	if !Engine.is_editor_hint():
		debug_shape_thickness = 2
		debug_shape_custom_color = Color.PINK

		
		_load_brush()
		_create_brush_rect()

		print_rich(str(
			MeshPaint.title, "Brush ready."
		))
		isReady = true


func _process(delta):
	if !Engine.is_editor_hint():
		if use_custom_input_action:
			if Input.is_action_pressed(custom_input_action):
				_paint_if_mesh_hit()
		else:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				_paint_if_mesh_hit()
		

############################################
# PRIVATE
############################################

static func _resize_brush(newSize: int):
	if brush != null:
		brush.resize(newSize, newSize, Image.INTERPOLATE_BILINEAR)

func _cast_ray_from_camera_to_mouse_pos():
	var from_camera = get_viewport().get_camera_3d()
	if from_camera == null:
		return
	var to = from_camera.project_ray_normal(get_viewport().get_mouse_position()) * ray_length_multiplier
	global_position = from_camera.global_position
	target_position = to

	
func _load_brush():
	brush = Image.new()
	brush = brush_texture.get_image()
	brush.decompress()
	_resize_brush(brush_size)


func _create_brush_rect():
	var rectSize = brush.get_height()
	rect = Rect2i(Vector2i(0, 0), Vector2i(rectSize, rectSize))
	

func _paint_if_mesh_hit():
	if !use_custom_ray:
			_cast_ray_from_camera_to_mouse_pos()
			
	if is_colliding() && get_collider().is_in_group("PaintableMeshCollider"):
		#
		paintable_mesh = get_collider().get_parent()
		paintable_mesh.paint(get_collision_point(), get_collision_face_index(), brush_color)
		

############################################
# PUBLIC
############################################


static func randomize_atlas_brush(): # choose a random sprite from my 2x2 atlas texture
	#TODO This method doesnt work yet
	var index: Vector2i = Vector2i(0, 0)
	if randi() % 2:
		index = Vector2i(brush_size, 0)
	if randi() % 2:
		index = Vector2i(index.x, brush_size)
	rect = Rect2i(Vector2i(index.x, index.y), Vector2i(brush_size, brush_size))
