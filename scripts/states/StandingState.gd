extends "res://scripts/framework/State.gd"

var is_grounded = true # DEV - Not currently implemented, but may solve the jumping problem

func _init(controlled_player):
	player = controlled_player
	

func start():
	set_state_name("StandingState")
	player.idle_sprite_node.visible = true
	

func state_process(delta):
	if player.input_direction != 0:
		set_state("RunningState")
	
	if is_in_air():
		set_state("JumpingState")
	

func set_state(new_state):
	if exiting == true:
		return
	exiting = true
	
	player.idle_sprite_node.visible = false
	player.set_state(new_state)
	

func jump():
	player.default_jump()
	set_state("JumpingState")
	

func is_in_air():
	return not player.test_move(player.get_transform(), Vector2(0, 1))
	