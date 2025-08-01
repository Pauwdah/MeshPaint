@tool
class_name PaintableMesh
extends MeshInstance3D


# Formatting

# Formatting End

@export var paint_on_material: PaintOnMat = PaintOnMat.MATERIAL_OVERRIDE
## The texture path relative to [param paint_on_material] e.g. [color=#88FFFF][i]'next_pass/albedo_texture'[/i][/color]
@export var paint_on_texture_path: String = "albedo_texture"
## Format of [param paint_on_texture_path]
@export var image_format: Image.Format = Image.FORMAT_RGBA8
## Sets the uv calculation mode.
@export var uv_flip: UvFlip = UvFlip.DISABLED
## Usefull when exported UV's don't fit Godots default.
@export var uv_negative: UvNegative = UvNegative.DISABLED

## Creates an ImageTexture at [param paint_on_texture_path] in [param paint_on_material].
## Good if you don't want to make new textures all the time.
@export var use_fallback_image: bool = true
## This resolution only applies if the given [param paint_on_texture_path] doesn't already have a texture assigned.
@export var fallback_resolution: Vector2i = Vector2i(1024, 1024)


## The path to your brush in the [color=#AAFFFF][b]res://[/b][/color] folder.


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


var paint_image_texture: ImageTexture

var paint_texture_2d: Texture2D = null
## Collision Object that is used. [br]
## E.g.: StaticBody3D, RigidBody3D
var collider: CollisionObject3D

var meshtool: MeshDataTool


func _ready() -> void:
	#Null Check Assigments
	if mesh == null:
		mesh = preload("res://addons/meshpaint/misc/DefaultCube.obj")

	_init_meshtool()
	_prepare_texture()
	_prepare_collider()

	print_rich(str(
		MeshPaint.title, "PaintableMesh \"", name, "\" ready."
	))


func _prepare_collider():
	for child in get_children():
		if child is CollisionObject3D:
			collider = child

	if collider == null:
		printerr(str(
			"MESHPAINT: \"", name, "\" No CollisionObject3D child. (e.g. StaticBody3d, RidgidBody3D)",
		))
		# var staticBody: StaticBody3D = StaticBody3D.new()
		# add_child(staticBody)
		# collider = staticBody

		# var collisionShape: CollisionShape3D = CollisionShape3D.new()
		# staticBody.add_child(collisionShape)
		# collisionShape.shape = mesh.create_convex_shape()
		
	# Creating Group for Comparison
	collider.add_to_group("PaintableMeshCollider")
	pass


func _prepare_texture():
	match paint_on_material:
		PaintOnMat.MATERIAL_OVERRIDE:
			#
			if material_override == null:
				set("material_override", StandardMaterial3D.new())
			
			if use_fallback_image:
				paint_image_texture = _create_image_texture_from_texture_2d()
				paint_texture_2d = paint_image_texture
			else:
				paint_texture_2d = material_override.get(paint_on_texture_path)
				paint_image_texture = _create_image_texture_from_texture_2d(paint_texture_2d)
				if paint_texture_2d == null: # create new
					printerr(str(
						"MESHPAINT: No Texture found at: \"", paint_on_texture_path, "\" ", "Either use Fallback Image or enter valid path."
					))

		PaintOnMat.MATERIAL_OVERLAY:
			#
			if material_overlay == null:
				set("material_overlay", StandardMaterial3D.new())

			if paint_on_texture_path != "":
				printerr("MESHPAINT: No Texture Path specified.")
				return
	
			if use_fallback_image:
				paint_image_texture = _create_image_texture_from_texture_2d()
				paint_texture_2d = paint_image_texture
			else:
				paint_texture_2d = material_overlay.get(paint_on_texture_path)
				paint_image_texture = _create_image_texture_from_texture_2d(paint_texture_2d)
				if paint_texture_2d == null: # create new
					printerr(str(
						"MESHPAINT: No Texture found at: \"", paint_on_texture_path, "\" ", "Either use Fallback Image or enter valid path."
					))


func _create_image_texture_from_texture_2d(textureToEdit: Texture2D = ImageTexture.create_from_image(Image.create(fallback_resolution.x, fallback_resolution.y, false, image_format))):
	## Size from [param paint_on_texture_path] texture
	var size = textureToEdit.get_size()
	
	var img = Image.create(size.x, size.y, false, image_format)
	img.fill(Color(1, 1, 1, 1))
	
	return ImageTexture.create_from_image(img)


## Paints at the location of the [PaintableMesh], where the mouse is pointing.
func paint(uv_point: Vector2, _color: Color = Color.BLACK):
	var aimed_pixel: Vector2i = Vector2(uv_point.x, uv_point.y) * Vector2(paint_image_texture.get_size())

	aimed_pixel = Vector2i(aimed_pixel.x - 1, aimed_pixel.y - 1) # ensure its not out of bounds
	aimed_pixel = Vector2i(aimed_pixel.x - MeshPaintBrush.rect.size.x / 2, aimed_pixel.y - MeshPaintBrush.rect.size.y / 2)

	if MeshPaintBrush.is_using_texture_atlas:
		MeshPaintBrush.randomize_atlas_brush()

	
	print(str(
		"Brush Size: ", MeshPaintBrush.brush.get_size(), "\n",
		"Rect Size: ", MeshPaintBrush.rect.size
	))
	var paint_image = paint_image_texture.get_image()
	paint_image.blend_rect(MeshPaintBrush.brush, MeshPaintBrush.rect, Vector2i(aimed_pixel.x, aimed_pixel.y)) # * img & brush need to be same format
	paint_image_texture.update(paint_image)
	
	match paint_on_material:
		PaintOnMat.MATERIAL_OVERRIDE:
			material_override.set(paint_on_texture_path, paint_image_texture)
			# material_override.albedo_texture = paint_image_texture
		PaintOnMat.MATERIAL_OVERLAY:
			material_overlay.set(paint_on_texture_path, paint_image_texture)
			# material_overlay.albedo_texture = paint_image_texture

	# save_image(paint_image)


func _init_meshtool():
	meshtool = MeshDataTool.new()
	if mesh is ArrayMesh:
		meshtool.create_from_surface(mesh, 0)

		
	else:
		printerr("MESHPAINT: Mesh needs to be of Type ArrayMesh.")
		return
	

func get_uv_coord_by_collision_point(collision_point: Vector3, normal_index: int):
	var local_point = to_local(collision_point)

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


func save_image(image: Image):
	image.save_png("user://image.png")
	pass
