extends CharacterBody2D

const SPEED : float = 150.0
const FALL_AWAY_SPEED : float = 75.0
const FALL_SPEED : float = 300.0
const JUMP_POWER : float = 300.0
const START_WALKING_FRAMES : int = 2
const CROUCH_DIMENSIONS : Vector2 = Vector2(18.0, 15.0)

@onready var sprite : AnimatedSprite2D = $"Sprite"
@onready var body_coll : CollisionShape2D = $"Body Collision"
@onready var grab_coll : CollisionShape2D = $"Grab Collision"
@onready var ray : RayCast2D = $"Ray"
@onready var standing_pos : Vector2 = $"Body Collision".position
@onready var standing_size : Vector2 = $"Body Collision".shape.size

enum Action {
	STANDING,
	TURNING,
	START_WALKING,
	WALKING,
	START_JUMPING,
	JUMPING,
	FALLING,
	GRABBING,
	LEDGE_CLIMB,
	START_STANDING,
	START_CROUCHING,
	CROUCHING,
	START_CRAWLING,
	CRAWLING
}

var action : Action = Action.STANDING
var intent_dir : int = 1
var facing_dir : int = 1
var air_dir : int = 0
var animation_done : bool = true
var falling_open_wall : bool = true
var last_y : float = 0.0
var do_movement : bool = true

func set_facing_dir(dir : int):
	facing_dir = dir
	grab_coll.position.x = absf(grab_coll.position.x) * dir
	grab_coll.shape.b.x = absf(grab_coll.shape.b.x) * dir
	ray.position = grab_coll.position
	ray.target_position.x = grab_coll.shape.b.x

func stand_anim(dir : int):
	action = Action.STANDING
	air_dir = 0
	if dir > 0:
		sprite.play(&"Standing R")
	else:
		sprite.play(&"Standing L")

func walk_anim(dir : int):
	action = Action.WALKING
	air_dir = dir
	if dir > 0:
		sprite.play(&"Walking R")
	else:
		sprite.play(&"Walking L")
	sprite.set_frame_and_progress(START_WALKING_FRAMES, 0.0)

func start_walk_anim(dir : int):
	action = Action.START_WALKING
	animation_done = false
	if dir > 0:
		sprite.play(&"Start Walking R")
	else:
		sprite.play(&"Start Walking L")

func turn_anim(dir : int):
	action = Action.TURNING
	animation_done = false
	if dir > 0:
		sprite.play(&"Turning")
	else:
		sprite.play_backwards(&"Turning")

func jump_anim(dir : int):
	action = Action.START_JUMPING
	animation_done = false
	if dir > 0:
		sprite.play(&"Jumping R")
	else:
		sprite.play(&"Jumping L")

func fall_anim(dir : int):
	action = Action.FALLING
	ray.enabled = true
	if dir > 0:
		sprite.play(&"Falling R")
	else:
		sprite.play(&"Falling L")

func grab_anim(dir : int):
	action = Action.GRABBING
	if dir > 0:
		sprite.play(&"Grabbing R")
	else:
		sprite.play(&"Grabbing L")

func ledge_climb_anim(dir : int):
	action = Action.LEDGE_CLIMB
	animation_done = false
	if dir > 0:
		sprite.play(&"Ledge Climb R")
	else:
		sprite.play(&"Ledge Climb L")

func start_crouch_anim(dir : int):
	action = Action.START_CROUCHING
	animation_done = false
	if dir > 0:
		sprite.play(&"Start Crouch R")
	else:
		sprite.play(&"Start Crouch L")

func crouch_anim(dir : int):
	action = Action.CROUCHING
	if dir > 0:
		sprite.play(&"Crouch R")
	else:
		sprite.play(&"Crouch L")

