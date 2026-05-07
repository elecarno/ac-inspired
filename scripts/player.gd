extends CharacterBody3D

const MOVE_SPEED = 25.0
const JUMP_VELOCITY = 15.0

@export var cam_sensitivity = 0.5
@onready var cam_pivot: Node3D = $cam_pivot

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * cam_sensitivity))
		cam_pivot.rotate_x(deg_to_rad(-event.relative.y * cam_sensitivity))
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("option_quit"):
		get_tree().quit()

	if not is_on_floor():
		# gravity
		velocity += get_gravity() * delta

	# handle jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# get input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
