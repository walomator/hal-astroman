extends "framework/character.gd"

var debug = false

#var fireball_scene = preload("res://scenes/effects/Fireball.tscn")

var idle_sprite_node # Safe to initialize in the _ready() function
var move_anim_node
var fall_anim_node
#var scoreboard_node
var collision_handler_node
var center_box_node
var global_node
var root_node

signal exited_center_box
signal attacked_enemy
#signal bumped_enemy
#signal body_collided
signal shutdown

var direction = 0 # 0 = stationary, 1 = right, -1 = left
var last_direction = 1 # The direction last moved, or the facing direction
var start_pos_x = 38 # DEV - Make single vector
var start_pos_y = 17
var run_speed = 0
var is_moving = false # Running implies specifically FAST running, to be considered if there will be multiple speeds
#var item_1 = "hookshot"

const MAX_RUN_SPEED    = 195
const MAX_VELOCITY     = 400 # Adjustment from MAX_VELOCITY of character.gd class
const JUMP_FORCE       = 260
const BOUNCE_FORCE     = 200 # FEAT - Should be enemy-specific
#const GRAVITY          = 400 # Opposes jump force
const HURT_FORCE       = 80
const STUN_TIME        = 0.5
const MAX_HEALTH       = 3
const GROUND_DRAG      = 300
const AIR_ACCELERATION = 4

var jump_count = 0
var max_jump_count = 2

const ActionHolder = preload("res://scripts/framework/action_holder.gd")
var action

# State machine possible states.
const StandingState = preload("res://scripts/states/StandingState.gd")
const RunningState  = preload("res://scripts/states/RunningState.gd")
const JumpingState  = preload("res://scripts/states/JumpingState.gd")
const SkiddingState  = preload("res://scripts/states/SkiddingState.gd")
#const StunnedState  = preload("res://scripts/states/StunnedState.gd")
var state = StandingState.new(self)

func _ready():
	_set_health(MAX_HEALTH)
	_set_is_weighted(true)
	
	var path_to_player_node = "/root/World/Player/"
#	var path_to_scoreboard_node = "/root/World/Scoreboard/"
	var path_to_collision_handler_node = "/root/World/CollisionHandler/"
	var path_to_center_box_node = "/root/World/CenterBox/"
	var path_to_global_node = "/root/Global/"
	var idle_sprite_node_name = "IdleSprite/"
	var move_anim_node_name = "RunAnim/"
	var fall_anim_node_name = "FallAnim/"
	
	idle_sprite_node       = get_node(path_to_player_node + idle_sprite_node_name)
	move_anim_node         = get_node(path_to_player_node + move_anim_node_name)
	fall_anim_node         = get_node(path_to_player_node + fall_anim_node_name)
#	scoreboard_node        = get_node(path_to_scoreboard_node)
	collision_handler_node = get_node(path_to_collision_handler_node)
	global_node            = get_node(path_to_global_node)
	root_node              = get_node("/root/")
	center_box_node        = get_node(path_to_center_box_node)
	
	root_node.call_deferred("add_child", center_box_node) # DEV - This should be handled elsewhere
	self.connect("body_collided", collision_handler_node, "handle_body_collided")
	self.connect("shutdown", global_node, "handle_shutdown")
	self.connect("exited_center_box", global_node, "handle_exited_center_box")
	
	action = ActionHolder.new()
	

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
	
#	if direction:
#		last_direction = direction
	
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
		state.jump()

	if event.is_action_pressed("reset"):
		reset_position()

#	if event.is_action_pressed("combat_action_1"):
#		launch_particle(item_1)

	if event.is_action_pressed("debug"):
		debug()
	

func set_state(new_state): # After initial call, only use state.set_state
	print(new_state)
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
	state.handle_timeout(timer_name)
	object_timer.queue_free()
	

func flip_sprite(is_flipped): # DEV - Should be part of character.gd
	idle_sprite_node.set_flip_h(is_flipped)
	move_anim_node.set_flip_h(is_flipped)
	fall_anim_node.set_flip_h(is_flipped)
	

func update_direction(): # Decides how to update sprite # DEV - Should be passed "direction"
	direction = 0
	if "right" in action.get_actions():
		direction += 1
	if "left" in action.get_actions():
		direction -= 1
	
	# DEV - This should be set by states
#	run_speed = MAX_RUN_SPEED * direction # This makes the next line seem redundant, and it is as long as there is no speed ramp
#	run_speed = min(abs(run_speed), MAX_RUN_SPEED) * direction # DEV - Hacky thing number 2, write this better
	
	if direction == 0:
		is_moving = false
	else:
		is_moving = true
	
	if direction:
		last_direction = direction
		
	if direction > 0:
		flip_sprite(false)
	if direction < 0:
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
#	direction = 0
#	action.clear()
#	update_direction()
	

func reset_position():
	self.position = Vector2(start_pos_x, start_pos_y)
	state.set_state("StandingState")
	reset_velocity()
	

func default_jump():
	if jump_count < max_jump_count:
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
#	particle.set_direction(last_direction)
#	particle.set_spawner(self)
#	particle.set_global_pos(self.position) # BUG - Not centered
	

func debug():
	print("state: ", state.get_name())
	var ground_collision = test_move(get_transform(), -GRAVITY_NORMAL)
	print(ground_collision)
	

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
	