func crouch_check(dir : int):
	# disable grab collider
	# needed for climbing up in to a crouch
	grab_coll.disabled = true
	# store original values
	var orig_pos : Vector2
	if action == Action.LEDGE_CLIMB:
		# try placing self in new position for climbing up
		orig_pos = position
		position += ray.position + ray.target_position
	var orig_coll_pos : Vector2 = body_coll.position
	var orig_size : Vector2 = body_coll.shape.size
	# set new values
	body_coll.position = Vector2(0.0, CROUCH_DIMENSIONS.y / -2.0)
	body_coll.shape.size = CROUCH_DIMENSIONS
	# check collision at the new location
	var coll : KinematicCollision2D = move_and_collide(Vector2.ZERO)
	if coll == null:
		# no collision
		# transition to crouching
		if action == Action.LEDGE_CLIMB:
			# transition from climb up animation
			# just go straight to the crouch position
			crouch_anim(dir)
		else:
			# transition from standing
			# transition through crouching animation
			start_crouch_anim(dir)
	else:
		# collision
		# restore collision
		body_coll.position = orig_coll_pos
		body_coll.shape.size = orig_size
		if action == Action.LEDGE_CLIMB:
			position = orig_pos
			grab_coll.disabled = false
			grab_anim(dir)
		# don't change anim/action

func start_stand_anim(dir : int):
	action = Action.START_STANDING
	animation_done = false
	if dir > 0:
		sprite.play(&"Start Standing R")
	else:
		sprite.play(&"Start Standing L")

func stand_check(dir : int):
	# disable grab collider
	grab_coll.disabled = true
	var orig_pos : Vector2
	if action == Action.LEDGE_CLIMB:
		# try placing self in new position
		orig_pos = position
		position += ray.position + ray.target_position
	var orig_coll_pos : Vector2 = body_coll.position
	var orig_coll_size : Vector2 = body_coll.shape.size
	body_coll.position = standing_pos
	body_coll.shape.size = standing_size
	# check collision at the new location
	var coll : KinematicCollision2D = move_and_collide(Vector2.ZERO)
	if coll == null:
		# no collision
		# transition to standing
		start_stand_anim(dir)
	else:
		# collision
		if action == Action.LEDGE_CLIMB:
			# crouch failed
			# move player back and regrab
			position = orig_pos
			body_coll.position = orig_coll_pos
			body_coll.shape.size = orig_coll_size
			grab_coll.disabled = false
			grab_anim(dir)
		# try transitioning to a crouch
		crouch_check(dir)

func _on_sprite_animation_finished() -> void:
	animation_done = true

func _ready():
	stand_anim(facing_dir)

func transition_animation(grounded : bool,
						 pressed_dir : int,
						 can_turn : bool,
						 can_drop : bool,
						 next_anim : Callable,
						 cancel_anim : Callable):
	if grounded:
		if animation_done:
			if pressed_dir != 0 and pressed_dir != intent_dir:
				# pressed the opposite direction
				if can_turn:
					intent_dir = pressed_dir
					turn_anim(intent_dir)
				elif can_drop:
					fall_anim(facing_dir)
			else:
				set_facing_dir(intent_dir)
				if pressed_dir == intent_dir:
					# still pressing the same direction
					next_anim.call(facing_dir)
				else:
					# stopped pressing the direction
					cancel_anim.call(facing_dir)
	else:
		# ground fell out from underneath
		animation_done = true
		fall_anim(facing_dir)

