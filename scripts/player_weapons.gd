extends Node

# VARIABLES --------------------------------------------------------------------
enum WEAPON_POSITION {
	RIGHT_HAND, LEFT_HAND,
	RIGHT_BACK, LEFT_BACK
}

# REFERENCES -------------------------------------------------------------------
@onready var barrel_right_hand: Node3D = $"../mesh/weapon_barrels/barrel_right-hand"
@onready var barrel_left_hand:  Node3D = $"../mesh/weapon_barrels/barrel_left-hand"
@onready var barrel_right_back: Node3D = $"../mesh/weapon_barrels/barrel_right-back"
@onready var barrel_left_back:  Node3D = $"../mesh/weapon_barrels/barrel_left-back"
@onready var cam: Camera3D = $"../cam_pivot/cam_arm/cam"

# PRELOADS ---------------------------------------------------------------------
@onready var prefab_bullet: PackedScene = preload("res://bullet.tscn")


# CODE -------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_right_hand"):
		fire_weapon(WEAPON_POSITION.RIGHT_HAND)
	if event.is_action_pressed("weapon_left_hand"):
		fire_weapon(WEAPON_POSITION.LEFT_HAND)
	if event.is_action_pressed("weapon_right_back"):
		fire_weapon(WEAPON_POSITION.RIGHT_BACK)
	if event.is_action_pressed("weapon_left_back"):
		fire_weapon(WEAPON_POSITION.LEFT_BACK)
		

func fire_weapon(weapon_pos: WEAPON_POSITION):
	var barrel: Node3D = barrel_right_hand
	if weapon_pos == WEAPON_POSITION.LEFT_HAND:
		barrel = barrel_left_hand
	if weapon_pos == WEAPON_POSITION.RIGHT_BACK:
		barrel = barrel_right_back
	if weapon_pos == WEAPON_POSITION.LEFT_BACK:
		barrel = barrel_left_back
	
	var bullet_instance: Area3D = prefab_bullet.instantiate()
	bullet_instance.position = barrel.global_position
	bullet_instance.rotation = cam.global_rotation
		
	get_parent().get_parent().add_child(bullet_instance)
