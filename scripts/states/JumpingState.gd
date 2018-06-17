extends "res://scripts/framework/State.gd"

# This state describes any in which the player is in the air, including falling
# after running off a ledge. It is not limited to voluntarily jumping.

var is_grounded = true

func _init(controlled_player):
	player = controlled_player
	

func start():
	set_state_name("JumpingState")
	player.fall_anim_node.play()
	player.fall_anim_node.visible = true
	
	if player.jump_count == 0:
		player.jump_count = 1
	

func state_process(delta):
	# Set velocity caused by player input for handling by character.gd
	player.set_controller_velocity(Vector2(player.run_speed * player.direction, 0))
	
	if player.direction == 0:
		player.run_speed = 0 # FEAT - Don't allow sudden stopping in mid-air
	
	if is_on_ground():
		set_state("StandingState")
	

func set_state(new_state):
	if exiting == true:
		return
	exiting = true
	
	if new_state == "StandingState" or new_state == "RunningState":
		player.jump_count = 0
		
	player.fall_anim_node.stop()
	player.fall_anim_node.visible = false
	
	player.set_state(new_state)
	

func jump():
	player.default_jump()
	

func is_on_ground():
	var test = false
	if player.natural_velocity.y >= 0:
		test = player.test_move(player.get_transform(), Vector2(0, 1))
	return test