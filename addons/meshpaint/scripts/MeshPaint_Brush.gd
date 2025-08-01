@tool
class_name MeshPaintBrush
extends RayCast3D


static var isInTree: bool = false
## The brush that is used.
static var brush: Image
static var rect: Rect2i
## The path to your brush in the [color=#AAFFFF][b]res://[/b][/color] folder.
@export var brush_texture: Texture2D = preload("res://addons/meshpaint/brushes/brush.png")

# @export var froce_brush_format: bool = false
# @export var forced_brush_format: Image.Format = Image.FORMAT_RGBA8

@export var brush_color: Color

@export var brush_size: int = 64:
	set(value):
		brush_size = value
		_brushSize = value
		_resize_brush(value)
## Squared brush size that is used.
static var _brushSize: int = 64
## If enabled, [color=#AAFFFF][b]brush_path[/b][/color] is seen as a texture atlas.
@export var use_texture_atlas: bool:
	set(value):
		use_texture_atlas = value
		is_using_texture_atlas = value
		pass
static var is_using_texture_atlas: bool
## If [member use_texture_atlas] is enabled, this will tell how many times the texture gets split. [br]
## Example: [br]
## If you have a squared map with 4 sprites, type: X=2;Y=2 [br]
## If you have a wide map with 4 sprites type: X=1;Y=4
@export var texture_atlas_compartments: Vector2i


var paintable_mesh: PaintableMesh

var collisionPoint: Vector3
var collisionFaceIndex: int


func _enter_tree() -> void:
	if MeshPaintBrush.isInTree:
		printerr("MESHPAINT: Only 1 Brush can be in Tree. Deleting surplus.")
		queue_free()
	else:
		isInTree = true

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


func _process(delta):
	if !Engine.is_editor_hint():
		_cast_ray_from_camera_to_mouse_pos()
		

func _cast_ray_from_camera_to_mouse_pos():
	var fromCamera = get_viewport().get_camera_3d()

	if fromCamera == null:
		return
	var to = fromCamera.project_ray_normal(get_viewport().get_mouse_position())
	global_position = fromCamera.global_position
	target_position = to

	
func _load_brush():
	brush = Image.new()
	brush = brush_texture.get_image()
	brush.decompress()
	_resize_brush(_brushSize)


func _resize_brush(newSize: int):
	if brush != null:
		print(str(
			"Brush Format: ", brush.get_format()
		))
		brush.resize(newSize, newSize, Image.INTERPOLATE_BILINEAR)
		

func _create_brush_rect():
	var rectSize = brush.get_height()
	rect = Rect2i(Vector2i(0, 0), Vector2i(rectSize, rectSize))
	

static func randomize_atlas_brush(): # choose a random sprite from my 2x2 atlas texture
	var index: Vector2i = Vector2i(0, 0)
	if randi() % 2:
		index = Vector2i(_brushSize, 0)
	if randi() % 2:
		index = Vector2i(index.x, _brushSize)
	rect = Rect2i(Vector2i(index.x, index.y), Vector2i(_brushSize, _brushSize))


func _paint_if_mesh_hit():
	if is_colliding() && get_collider().is_in_group("PaintableMeshCollider"):
		#
		paintable_mesh = get_collider().get_parent()

		var uv_point = paintable_mesh.get_uv_coord_by_collision_point(get_collision_point(), get_collision_face_index())
		
		if uv_point == null:
			return
		paintable_mesh.paint(uv_point, brush_color)
		

func _input(event):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_paint_if_mesh_hit()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pass
