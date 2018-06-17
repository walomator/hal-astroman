extends "res://scripts/framework/State.gd"

# This state describes any in which the player is in the air, including falling
# after running off a ledge. It is not limited to voluntarily jumping.

const Effect = preload("res://scripts/framework/effect.gd")

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
	player.set_controller_velocity(Vector2(player.run_speed * player.facing_direction, 0))
	
#	if player.input_direction == 0: # Comment out if you want to block the player stopping mid-air
#		player.run_speed = 0
	
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