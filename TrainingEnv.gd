extends Node3D

@onready var soldier = $Soldier
@onready var zombie = get_node_or_null("Zombie")

var time_elapsed = 0.0

func _ready():
	# Speed is 5.0 so we can see physics settle, but training is still fast
	Engine.time_scale = 5.0  
	
	if soldier and zombie:
		soldier.zombie_ref = zombie
		zombie.target = soldier
		# Add a flag to the soldier for shooting rewards
		soldier.set("just_hit_enemy", false)

func _physics_process(delta):
	time_elapsed += delta
	
	# CHECK 1: Did Zombie eat Soldier?
	if soldier and soldier.health <= 0:
		_end_episode()
		return

	# CHECK 2: Time Limit
	if time_elapsed > 10.0: # Short rounds for faster learning
		_end_episode()

func _end_episode():
	# 1. Tell Python "Game Over"
	if soldier.ai_controller:
		soldier.ai_controller.done = true
		soldier.ai_controller.needs_reset = true
	
	# 2. Reset Positions
	reset_positions()

func reset_positions():
	time_elapsed = 0.0
	
	if soldier:
		soldier.health = 100
		if soldier.ai_controller:
			soldier.ai_controller.zero_reward()
		
		# --- FIX: Stop falling forever ---
		soldier.velocity = Vector3.ZERO 
		
		# --- FIX: Spawn HIGH (Y=5.0) ---
		# Spawning at Y=1 often puts feet underground. Y=5 ensures he drops ON the floor.
		soldier.global_position = Vector3(randf_range(-10, 10), 5.0, randf_range(-10, 10))
		soldier.rotation.y = randf() * PI * 2
	
	# Move Zombie (Far away)
	if zombie:
		zombie.velocity = Vector3.ZERO
		var safe_pos = Vector3.ZERO
		while true:
			# Spawn Zombie HIGH UP too
			safe_pos = Vector3(randf_range(-10, 10), 5.0, randf_range(-10, 10))
			if safe_pos.distance_to(soldier.global_position) > 8.0:
				break
		zombie.global_position = safe_pos
