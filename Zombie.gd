extends CharacterBody3D

var speed = 4.5   # Slightly slower than soldier (who is 5.0)
var target: Node3D = null

func _physics_process(delta):
	if target:
		# 1. Look at the Soldier
		look_at(target.global_position, Vector3.UP, true)
		
		# 2. Calculate direction towards Soldier
		var direction = (target.global_position - global_position).normalized()
		
		# 3. Move
		velocity = direction * speed
		move_and_slide()
		
		# 4. Attack! (If touching)
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var body = collision.get_collider()
			if body.has_method("take_damage"):
				body.take_damage(5) # Deal damage
