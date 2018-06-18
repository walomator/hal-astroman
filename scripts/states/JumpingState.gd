extends "res://scripts/framework/State.gd"

# This state describes any in which the player is in the air, including falling
# after running off a ledge. It is not limited to voluntarily jumping.
# DEV - This should be two states, one for moving and one for staying still
# BUG - Hitting a wall doesn't reset the built-up velocity

const Effect = preload("res://scripts/framework/effect.gd")
var locked_direction

func _init(controlled_player):
	player = controlled_player
	

func start():
	set_state_name("JumpingState")
	player.fall_anim_node.play()
	player.fall_anim_node.visible = true
	
	if player.jump_count == 0:
		player.jump_count = 1
	
	locked_direction = player.facing_direction
	

func state_process(delta):
	# Allow player to turn around and reset speed
	if player.input_direction != locked_direction:
		player.run_speed = 0
		locked_direction = player.facing_direction
	
	# Set velocity caused by player input for handling by character.gd
	if player.run_speed < player.MAX_RUN_SPEED:
		player.run_speed += player.AIR_ACCELERATION * delta
	else:
		player.run_speed = player.MAX_RUN_SPEED
#	player.set_controller_velocity(Vector2(player.run_speed * locked_direction, 0))
	player.set_controller_velocity(Vector2(player.run_speed * player.input_direction, 0))
	
	if is_on_ground():
		set_state("StandingState")
	

func set_state(new_state):
	if exiting == true:
		return
	exiting = true
	
	if new_state == "StandingState" or new_state == "RunningState":
		player.jump_count = 0
		_land()
		if new_state == "StandingState":
			player.run_speed = 0
			player.set_controller_velocity(Vector2(0, 0))
		
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

func _land():
	var landing_effect = Effect.new()
	player.add_child(landing_effect)
	landing_effect.play_anim_once("LandingAnim")