extends CharacterBody3D

# EXPORTS ----------------------------------------------------------------------
@export_group("Camera")
## Sensititivy of the camera based on mouse movement
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25
## Maximum tilt angle in degrees of the camera when moving side to side in boost mode
@export var cam_max_tilt: 		 float = 5.0
## Speed at which the camera tilts from side to side in boost mode
@export var cam_tilt_speed: 	 float = 3.0
## Minimum distance of the camera when in walk mode
@export var cam_walk_distance: 	 float = 2.5
## Minimum distance of the camera when in boost mode
@export var cam_boost_distance:  float = 3.5
## Maximum distance of the camera
@export var cam_max_distance: 	 float = 5.0
## Speed at which the camera moves towards it's current minimum distance
@export var cam_arm_speed: 		 float = 1.5
## The follow speed of the camera during boost mode or flight
@export var cam_boost_speed: 	 float = 30.0
## Vertical offset of the camera from the player origin
@export var cam_vertical_offset: float = 2.5

@export_group("Movement")
## Speed of the player in walking mode
@export var walk_speed: 		float = 8.0
## Speed of the player in boosting mode
@export var boost_speed: 		float = 25.0
## Acceleration of the player movement
@export var acceleration: 		float = 50.0
## Speed of the player's quick boost
@export var quick_boost_speed: 	float = 30.0
## Rotation speed of the player character's mesh
@export var rotation_speed: 	float = 12.0
## Vertical impulse used in jumping
@export var jump_impulse: 		float = 25.0
## Vertical impulse used in flight
@export var flight_impulse: 	float = 25.0
## Vertical downward decelleration applied to the player as gravity
@export var gravity:			float = -30.0

@export_group("Cooldowns")
@export var flight_delay_time: 		float = 0.5
@export var quick_boost_delay_time: float = 0.5

# VARIABLES --------------------------------------------------------------------
var cam_input_direction: 	 Vector2 = Vector2.ZERO
var last_movement_direction: Vector3 = Vector3.BACK
var is_boost_mode: 	bool = false
var is_targeting:	bool = false

# REFERENCES -------------------------------------------------------------------
@onready var cam_pivot: 	Node3D = $cam_pivot
@onready var cam_arm: 		SpringArm3D = $cam_pivot/cam_arm
@onready var cam: 			Camera3D = $cam_pivot/cam_arm/cam
@onready var mesh: 			MeshInstance3D = $mesh
@onready var flight_delay: 	Timer = $flight_delay
@onready var qb_delay: 		Timer = $qb_delay
@onready var target_delay: 	Timer = $target_delay


# CODE -------------------------------------------------------------------------
func _ready() -> void:
	cam_arm.spring_length = cam_walk_distance
	flight_delay.wait_time = flight_delay_time
	qb_delay.wait_time = quick_boost_delay_time
	
	# stop cam pivot from being locked to player position
	cam_pivot.set_as_top_level(true)

