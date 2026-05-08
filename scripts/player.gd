extends CharacterBody3D

# EXPORTS ----------------------------------------------------------------------
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25

@export_group("Movement")
@export var move_speed: float = 25.0
@export var acceleration: float = 50.0
@export var rotation_speed: float = 12.0
@export var jump_impulse: float = 25.0
@export var gravity: float = -30.0

# VARIABLES --------------------------------------------------------------------
var cam_input_direction: Vector2 = Vector2.ZERO
var last_movement_direction: Vector3 = Vector3.BACK

# REFERENCES -------------------------------------------------------------------
@onready var cam_pivot: Node3D = $cam_pivot
@onready var cam: Camera3D = $cam_pivot/cam_arm/cam
@onready var mesh: MeshInstance3D = $mesh


# CODE -------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	# mouse capturing
	if event.is_action_pressed("lmb"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("option_quit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	# handle camera movement input
	var is_camera_motion: bool = (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		cam_input_direction = event.screen_relative * mouse_sensitivity
	

func _physics_process(delta: float) -> void:
	# camera rotation
	cam_pivot.rotation.x -= cam_input_direction.y * delta
	cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, -PI/6.0, PI/3.0)
	cam_pivot.rotation.y -= cam_input_direction.x * delta
	
	cam_input_direction = Vector2.ZERO
	
	# movement
	var raw_input: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var forward_vector: Vector3 = cam.global_basis.z
	var right_vector: Vector3 = cam.global_basis.x
	
	var move_direction: Vector3 = (
		forward_vector * raw_input.y + 
		right_vector * raw_input.x
	)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity: float = velocity.y
	velocity.y = 0.0
	velocity = velocity.move_toward(
		move_direction * move_speed,
		acceleration * delta
	)
	velocity.y = y_velocity + (gravity * delta)
	
	var is_starting_jump: bool = (
		Input.is_action_just_pressed("move_jump") and 
		is_on_floor()
	)
	if is_starting_jump:
		velocity.y += jump_impulse
	
	move_and_slide()
	
	# rotate mesh to movement direction
	if move_direction.length() > 0.2:
		last_movement_direction = move_direction
	
	var target_angle: float = Vector3.BACK.signed_angle_to(
		last_movement_direction, Vector3.UP
	)
	mesh.global_rotation.y = lerp_angle(
		mesh.rotation.y, target_angle, rotation_speed * delta
	)
	
