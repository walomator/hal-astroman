extends "res://scripts/framework/State.gd"

#var speed = 0 # DEV - Deprecated, using player.run_speed instead

func _init(controlled_player):
	player = controlled_player
	

func start():
	set_state_name("RunningState")
	player.move_anim_node.play()
	player.move_anim_node.visible = true
	
	player.run_speed = 0
	

func state_process(delta):
	if player.input_direction == 0:
		if player._total_velocity.x == 0:
			set_state("StandingState")
		else:
			set_state("SkiddingState")
	
	if is_in_air():
		set_state("JumpingState")
	
	# Set velocity caused by player input for handling by character.gd
	if player.run_speed < player.MAX_RUN_SPEED:
		player.run_speed += player.ACCELERATION * delta
	else:
		player.run_speed = player.MAX_RUN_SPEED
	player.set_controller_velocity(Vector2(player.run_speed * player.facing_direction, 0))
	

func set_state(new_state):
	if exiting == true:
		return
	exiting = true
	
	player.move_anim_node.stop()
	player.move_anim_node.visible = false
	player.set_state(new_state)
	

func jump():
	player.default_jump()
	set_state("JumpingState")
	

func is_in_air():
	return not player.test_move(player.get_transform(), Vector2(0, 1))
	