func _input(event: InputEvent) -> void:
	# mouse capturing
	if event.is_action_pressed("lmb"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("option_quit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	# movement mode switching
	if event.is_action_pressed("move_mode"):
		if is_boost_mode and velocity.length() < 0.1:
			is_boost_mode = false
		else:
			is_boost_mode = true
			
	# detect weapon usage
	var has_fired = (
		event.is_action_pressed("weapon_right_hand") or
		event.is_action_pressed("weapon_left_hand")  or
		event.is_action_pressed("weapon_right_back") or
		event.is_action_pressed("weapon_left_back")
	)
	if has_fired:
		is_targeting = true
		target_delay.start()


func _unhandled_input(event: InputEvent) -> void:
	# handle camera movement input
	var is_camera_motion: bool = (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		cam_input_direction = event.screen_relative * mouse_sensitivity
	

func _physics_process(delta: float) -> void:
	# camera follow ------------------------------------------------------------
	var cam_target_pos = global_position + Vector3(0, cam_vertical_offset, 0)
	if is_boost_mode or not is_on_floor():
		cam_pivot.global_position = cam_pivot.global_position.lerp(
			cam_target_pos, cam_boost_speed * delta
		)
	else:
		cam_pivot.global_position = cam_target_pos
	
	# camera rotation ----------------------------------------------------------
	cam_pivot.rotation.x -= cam_input_direction.y * delta
	cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, -PI/6.0, PI/3.0)
	cam_pivot.rotation.y -= cam_input_direction.x * delta
	
	cam_input_direction = Vector2.ZERO
	
	if is_boost_mode:
		cam_arm.spring_length = lerp(
			cam_arm.spring_length, cam_boost_distance, cam_arm_speed * delta
		)
		
		# camera tilting in boost mode
		if Input.is_action_pressed("move_left"):
			cam.rotation.z = lerp_angle(
				cam.rotation.z, deg_to_rad(cam_max_tilt), cam_tilt_speed * delta
			)
		elif Input.is_action_pressed("move_right"):
			cam.rotation.z = lerp_angle(
				cam.rotation.z, -deg_to_rad(cam_max_tilt), cam_tilt_speed * delta
			)
		else:
			cam.rotation.z = lerp_angle(
				cam.rotation.z, 0, cam_tilt_speed * delta
			)
	else:
		cam_arm.spring_length = lerp(
			cam_arm.spring_length, cam_walk_distance, cam_arm_speed * delta
		)
	
	# movement -----------------------------------------------------------------
	# capture raw input and create movement direction vector
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
	
	# add velocities
	var y_velocity: float = velocity.y
	velocity.y = 0.0
	
	var move_speed: float = 0.0
	if is_boost_mode: move_speed = boost_speed
	else: move_speed = walk_speed
	
	velocity = velocity.move_toward(
		move_direction * move_speed,
		acceleration * delta
	)
	velocity.y = y_velocity + (gravity * delta)
	
	# quick boosting
	var can_boost: bool = (
		Input.is_action_just_pressed("move_boost") and 
		qb_delay.is_stopped()
	)
	if can_boost:
		velocity += (move_direction * quick_boost_speed)
		is_boost_mode = true
		qb_delay.start()
	
	# jumping and flight
	var is_starting_jump: bool = (
		Input.is_action_just_pressed("move_jump") and 
		is_on_floor()
	)
	if is_starting_jump:
		velocity.y += jump_impulse
		flight_delay.start()
	
	var is_flying: bool = (
		Input.is_action_pressed("move_jump") and 
		not is_on_floor() and
		flight_delay.is_stopped()
	)
	if is_flying:
		velocity.y = 0.0
		velocity.y += flight_impulse
	
	move_and_slide()
	
	# if player stops moving, turn off boost mode
	#if is_boost_mode and velocity.length() < 0.1:
		#is_boost_mode = false
	
	# mesh rotation
	var target_angle: float = 0.0
	if is_targeting:
		# get screen center
		var viewport_size = get_viewport().get_visible_rect().size
		var screen_center = viewport_size / 2
		
		# raycast from center of camera
		var ray_origin = cam.project_ray_origin(screen_center)
		var ray_end = ray_origin + cam.project_ray_normal(screen_center) * 1000.0 # 1000m range
		
		# check for hit
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		
		# exclude the player from hitting themselves
		query.exclude = [get_rid()]
		
		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(query)
		var target_point: Vector3
		if result: # snap to hit point
			target_point = result.position
		else: # hit nothing, snap to a point far in the distance
			target_point = ray_end
			
		# rotate mesh and update last_movement_direction
		var look_pos = Vector3(target_point.x, global_position.y, target_point.z)
		var direction_to_target = (look_pos - global_position).normalized()
		if global_position.distance_to(look_pos) > 0.1:
			target_angle = Vector3.BACK.signed_angle_to(
				direction_to_target, Vector3.UP
			)
			last_movement_direction = direction_to_target
	else: # rotate mesh to movement direction
		if move_direction.length() > 0.2:
			last_movement_direction = move_direction
		
		target_angle = Vector3.BACK.signed_angle_to(
			last_movement_direction, Vector3.UP
		)
		
	mesh.global_rotation.y = lerp_angle(
		mesh.rotation.y, target_angle, rotation_speed * delta
	)
	
	
func _on_target_delay_timeout() -> void:
	is_targeting = false
	
