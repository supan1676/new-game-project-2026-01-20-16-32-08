extends CharacterBody3D

# --- NODES ---
@onready var ai_controller = $AIController3D
@onready var sensors_container = $Sensors

# --- VARIABLES ---
var health = 100.0
var max_health = 100.0
var move_speed = 5.0
var ammo = 30 # Added (Brain needs this)

# --- CRITICAL FIXES FOR AI ---
var just_hit_enemy: bool = false  # <--- FIXED: The variable causing the crash
var zombie_ref: Node3D = null     # <--- FIXED: Needed for "Sixth Sense"
var took_damage_this_frame = false 

func _ready():
	# --- CRITICAL FIX: FORCE THE CORRECT SCRIPT ---
	if ai_controller:
		# Use the ResourceLoader to find the script safely
		var correct_brain_script = load("res://SoldierBrain.gd")
		
		# If the node has the wrong script, we force-swap it right here
		if ai_controller.get_script() != correct_brain_script:
			print("WARNING: AIController had the wrong script. Forcing swap to SoldierBrain.gd...")
			ai_controller.set_script(correct_brain_script)
		
		# Initialize the brain manually just in case
		if ai_controller.has_method("init"):
			ai_controller.init(self)
			
		print("SOLDIER: Brain Initialized Successfully!")
	else:
		printerr("ERROR: AIController3D node not found inside Soldier!")

func _physics_process(delta):
	took_damage_this_frame = false
	
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

# --- COMMANDS (Called by the Brain) ---
func apply_ai_movement(action_array):
	# This function acts as a backup if the Brain calls it directly
	var forward_val = action_array[0]
	var turn_val = action_array[1]
	
	rotate_y(turn_val * 0.1)
	
	var dir = transform.basis.z * forward_val
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	move_and_slide()

func take_damage(amount):
	health -= amount
	took_damage_this_frame = true
	if health < 0: health = 0
