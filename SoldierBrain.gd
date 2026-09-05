extends AIController3D
class_name SoldierBrain

# REFERENCES
@onready var player = get_parent()
@onready var sensors = player.get_node("Sensors")

# SETTINGS
var move_speed = 5.0
var turn_speed = 4.0

# --- 1. DEFINING THE BUTTONS (The Missing Piece) ---
func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 4, # 0=Forward, 1=Left, 2=Right, 3=Shoot
			"action_type": "discrete"
		}
	}

# --- 2. THE EYES (Observation) ---
func get_obs() -> Dictionary:
	var obs = []
	
	# Raycasts
	if sensors:
		for ray in sensors.get_children():
			if ray.is_colliding():
				var dist = player.global_position.distance_to(ray.get_collision_point())
				obs.append(clamp(dist / 20.0, 0.0, 1.0))
			else:
				obs.append(1.0)
	
	# Health
	obs.append(player.health / 100.0)
	
	# Radar to Zombie
	if player.zombie_ref and is_instance_valid(player.zombie_ref):
		var dir = player.to_local(player.zombie_ref.global_position).normalized()
		obs.append(dir.x)
		obs.append(dir.z)
	else:
		obs.append(0.0)
		obs.append(0.0)
		
	# Fill remaining slots to keep size constant (needs 15 total usually)
	while obs.size() < 15:
		obs.append(0.0)
		
	return {"obs": obs}

# --- 3. THE REWARD ---
func get_reward() -> float:
	reward = -0.01 # Time penalty
	
	if player.get("just_hit_enemy"):
		reward += 10.0
		player.just_hit_enemy = false
		
	return reward

# --- 4. THE ACTIONS ---
func set_action(action) -> void:
	var move_idx = action["move"]
	player.velocity = Vector3.ZERO
	
	if move_idx == 0: # Forward
		var dir = -player.global_transform.basis.z
		player.velocity = dir * move_speed
	elif move_idx == 1: # Left
		player.rotate_y(turn_speed * 0.1)
	elif move_idx == 2: # Right
		player.rotate_y(-turn_speed * 0.1)
	elif move_idx == 3: # Shoot
		_try_shoot()
	
	player.move_and_slide()

func _try_shoot():
	var space_state = player.get_world_3d().direct_space_state
	
	# 1. FIND THE MUZZLE
	# We look for the node named "Muzzle" inside "SoldierModel"
	var muzzle = player.get_node_or_null("SoldierModel/Gun/Muzzle") 
	
	var from = Vector3.ZERO
	var dir = -player.global_transform.basis.z # Default forward direction

	if muzzle:
		# If we found the muzzle, shoot from there!
		from = muzzle.global_position
		dir = -muzzle.global_transform.basis.z 
	else:
		# Fallback (Just in case the marker is missing)
		from = player.global_position + Vector3(0, 1.5, 0)

	# 2. SHOOT
	# 20.0 is the range of the sniper (20 meters)
	var to = from + (dir * 20.0)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true 
	query.collide_with_bodies = true
	# Don't shoot yourself
	query.exclude = [player.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# VISUAL DEBUG: Draw the laser so you can see it!
		if player.get_node_or_null("DebugDraw"):
			player.get_node("DebugDraw").draw_bullet(from, result.position)
		
		# LOGIC: Check if we hit a zombie
		if "Zombie" in result.collider.name:
			player.just_hit_enemy = true
			print("BANG! Sniper hit target!")
