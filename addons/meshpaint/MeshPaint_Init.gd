@tool
extends EditorPlugin


## Attribution
## Paint brush icon created by Freepik - Flaticon
## https://www.flaticon.com/free-icons/paint-brush

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("PaintableMesh", "MeshInstance3D", preload("res://addons/meshpaint/PaintableMesh.gd"), preload("res://addons/meshpaint/paint_brush_icon.png"))
	add_custom_type("MeshPaintBrush", "RayCast3D", preload("res://addons/meshpaint/MeshPaint_Brush.gd"), preload("res://addons/meshpaint/paint_brush_icon.png"))


func _exit_tree() -> void:
	remove_custom_type("PaintableMesh")
	remove_custom_type("MeshPaintBrush")


	# Remove the dock.
	
	# Erase the control from the memory.
