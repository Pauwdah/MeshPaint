class_name Player
extends CharacterBody3D
## This class handles all player relevant logic.

static var singleton

@export var DEFAULT_SPEED: float = 5.0
@export var GRAVITY: float = 9.8
@export var CAM: Camera3D
@export var COLLIDER: CollisionShape3D


func _ready():
	singleton = self


func _physics_process(delta):
		apply_gravity(delta)
		apply_movement()
		move_and_slide()


func apply_gravity(delta):
# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	

func _input(event):
		# Mouse Mode
		if event is InputEventMouseButton:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		elif event.is_action_pressed("ui_cancel"):
			print("Player: I own Controller.")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# Camera
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				if event is InputEventMouseMotion:
					rotate_y(-event.relative.x * 0.01)
					CAM.rotate_x(-event.relative.y * 0.01)
					CAM.rotation.x = clamp(CAM.rotation.x, deg_to_rad(-60), deg_to_rad(80))
		

## Applies movement relative to the look direction of the Camera.
func apply_movement():
	var direction = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x

	direction.y = 0
	direction = direction.normalized()

	var horizontal_velocity = direction * DEFAULT_SPEED
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z


func reset():
	position = Vector3.ZERO
	rotation_degrees = Vector3.ZERO
