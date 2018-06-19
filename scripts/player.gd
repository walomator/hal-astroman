extends "framework/character.gd"

# Status constants
const MAX_HEALTH       = 3
const MAX_JUMP_COUNT   = 2
const KONAMI_CODE = ["up", "up", "down", "down", "left", "right", "left", "right"]

# Physics constants, with pixels as units of length and milliseconds as units of time
const GRAVITY          = 200
const MAX_RUN_SPEED    = 100
const ACCELERATION     = 300
const AIR_ACCELERATION = 100
const GROUND_DRAG      = 900
const JUMP_FORCE       = 170
const BOUNCE_FORCE     = 200 # FEAT - Should be enemy-specific
const HURT_FORCE       = 80
const STUN_TIME        = 0.5

# Movement-dependent variables
var input_direction = 0 # 0 = stationary, 1 = right, -1 = left
var facing_direction = 1 # The direction last moved
var run_speed = 0
var jump_count = 0

# State machine possible states.
const StandingState  = preload("res://scripts/states/StandingState.gd")
const RunningState   = preload("res://scripts/states/RunningState.gd")
const JumpingState   = preload("res://scripts/states/JumpingState.gd")
const SkiddingState  = preload("res://scripts/states/SkiddingState.gd")
const StunnedState  = preload("res://scripts/states/StunnedState.gd")
var state = StandingState.new(self)

# References to nodes typical to the scene
var idle_sprite_node
var move_anim_node
var fall_anim_node
var landing_anim_node
#var scoreboard_node
var collision_handler_node
var global_node
var root_node
var world_node

# Signals
signal exited_center_box
signal attacked_enemy
#signal bumped_enemy
#signal body_collided
signal shutdown

# External scripts
const ActionHolder = preload("res://scripts/framework/action_holder.gd")
var action

func _ready():
	_set_health(MAX_HEALTH)
	_set_is_weighted(true)
	
	var player_nodepath = "/root/World/Player/"
	idle_sprite_node       = get_node(player_nodepath + "IdleSprite/")
	move_anim_node         = get_node(player_nodepath + "RunAnim/")
	fall_anim_node         = get_node(player_nodepath + "FallAnim/")
	landing_anim_node      = get_node(player_nodepath + "LandingAnim/")
#	scoreboard_node        = get_node("/root/World/Scoreboard/")
	collision_handler_node = get_node("/root/World/CollisionHandler/")
	global_node            = get_node("/root/Global")
	root_node              = get_node("/root/")
	world_node             = get_node("/root/World/")
	
	self.connect("body_collided", collision_handler_node, "handle_body_collided")
	self.connect("shutdown", global_node, "handle_shutdown")
	self.connect("exited_center_box", global_node, "handle_exited_center_box")
	
	action = ActionHolder.new() # Holds the current keys being pressed
	

func _process(delta):
	state.state_process(delta)
	

func _physics_process(delta):
	for collision in get_char_collisions():
#		print("msg - ", collision, " in ", get_char_collisions())
		var colliding_body = collision.collider
		if colliding_body and (colliding_body.is_in_group("Enemies") or colliding_body.is_in_group("Hazards")): # FEAT - Should be "Collidables"
			handle_body_collided(colliding_body, collision.normal)
	

func _input(event):
	if event.is_action_pressed("shutdown"):
		emit_signal("shutdown")
	
	# Input
	if event.is_action_pressed("move_right"):
		action.add("right")
		update_direction()
	if event.is_action_pressed("move_left"):
		action.add("left")
		update_direction()
	if event.is_action_released("move_right"):
		action.remove("right")
		update_direction()
	if event.is_action_released("move_left"):
		action.remove("left")
		update_direction()

	if event.is_action_pressed("move_up"):
		action.update_history("up")
		state.jump()
	
	if event.is_action_pressed("move_down"):
		action.update_history("down")
#		state.duck() # FEAT - Not implemented yet

	if event.is_action_pressed("reset"):
		reset_position()

#	if event.is_action_pressed("combat_action_1"):
#		launch_particle(item_1)

	if event.is_action_pressed("debug"):
		debug()
		
	# Konami code proof of concept
	if action.history_equals(KONAMI_CODE):
		print("Konami would be proud.")
		action.clear_history()
		
	

