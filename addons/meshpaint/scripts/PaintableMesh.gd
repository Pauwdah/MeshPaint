@tool
class_name PaintableMesh
extends MeshInstance3D

## A [MeshInstance3D], used for painting by MeshPaint.

############################################################################
# ENUMS
############################################################################

enum UvFlip {
	## Default UV calculation.
	DISABLED,
	## Flips UV on Y [br]
	## E.g.: Y 0.3 will be 0.7
	FLIP_Y,
	## Flips UV on X [br]
	## E.g.: X 0.3 will be 0.7
	FLIP_X,
	## [param UvFlip.FLIP_Y] & [param UvFlip.FLIP_X]
	FLIP_X_Y

	}

enum UvNegative {
	## Disabled
	DISABLED,
	## UV on Y *-1 [br]
	## E.g.: Y -0.3 will be 0.3
	NEGATIVE_Y,
	## UV on X *-1 [br]
	## E.g.: X -0.3 will be 0.3
	NEGATIVE_X,
	## [param UvNegative.NEGATIVE_Y] & [param UvNegative.NEGATIVE_X] 
	NEGATIVE_X_Y,
}

enum PaintOnMat {
	## This Meshes [param material_override]
	MATERIAL_OVERRIDE,
	## This Meshes [param material_overlay]
	MATERIAL_OVERLAY
}

############################################################################
# NOT EXPORTED VARIABLES
############################################################################

## This is the [ImageTexture] [MeshPaintBrush] will paint on.
var paint_image_texture: ImageTexture
## Collision Object that is used. [br]
## E.g.: StaticBody3D, RigidBody3D
var collider: CollisionObject3D
## Used to get information about the meshes Verticies & UV.
var meshtool: MeshDataTool


############################################################################
# EXPORTED VARIABLES
############################################################################

## This is the material used for painting.
var paint_on_material: PaintOnMat = PaintOnMat.MATERIAL_OVERRIDE
## The texture path relative to [param paint_on_material] e.g. [color=#88FFFF][i]'next_pass/albedo_texture'[/i][/color]
var paint_on_texture_path: String = "albedo_texture"


############################################
# GROUP UV SETTINGS
############################################


## Flip Mode for UVs. (Useful when imported UV's don't fit Godots default.) [br]
## E.g.: 0.3 will be 0.7
var uv_flip: UvFlip = UvFlip.DISABLED
## Pulls UV's from Negative to Positive space. (Useful when imported UV's don't fit Godots default.)[br]
## E.g.: -0.3 will be 0.3
var uv_negative: UvNegative = UvNegative.DISABLED

############################################
# FALLBACK IMAGE SETTINGS
############################################


## This resolution only applies if the given [param paint_on_texture_path] doesn't already have a texture assigned.
var fallback_resolution: Vector2i = Vector2i(1024, 1024)
## Format used by fallback texture. [MeshPaintBrush] [enum Image.Format] & [PaintableMesh] [enum Image.Format] must be the same.
var fallback_image_format: Image.Format = Image.FORMAT_RGBA8


func _get_property_list():
	if Engine.is_editor_hint():
		var return_array = []


		# GROUP TEXTURE
		return_array.append(
			{"name": "Texture",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			})
		return_array.append(
			{
			"name": &"paint_on_material",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(PaintOnMat.keys())
			})
		return_array.append(
			{"name": &"paint_on_texture_path",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_DEFAULT,
			})
		# GROUP UV SETTINGS
		return_array.append(
			{"name": "UV",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			})
		return_array.append(
			{
			"name": &"uv_flip",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(UvFlip.keys())
			})
		return_array.append(
			{
			"name": &"uv_negative",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(UvNegative.keys())
			})
		# FALLBACK IMAGE SETTINGS
		return_array.append(
			{"name": "Fallback Image",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			})
		
		
		return_array.append(
		{
		"name": &"fallback_resolution",
		"type": TYPE_VECTOR2I,
		"usage": PROPERTY_USAGE_DEFAULT,
		})
		return_array.append(
		{
		"name": &"fallback_image_format",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(ClassDB.class_get_enum_constants("Image", "Format"))
		
		})
		
		return return_array
	

############################################################################
# FUNCTIONS
############################################################################

############################################
# PROTECTED
############################################

func _ready() -> void:
	#Null Check Assigments
	if mesh == null:
		mesh = BoxMesh.new()

	_init_meshtool()
	_prepare_texture()
	_prepare_collider()

	print_rich(str(
		MeshPaint.title, "PaintableMesh \"", name, "\" ready."
	))


############################################
# PRIVATE
############################################

func _init_meshtool():
	meshtool = MeshDataTool.new()
	if mesh is ArrayMesh:
		pass
	else:
		print_rich(str(
			MeshPaint.title, "[color=yellow]Mesh needs to be of Type ArrayMesh. Converting Mesh to ArrayMesh...[/color]"
		))
		var surface_tool := SurfaceTool.new()
		surface_tool.create_from(mesh, 0)
		mesh = surface_tool.commit()

	meshtool.create_from_surface(mesh, 0)


func _prepare_collider():
	for child in get_children():
		if child is CollisionObject3D:
			collider = child

	if collider == null:
		print_rich(str(
			MeshPaint.title, "[color=yellow]\"", name, "\" No CollisionObject3D child. (e.g. StaticBody3d, RidgidBody3D) Creating 'StaticBody3D' with 'ConcavePolygonShape3D' from '", name, "'[/color]"
		))

		var staticBody: StaticBody3D = StaticBody3D.new()
		add_child(staticBody)
		collider = staticBody

		var collisionShape: CollisionShape3D = CollisionShape3D.new()
		staticBody.add_child(collisionShape)
		collisionShape.shape = mesh.create_trimesh_shape()
		
	# Creating Group for Comparison
	collider.add_to_group("PaintableMeshCollider")
	pass