func _physics_process(delta : float):
	var pressed_dir : int = 0
	var jumping : bool = false
	var grounded : bool = is_on_floor()
	var hit_wall : bool = is_on_wall()
	var grabbing : bool = false

	if not grab_coll.disabled:
		for i in get_slide_collision_count():
			var coll : KinematicCollision2D = get_slide_collision(i)
			if coll.get_local_shape() == grab_coll:
				grabbing = true
				break

	if grounded or grabbing:
		velocity.y = 0.0

	if Input.is_action_pressed(&"move_right"):
		pressed_dir += 1
	elif Input.is_action_pressed(&"move_left"):
		pressed_dir -= 1

	if Input.is_action_pressed(&"jump"):
		jumping = true

	velocity.x = 0.0
	match action:
		Action.STANDING:
			if grounded:
				if jumping:
					# jump
					jump_anim(facing_dir)
				elif Input.is_action_just_pressed(&"crouch"):
					crouch_check(facing_dir)
				elif pressed_dir != 0:
					if pressed_dir != facing_dir:
						# pressed in opposite direction: turn
						intent_dir = pressed_dir
						turn_anim(intent_dir)
					else:
						# pressed in same direction: walk
						start_walk_anim(facing_dir)
			else:
				# fall
				fall_anim(facing_dir)
		Action.TURNING:
			transition_animation(grounded,
								pressed_dir,
								true, false,
								start_walk_anim,
								stand_anim)
		Action.START_WALKING:
			transition_animation(grounded,
								pressed_dir,
								true, false,
								walk_anim,
								stand_anim)
		Action.WALKING:
			if grounded:
				if jumping:
					# jump
					jump_anim(facing_dir)
				elif pressed_dir == 0:
					# stop
					stand_anim(facing_dir)
				elif pressed_dir != facing_dir:
					# turn
					intent_dir = pressed_dir
					turn_anim(intent_dir)
				else:
					# continue walking
					velocity.x = SPEED * facing_dir
			else:
				# fall
				fall_anim(facing_dir)
		Action.START_JUMPING:
			if grounded:
				if jumping:
					if animation_done:
						action = Action.JUMPING
						velocity.y = -JUMP_POWER
				else:
					stand_anim(facing_dir)
			else:
				# ground fell out from underneath
				animation_done = true
				fall_anim(facing_dir)
		Action.JUMPING:
			if hit_wall:
				air_dir = 0
			velocity.x = FALL_AWAY_SPEED * air_dir
			if velocity.y > 0.0:
				# initializa the correct value at the peak
				# raycasting is disabled at this point, so force the update
				ray.force_raycast_update()
				if ray.is_colliding():
					# blocked
					falling_open_wall = false
				else:
					# open
					falling_open_wall = true
				last_y = position.y
				fall_anim(facing_dir)
		Action.FALLING:
			if hit_wall:
				air_dir = 0
			if grounded:
				# landed on ground
				stand_anim(facing_dir)
			else:
				# falling
				#ray.force_raycast_update()
				if ray.is_colliding():
					# blocked
					if falling_open_wall:
						# transition from open to blocked
						# grab

						# Find where on the ground the player hit
						var orig_pos : Vector2 = ray.position
						var orig_target : Vector2 = ray.target_position
						# search starting from where the player fell from to here
						# at the "hand" position
						ray.position = orig_pos + Vector2(orig_target.x, last_y - position.y)
						ray.target_position = Vector2(0.0, position.y - last_y)
						ray.force_raycast_update()
						if ray.is_colliding():
							# move the player to the found position relative to the hand position
							var collision_pos : Vector2 = ray.get_collision_point()
							position = collision_pos - (orig_pos + orig_target)

							# place the collider to keep the player in place
							grab_coll.disabled = false
							grab_anim(facing_dir)
						# restore the ray
						ray.position = orig_pos
						ray.target_position = orig_target
					falling_open_wall = false
				else:
					# open
					falling_open_wall = true
				velocity.x = FALL_AWAY_SPEED * air_dir
				last_y = position.y
		Action.GRABBING:
			if grabbing:
				# still grabbing
				if (facing_dir < 0 and Input.is_action_just_pressed(&"move_left")) or \
				   (facing_dir > 0 and Input.is_action_just_pressed(&"move_right")):
					# pressing towards ledge
					# start climbing up
					ledge_climb_anim(facing_dir)
				elif (facing_dir > 0 and Input.is_action_just_pressed(&"move_left")) or \
					 (facing_dir < 0 and Input.is_action_just_pressed(&"move_right")) or \
					 Input.is_action_just_pressed(&"jump"):
					# pressing away from ledge
					# let go
					fall_anim(facing_dir)
					grab_coll.disabled = true
			else:
				grab_coll.disabled = true
				if grounded:
					# still on ground, but not holding on
					stand_anim(facing_dir)
				else:
					# no longer grabbing nor on ground
					fall_anim(facing_dir)
		Action.LEDGE_CLIMB:
			transition_animation(grabbing,
								pressed_dir,
								false, true,
								stand_check,
								grab_anim)
		Action.START_STANDING:
			transition_animation(grounded,
								 pressed_dir,
								 false, false,
								 stand_anim,
								 stand_anim)
		Action.START_CROUCHING:
			transition_animation(grounded,
								 pressed_dir,
								 false, false,
								 crouch_anim,
								 crouch_anim)
		Action.CROUCHING:
			if grounded:
				if Input.is_action_just_pressed(&"climb_up"):
					stand_check(facing_dir)
				elif pressed_dir != 0:
					if pressed_dir != facing_dir:
						# pressed in opposite direction: turn
						pass
					else:
						# pressed in same direction: crawl
						pass
			else:
				# fall
				fall_anim(facing_dir)

	# always apply gravity, many grounded/grabbing checks depend on this.
	velocity.y += FALL_SPEED * delta

	move_and_slide()
