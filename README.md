# MeshPaint

A godot addon for painting on meshes at runtime.

## Main functionality

MeshPaint features 2 Nodes. "PaintableMesh" and "MeshPaintBrush". \
An example scene is provided.

## Node: PaintableMesh

This node inherited from [**MeshInstance3D**](https://docs.godotengine.org/en/stable/classes/class_meshinstance3d.html) & hosts the [**Mesh**](https://docs.godotengine.org/en/stable/classes/class_mesh.html#class-mesh), [**Material**](https://docs.godotengine.org/en/stable/classes/class_standardmaterial3d.html#class-standardmaterial3d) & [**Texture**](https://docs.godotengine.org/en/stable/classes/class_texture2d.html#class-texture2d) you paint on.

You can use it in combination with the **MeshPaintBrush** or just use **PaintableMesh.paint()** on that instance in combination with a custom [**RayCast3D**](https://docs.godotengine.org/en/stable/classes/class_raycast3d.html).

### Properties

| **Property**|**Type** | **Description**| **Default** |
|-|-|-|-|
|``paint_on_material``|``enum PaintOnMat``|Can either target ``Material Override`` or ``Material Overlay``| ``MATERIAL_OVERRIDE``|
|``paint_on_texture_path``|``String``|The texture path relative to ``paint_on_material`` used for paiting. E.g.: ``next_pass/albedo_texture`` |``"albedo_texture"``|
|-|-|-|-|
|``uv_flip``|``enum UvFlip``|Flipping/Mirror mode used for the UV map.|``DISABLED``|
|``uv_negative``|``enum UvNegative``|Multiplies X, Y or X & Y *-1.|``DISABLED``|
|-|-|-|-|
|``fallback_resolution``|``Vector2i``| Resolution used if no image was found at ``paint_on_texture_path``.|``Vector2i(1024,1024)``|
|``fallback_image_format``|``Image.Format``| Format used if no image was found at ``paint_on_texture_path``.|``Image.FORMAT_RGBA8``|

### Methods

#### **paint()**

**Signatur:** *paint(collision_point: Vector3, face_index: int, _color: Color = Color.BLACK)*\
**Returns:** void

> [!Tip]
> Used with a RayCast3D.

| **Input Parameters** |**Type**| **Description** |
|-|-|-|
|``collision_point``|``Vector3``|Collision Point gotten from a RayCast3D collision, where the function should paint.|
|``face_index``|``Vector3``|Collision face index gotten from a RayCast3D collision.|
|``_color``|``Color``|Color to paint with. Defaults to black.|

## Node: MeshPaintBrush

This node inherited from [**RayCast3D**](https://docs.godotengine.org/en/stable/classes/class_raycast3d.html) & *can* be used to paint on a **PaintableMesh**.

By default it will cast from the active [**Camera3D**](https://docs.godotengine.org/en/stable/classes/class_camera3d.html) <ins>forward</ins> at mouse cursor position.
Though, you can unlock this behavior by ticking *'Use Custom Ray'* to set its ``position`` & ``target_position`` manually.

| **Property**|**Type**| **Description**| **Default** |
|-|-|-|-|
|``brush_size``|``int``| Size of the brush.| ``64``|
|``brush_color``|``Color``| Color of the bursh. |``Color.BLACK``|
|-|-|-|-|
|``brush_texture``|``Texture2D``|Flipping/Mirror mode used for the UV map.|*DefaultBrush*|
|-|-|-|-|
|``use_custom_ray``|``bool``|If ``true``, ``position`` & ``target_position`` can be set manually.  |``false``|
|``ray_length_multiplier``|``float``|Multiplierer for the default ray.|``2.0``|
|-|-|-|-|
|``use_custom_input_action``|``bool``| Whether or not to use ``custom_input_action`` for painting.|``false``|
|``custom_input_action``|``String``|A in the [Input Map](https://docs.godotengine.org/en/4.4/classes/class_inputmap.html) defined [InputEventAction](https://docs.godotengine.org/en/4.4/classes/class_inputeventaction.html) to use for painting, when ``use_custom_input_action`` is ``true``.   |``"ui_select"``|

## Example Workflow

1. Add a **PaintableMesh** & a **MeshPaintBrush** to the scene.
2. In **MeshPaintBrush**: Set Brush Size, Color & Texture to your liking.<sup>(or just use the default)</sup>
3. In **PaintableMesh**: add your Mesh, Material & specify your 'Paint on Material' & 'Paint on Texture Path'.<sup>(or just use the default)</sup>
4. Start the game. You should now be able to paint with your brush on the mesh.

> [!IMPORTANT]
> The 'Paint on Texture Path' is the path relative to your selected 'Paint on Material'.
> E.g.: You want to paint on your Material Overlays, Next Pass, Albedo Texture?
> Select 'Paint on Material': MATERIAL_OVERLAY & type next_pass/albedo_texture in 'Paint on Texture Path'