func _prepare_texture():
	if paint_on_texture_path == "":
		printerr("MESHPAINT: No Texture Path specified.")
		return
	var paint_texture_2d: Texture2D = null
	match paint_on_material:
		PaintOnMat.MATERIAL_OVERRIDE:
			#
			if material_override == null:
				set("material_override", StandardMaterial3D.new())
	
			paint_texture_2d = material_override.get(paint_on_texture_path)

		PaintOnMat.MATERIAL_OVERLAY:
			#
			if material_overlay == null:
				set("material_overlay", StandardMaterial3D.new())
	
			paint_texture_2d = material_overlay.get(paint_on_texture_path)

	if paint_texture_2d == null: # create new
		paint_image_texture = _create_image_texture_from_texture_2d()
	else:
		paint_image_texture = _create_image_texture_from_texture_2d(paint_texture_2d)


func _create_image_texture_from_texture_2d(textureToEdit: Texture2D = ImageTexture.create_from_image(Image.create(fallback_resolution.x, fallback_resolution.y, false, fallback_image_format))):
	## Size from [param paint_on_texture_path] texture
	var size = textureToEdit.get_size()
	
	var img = Image.create(size.x, size.y, false, textureToEdit.get_format())
	img.fill(Color(1, 1, 1, 1))
	
	return ImageTexture.create_from_image(img)


func _get_uv_coord_by_collision_point(collision_point_global: Vector3, normal_index: int) -> Vector2:
	var local_point = to_local(collision_point_global)

	if normal_index == null:
		return Vector2.ZERO
	
	
	var v1 = meshtool.get_vertex(meshtool.get_face_vertex(normal_index, 0))
	var v2 = meshtool.get_vertex(meshtool.get_face_vertex(normal_index, 1))
	var v3 = meshtool.get_vertex(meshtool.get_face_vertex(normal_index, 2))


	var bc = Geometry3D.get_triangle_barycentric_coords(local_point, v1, v2, v3)

	var uv1 = meshtool.get_vertex_uv(meshtool.get_face_vertex(normal_index, 0))
	var uv2 = meshtool.get_vertex_uv(meshtool.get_face_vertex(normal_index, 1))
	var uv3 = meshtool.get_vertex_uv(meshtool.get_face_vertex(normal_index, 2))

	var uv = (uv1 * bc.x) + (uv2 * bc.y) + (uv3 * bc.z)

	match uv_negative:
		UvNegative.DISABLED:
			pass
		UvNegative.NEGATIVE_X:
			uv.x = - uv.x
		UvNegative.NEGATIVE_Y:
			uv.y = - uv.y
		UvNegative.NEGATIVE_X_Y:
			uv.x = - uv.x
			uv.y = - uv.y
	
	match uv_flip:
		UvFlip.DISABLED:
			pass
		UvFlip.FLIP_X:
			uv.x = remap(uv.x, 0, 1, 1, 0) # flip x mapping
		UvFlip.FLIP_Y:
			uv.y = remap(uv.y, 0, 1, 1, 0) # flip y mapping
		UvFlip.FLIP_X_Y:
			uv.x = remap(uv.x, 0, 1, 1, 0) # flip x mapping
			uv.y = remap(uv.y, 0, 1, 1, 0) # flip y mapping
	return uv

############################################
# PUBLIC
############################################

## Paints at [param collision_point] with its [param face_index] with the color of [param _color] on this [PaintableMesh]. [br]
## Values can be obtained by [method RayCast3D.get_collision_point] & [method RayCast3D.get_collision_face_index]
func paint(collision_point: Vector3, face_index: int, _color: Color = Color.BLACK):
	var uv_point = _get_uv_coord_by_collision_point(collision_point, face_index)
	if uv_point == null:
			return
	var aimed_pixel: Vector2i = Vector2(uv_point.x, uv_point.y) * Vector2(paint_image_texture.get_size())

	aimed_pixel = Vector2i(aimed_pixel.x - 1, aimed_pixel.y - 1) # ensure its not out of bounds
	aimed_pixel = Vector2i(aimed_pixel.x - MeshPaintBrush.rect.size.x / 2, aimed_pixel.y - MeshPaintBrush.rect.size.y / 2)

	if MeshPaintBrush.use_texture_atlas:
		MeshPaintBrush.randomize_atlas_brush()

	var paint_image = paint_image_texture.get_image()
	# paint_image.blend_rect(MeshPaintBrush.brush, MeshPaintBrush.rect, Vector2i(aimed_pixel.x, aimed_pixel.y)) # * img & brush need to be same format
	var color_image = Image.create(MeshPaintBrush.rect.size.x, MeshPaintBrush.rect.size.y, false, Image.FORMAT_RGBA8)
	color_image.fill(_color)
	
	paint_image.blend_rect_mask(color_image, MeshPaintBrush.brush, MeshPaintBrush.rect, Vector2i(aimed_pixel.x, aimed_pixel.y))

	paint_image_texture.update(paint_image)
	
	match paint_on_material:
		PaintOnMat.MATERIAL_OVERRIDE:
			material_override.set(paint_on_texture_path, paint_image_texture)
			# material_override.albedo_texture = paint_image_texture
		PaintOnMat.MATERIAL_OVERLAY:
			material_overlay.set(paint_on_texture_path, paint_image_texture)
			# material_overlay.albedo_texture = paint_image_texture