func set_state(new_state): # After initial call, only use this function coupled with state-handled switching
	# DEV - These don't need to be instances right _now_
	var old_state = state
	if   new_state == "StandingState":
		state = StandingState.new(self)
	elif new_state == "RunningState":
		state = RunningState.new(self)
	elif new_state == "JumpingState":
		state = JumpingState.new(self)
#	elif new_state == "StunnedState":
#		state = StunnedState.new(self, STUN_TIME, old_state.state_name)
	elif new_state == "SkiddingState":
		state = SkiddingState.new(self)
	else:
		print("invalid state")
		
	state.start()
	old_state.queue_free()
	

func handle_timeout(object_timer, timer_name): # Called by a timer after it times out
	state.handle_timeout(timer_name) # DEV - How timers are used is confusing
	object_timer.queue_free()
	

func flip_sprite(is_flipped): # DEV - Should be part of character.gd
	idle_sprite_node.set_flip_h(is_flipped)
	move_anim_node.set_flip_h(is_flipped)
	fall_anim_node.set_flip_h(is_flipped)
	

func update_direction(): # Decides how to update sprite # DEV - Should be passed "direction"
	input_direction = 0
	if "right" in action.get_actions():
		input_direction += 1
	if "left" in action.get_actions():
		input_direction -= 1
	
#	if input_direction == 0: # DEV - Deprecated
#		is_moving = false
#	else:
#		is_moving = true
	
	if input_direction:
		facing_direction = input_direction
		
	if input_direction > 0:
		flip_sprite(false)
	if input_direction < 0:
		flip_sprite(true)
	

func bounce(bounce_force): # Should be called externally
	reset_velocity()
	increase_velocity(Vector2(0, -bounce_force))
	jump_count = 1
	

func reel(reel_force, normal):
	pass
#	state.set_state("StunnedState")
#	reset_velocity()
#	increase_velocity(Vector2(normal.x * reel_force, 0))
#	input_direction = 0
#	action.clear()
#	update_direction()
	

func reset_position():
	self.position = Vector2(38, 17)
	state.set_state("StandingState")
	reset_velocity()
	

func default_jump():
	if jump_count < MAX_JUMP_COUNT:
		reset_velocity()
		increase_velocity(Vector2(0, -JUMP_FORCE))
		jump_count += 1
		# FEAT - Variable jump length needed
	

func launch_particle(particle_type): # BUG - Causes crash
	pass
#	var particle = "null"
#	if particle_type == "fireball":
#		particle = fireball_scene.instance()
#	if particle_type == "hookshot":
#		particle = hookshot_scene.instance()
	
#	# DEV - This code limits usage of the launch_particle function
#	get_tree().get_root().add_child(particle)
#	particle.set_direction(facing_direction)
#	particle.set_spawner(self)
#	particle.set_global_pos(self.position) # BUG - Not centered
	

func debug():
	if world_node.current_map.name == "Map0":
		world_node.change_map("MapFlat.tscn")
	elif world_node.current_map.name == "MapFlat":
		world_node.change_map("Map0.tscn")

	reset_position()
	

func handle_body_collided(colliding_body, collision_normal): # DEV - This function name is misleading
	emit_signal("body_collided", self, colliding_body, collision_normal)
	

func handle_player_hit_enemy_top(player, enemy):
	emit_signal("attacked_enemy")
	bounce(enemy.get_bounciness())
	

func handle_player_hit_enemy_side(player, enemy, normal):
	# BUG - This is not triggered in some cases,
	# including when a player bounces on a slime, then collides with an enemy (a
	# platform) in the air. Occurs on map-test.
	reel(HURT_FORCE, normal)
	var damage = enemy.get_damage()
	_set_health(get_health() - damage)
	start_timer("unstun", STUN_TIME)
	

func handle_player_hit_hazard_top(player, hazard, normal):
	var damage = hazard.get_damage()
	_set_health(get_health() - damage)
	

func handle_player_hit_hazard_side(player, hazard, normal):
	pass # DEV - It should be in the code of the hazard whether sides hurt the player
	