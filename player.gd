extends CharacterBody2D

const SPEED : float = 150.0
const CRAWL_SPEED : float = 50.0
const AIR_SPEED : float = 200.0
const FALL_SPEED : float = 300.0
const JUMP_POWER : float = 300.0
const START_WALKING_FRAMES : int = 2

@onready var sprite : AnimatedSprite2D = $"Sprite"
@onready var standing_coll : CollisionShape2D = $"Standing Collision"
@onready var crouching_coll : CollisionShape2D = $"Crouching Collision"
@onready var grab_coll : CollisionShape2D = $"Grab Collision"
@onready var ray : RayCast2D = $"Ray"

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

# sentinel Callable to disable turning
func NO_TURN(_dir : int):
	pass

func crouching_collision():
	standing_coll.disabled = true
	crouching_coll.disabled = false

func standing_collision():
	standing_coll.disabled = false
	crouching_coll.disabled = true

func set_facing_dir(dir : int):
	facing_dir = dir
	grab_coll.position.x = absf(grab_coll.position.x) * dir
	grab_coll.shape.b.x = absf(grab_coll.shape.b.x) * dir
	ray.position = grab_coll.position
	ray.target_position.x = grab_coll.shape.b.x

func stand_anim(dir : int):
	action = Action.STANDING
	velocity.x = 0.0
	air_dir = 0
	if dir > 0:
		sprite.play(&"Standing R")
	else:
		sprite.play(&"Standing L")

func start_walk_anim(dir : int):
	action = Action.START_WALKING
	animation_done = false
	if dir > 0:
		sprite.play(&"Start Walking R")
	else:
		sprite.play(&"Start Walking L")

func walk_anim(dir : int):
	action = Action.WALKING
	air_dir = dir
	if dir > 0:
		sprite.play(&"Walking R")
	else:
		sprite.play(&"Walking L")
	sprite.set_frame_and_progress(START_WALKING_FRAMES, 0.0)

func turning_anim(dir : int):
	action = Action.TURNING
	velocity.x = 0.0
	animation_done = false
	if dir > 0:
		sprite.play(&"Turning")
	else:
		sprite.play_backwards(&"Turning")

func jump_anim(dir : int):
	action = Action.START_JUMPING
	velocity.x = 0.0
	animation_done = false
	if dir > 0:
		sprite.play(&"Jumping R")
	else:
		sprite.play(&"Jumping L")

func fall_anim(dir : int):
	action = Action.FALLING
	ray.enabled = true
	# could be falling from crawling
	standing_collision()
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
	velocity.x = 0.0
	if dir > 0:
		sprite.play(&"Crouch R")
	else:
		sprite.play(&"Crouch L")

func crouch_check(dir : int):
	# disable grab collider
	# needed for climbing up in to a crouch
	grab_coll.disabled = true
	# store original values
	var orig_pos : Vector2 = position
	if action == Action.LEDGE_CLIMB:
		# try placing self in new position for climbing up
		position += ray.position + ray.target_position
	crouching_collision()
	# check collision at the new location
	# do it twice because the player will be pushed away from walls the first time
	move_and_collide(Vector2.ZERO)
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
		standing_collision()
		position = orig_pos
		if action == Action.LEDGE_CLIMB:
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
	standing_collision()
	# check collision at the new location
	var coll : KinematicCollision2D = move_and_collide(Vector2.ZERO)
	if coll == null:
		# no collision
		# transition to standing
		start_stand_anim(dir)
	else:
		# collision
		crouching_collision()
		if action == Action.LEDGE_CLIMB:
			# crouch failed
			# move player back and try other things
			position = orig_pos
			# try transitioning to a crouch
			crouch_check(dir)
		# if everything else failed, don't stand up

func start_crawl_anim(dir : int):
	action = Action.START_CRAWLING
	animation_done = false
	if dir > 0:
		sprite.play(&"Start Crawling R")
	else:
		sprite.play(&"Start Crawling L")

func crawl_anim(dir : int):
	action = Action.CRAWLING
	if dir > 0:
		sprite.play(&"Crawling R")
	else:
		sprite.play(&"Crawling L")

func _on_sprite_animation_finished() -> void:
	animation_done = true

func _ready():
	# make sure everything is set up with the scene
	standing_collision()
	stand_anim(facing_dir)

func transition_animation(grounded : bool,
						 pressed_dir : int,
						 can_drop : bool,
						 next_anim : Callable,
						 cancel_anim : Callable,
						 turn_anim : Callable):
	if grounded:
		if animation_done:
			if pressed_dir != 0 and pressed_dir != intent_dir:
				# pressed the opposite direction
				if turn_anim != NO_TURN:
					intent_dir = pressed_dir
					turn_anim.call(intent_dir)
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
						turning_anim(intent_dir)
					else:
						# pressed in same direction: walk
						start_walk_anim(facing_dir)
			else:
				# fall
				fall_anim(facing_dir)
		Action.TURNING:
			transition_animation(grounded,
								pressed_dir,
								true,
								start_walk_anim,
								stand_anim,
								NO_TURN)
		Action.START_WALKING:
			transition_animation(grounded,
								pressed_dir,
								true,
								walk_anim,
								stand_anim,
								turning_anim)
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
					turning_anim(intent_dir)
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
			velocity.x = AIR_SPEED * air_dir
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
				velocity.x = AIR_SPEED * air_dir
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
								false,
								stand_check,
								grab_anim,
								NO_TURN)
		Action.START_STANDING:
			transition_animation(grounded,
								 pressed_dir,
								 false,
								 stand_anim,
								 stand_anim,
								 NO_TURN)
		Action.START_CROUCHING:
			transition_animation(grounded,
								 pressed_dir,
								 false,
								 crouch_anim,
								 crouch_anim,
								 NO_TURN)
		Action.CROUCHING:
			if grounded:
				if Input.is_action_just_pressed(&"climb_up"):
					stand_check(facing_dir)
				elif pressed_dir != 0:
					if pressed_dir != facing_dir:
						# pressed in opposite direction: turn
						pass
					else:
						start_crawl_anim(facing_dir)
			else:
				# fall
				fall_anim(facing_dir)
		Action.START_CRAWLING:
			transition_animation(grounded,
								 pressed_dir,
								 false,
								 crawl_anim,
								 crawl_anim,
								 NO_TURN)
		Action.CRAWLING:
			if grounded:
				if Input.is_action_just_pressed(&"climb_up"):
					stand_check(facing_dir)
				elif pressed_dir == 0:
					# stop
					crouch_anim(facing_dir)
				else:
					# continue walking
					velocity.x = CRAWL_SPEED * facing_dir
			else:
				# fall
				# restore standing shape
				fall_anim(facing_dir)

	# always apply gravity, many grounded/grabbing checks depend on this.
	velocity.y += FALL_SPEED * delta

	move_and_slide()
