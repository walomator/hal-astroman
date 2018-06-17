extends "res://scripts/framework/State.gd"

# This state describes when a player has been stunned. It is up to an
# externally set timer to release the player from this state.

var stun_time
var old_state_name

func _init(controlled_player, player_stun_time, player_old_state_name):
	player = controlled_player
	stun_time = player_stun_time
	old_state_name = player_old_state_name
	player.set_controller_velocity(Vector2(0, 0))
	

func start():
	set_state_name("StunnedState")
	player.idle_sprite_node.visible = true
	player.start_timer("unstun", stun_time)
	

func state_process(delta):
	player.drag(player.GROUND_DRAG, delta)
	

func handle_timeout(timer_name): # Called by timer after it times out
	if timer_name == "unstun":
		set_state(old_state_name) # DEV - This could possibly be problematic if other state is also timer-based
	

func set_state(new_state):
	if exiting == true:
		return
	exiting = true
	
	player.idle_sprite_node.visible = false
	player.set_state(new_state)
	

func jump():
	pass
	

func get_name():
	return state_name
