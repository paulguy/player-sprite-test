extends CharacterBody2D
class_name Player

const SPEED : float = 150.0
const INCHING_SPEED : float = 20.0
const CRAWL_SPEED : float = 50.0
const AIR_SPEED : float = 200.0
const FALL_SPEED : float = 300.0
const JUMP_POWER : float = 300.0
const CLIMB_SPEED : float = 50.0
const START_WALKING_FRAMES : int = 2
const SPRITE_WIDTH : float = 16.0
const GRAB_AFTER_FALLING : float = 1.0
const WATER_DRAG : float = 0.95
const SWIM_POWER : float = 150.0
const SWIM_DELAY : float = 0.25
const WATER_FALL_SPEED : float = 150.0

@onready var sprite : AnimatedSprite2D = $"Sprite"
@onready var standing_coll : CollisionShape2D = $"Standing Collision"
@onready var crouching_coll : CollisionShape2D = $"Crouching Collision"
@onready var grab_coll : CollisionShape2D = $"Grab Collision"
@onready var grab_ray : RayCast2D = $"Grab Ray"
@onready var ledge_ray : RayCast2D = $"Ledge Ray"

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
	CRAWLING,
	# TODO: make climbing only possible with some walls
	#       automatically ledge grab when crawling instead of crawling off an edge
	CLIMBING_IDLE,
	CLIMBING,
	DOWN_TO_LEDGE,
	SWIMMING
}

var action : Action = Action.STANDING
var intent_dir : float = 1.0
var facing_dir : float = 1.0
var air_velocity : float = 0.0
var animation_done : bool = true
var falling_open_wall : bool = true
var last_y : float = 0.0
var fall_dist : float = 0.0
var gravity : float = FALL_SPEED
var in_water : bool = false
var swim_timer : float = 0.0

func entered_water():
	in_water = true

func left_water():
	in_water = false

# sentinel Callable to disable turning
func NO_TURN(_dir : float):
	pass

func crouching_collision():
	standing_coll.disabled = true
	crouching_coll.disabled = false

func standing_collision():
	standing_coll.disabled = false
	crouching_coll.disabled = true

func enable_gravity():
	if in_water:
		gravity = WATER_FALL_SPEED
	else:
		gravity = FALL_SPEED

func disable_gravity():
	gravity = 0.0

func set_facing_dir(dir : float):
	intent_dir = dir
	facing_dir = dir
	grab_coll.position.x = absf(grab_coll.position.x) * dir
	grab_coll.shape.b.x = absf(grab_coll.shape.b.x) * dir
	grab_ray.position = grab_coll.position
	grab_ray.target_position.x = grab_coll.shape.b.x
	ledge_ray.position.x = absf(ledge_ray.position.x) * dir

func stand_anim(dir : float):
	action = Action.STANDING
	velocity.x = 0.0
	air_velocity = 0.0
	if dir > 0.0:
		sprite.play(&"Standing R")
	else:
		sprite.play(&"Standing L")

func start_walk_anim(dir : float):
	action = Action.START_WALKING
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Start Walking R")
	else:
		sprite.play(&"Start Walking L")

func walk_anim(dir : float):
	action = Action.WALKING
	air_velocity = AIR_SPEED * dir
	if dir > 0.0:
		sprite.play(&"Walking R")
	else:
		sprite.play(&"Walking L")
	sprite.set_frame_and_progress(START_WALKING_FRAMES, 0.0)

func turning_anim(dir : float):
	action = Action.TURNING
	velocity.x = 0.0
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Turning")
	else:
		sprite.play_backwards(&"Turning")

func jump_anim(dir : float):
	action = Action.START_JUMPING
	velocity.x = 0.0
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Jumping R")
	else:
		sprite.play(&"Jumping L")

func fall_anim(dir : float):
	action = Action.FALLING
	# if gravity was off, enable it
	enable_gravity()
	# could be falling from crawling
	standing_collision()
	# initializa the correct value at the peak
	# raycasting is disabled at this point, so force the update
	grab_ray.force_raycast_update()
	if grab_ray.is_colliding():
		# blocked
		falling_open_wall = false
	else:
		# open
		falling_open_wall = true
	last_y = position.y
	fall_dist = 0.0
	if dir > 0.0:
		sprite.play(&"Falling R")
	else:
		sprite.play(&"Falling L")

func grab_anim(dir : float):
	action = Action.GRABBING
	grab_coll.disabled = false
	if dir > 0.0:
		sprite.play(&"Grabbing R")
	else:
		sprite.play(&"Grabbing L")

func ledge_climb_anim(dir : float):
	action = Action.LEDGE_CLIMB
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Ledge Climb R")
	else:
		sprite.play(&"Ledge Climb L")

func start_crouch_anim(dir : float):
	action = Action.START_CROUCHING
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Start Crouch R")
	else:
		sprite.play(&"Start Crouch L")

func crouch_anim(dir : float):
	action = Action.CROUCHING
	velocity.x = 0.0
	if dir > 0.0:
		sprite.play(&"Crouch R")
	else:
		sprite.play(&"Crouch L")

func crouch_check(dir : float):
	# disable grab collider
	# needed for climbing up in to a crouch
	grab_coll.disabled = true
	# store original values
	var orig_pos : Vector2 = position
	if action == Action.LEDGE_CLIMB:
		# try placing self in new position for climbing up
		position += grab_ray.position + grab_ray.target_position
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
			grab_anim(dir)
		# don't change anim/action

func start_stand_anim(dir : float):
	action = Action.START_STANDING
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Start Standing R")
	else:
		sprite.play(&"Start Standing L")

func stand_check(dir : float):
	# disable grab collider
	grab_coll.disabled = true
	var orig_pos : Vector2
	if action == Action.LEDGE_CLIMB:
		# try placing self in new position
		orig_pos = position
		position += grab_ray.position + grab_ray.target_position
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

func start_crawl_anim(dir : float):
	action = Action.START_CRAWLING
	animation_done = false
	if dir > 0.0:
		sprite.play(&"Start Crawling R")
	else:
		sprite.play(&"Start Crawling L")

func crawl_anim(dir : float):
	action = Action.CRAWLING
	if dir > 0.0:
		sprite.play(&"Crawling R")
	else:
		sprite.play(&"Crawling L")

func setup_climb(dir : float):
	disable_gravity()
	sprite.position.x = ((standing_coll.shape.size.x / 2.0) - (SPRITE_WIDTH / 2.0)) * dir

func climb_idle_anim(dir : float):
	setup_climb(dir)
	if action != Action.CLIMBING:
		if dir > 0.0:
			sprite.play(&"Climbing R")
		else:
			sprite.play(&"Climbing L")
	action = Action.CLIMBING_IDLE
	sprite.pause()

func climb_anim(dir : float):
	setup_climb(dir)
	if action != Action.CLIMBING_IDLE:
		if dir > 0.0:
			sprite.play(&"Climbing R")
		else:
			sprite.play(&"Climbing L")
	else:
		sprite.play()
	action = Action.CLIMBING

func down_to_ledge_anim(dir : float):
	action = Action.DOWN_TO_LEDGE
	if dir > 0.0:
		sprite.play(&"Down To Ledge R")
	else:
		sprite.play(&"Down To Ledge L")

func down_to_ledge(dir : float):
	# hanging off an edge, go in to a ledge grab
	# move the player to somewhere roughly over the ledge
	position.x += standing_coll.shape.size.x * dir
	# do this after so the player is moved in their facing position
	set_facing_dir(-dir)
	# do this first to enable collision
	# want the new facing_dir
	grab_anim(facing_dir)
	# move the player against the ledge
	# in 2 steps to make sure the player is as close as
	# possible on both axes so it looks visually correct
	move_and_collide(Vector2(0.0, -grab_ray.position.y))
	move_and_collide(Vector2(grab_coll.shape.b.x, 0.0))

func swim_anim(dir : float):
	action = Action.SWIMMING
	air_velocity = 0.0
	if dir > 0.0:
		sprite.play(&"Swimming R")
	else:
		sprite.play(&"Swimming L")

func swimming_turning_anim(dir : float):
	# not a real action
	if dir > 0.0:
		sprite.play(&"Swimming Turning")
	else:
		sprite.play_backwards(&"Swimming Turning")

func swim():
	velocity.y -= SWIM_POWER
	swim_timer = SWIM_DELAY

func _on_sprite_animation_finished() -> void:
	animation_done = true

func _ready():
	# make sure everything is set up with the scene
	standing_collision()
	stand_anim(facing_dir)

func transition_animation(grounded : bool,
						 pressed_horiz : float,
						 pressed_vert : float,
						 can_drop : bool,
						 climbing : bool,
						 next_anim : Callable,
						 cancel_anim : Callable,
						 turn_anim : Callable):
	if grounded:
		if animation_done:
			if pressed_horiz != 0.0 and pressed_horiz != intent_dir:
				# pressed the opposite direction
				if turn_anim != NO_TURN:
					intent_dir = pressed_horiz
					turn_anim.call(intent_dir)
				elif can_drop:
					fall_anim(facing_dir)
			else:
				set_facing_dir(intent_dir)
				if (pressed_horiz == intent_dir) or \
				   (climbing and pressed_vert < 0.0):
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
	var pressed_horiz : float = Input.get_axis(&"move_left", &"move_right")
	var pressed_vert : float = Input.get_axis(&"climb_up", &"crouch")
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

	if Input.is_action_pressed(&"jump"):
		jumping = true

	match action:
		Action.STANDING:
			if grounded:
				if jumping:
					# jump/swim
					if in_water:
						swim()
						swim_anim(facing_dir)
					else:
						jump_anim(facing_dir)
				elif pressed_vert < 0.0:
					# try to climb
					grab_ray.force_raycast_update()
					if grab_ray.is_colliding():
						# move player against wall
						move_and_collide(Vector2(grab_ray.target_position.x, 0.0))
						climb_idle_anim(facing_dir)
				elif Input.is_action_just_pressed(&"crouch"):
					ledge_ray.force_raycast_update()
					if not ledge_ray.is_colliding():
						down_to_ledge_anim(facing_dir)
					else:
						crouch_check(facing_dir)
				elif pressed_horiz != 0.0:
					if pressed_horiz != facing_dir:
						# pressed in opposite direction: turn
						intent_dir = pressed_horiz
						turning_anim(intent_dir)
					else:
						# pressed in same direction: walk
						start_walk_anim(facing_dir)
			else:
				# fall
				fall_anim(facing_dir)
		Action.TURNING:
			transition_animation(grounded,
								 pressed_horiz,
								 pressed_vert,
								 true, false,
								 start_walk_anim,
								 stand_anim,
								 NO_TURN)
		Action.START_WALKING:
			velocity.x = INCHING_SPEED * facing_dir
			transition_animation(grounded,
								 pressed_horiz,
								 pressed_vert,
								 true, false,
								 walk_anim,
								 stand_anim,
								 turning_anim)
		Action.WALKING:
			if grounded:
				if jumping:
					# jump/swim
					if in_water:
						swim()
						swim_anim(facing_dir)
					else:
						jump_anim(facing_dir)
				elif pressed_horiz == 0.0:
					# stop
					stand_anim(facing_dir)
				elif pressed_horiz != facing_dir:
					# turn
					intent_dir = pressed_horiz
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
				air_velocity = 0.0
			velocity.x = air_velocity
			if velocity.y > 0.0:
				fall_anim(facing_dir)
		Action.FALLING:
			if hit_wall:
				air_velocity = 0.0
			if grounded:
				# landed on ground
				stand_anim(facing_dir)
			else:
				# falling
				grab_ray.force_raycast_update()
				if grab_ray.is_colliding():
					# blocked
					# prevent regrabbing the same ledge
					# only grab if falling straight down because it's the only
					# way it's unambiguous that the player has fallen past a ledge
					# rather than flew towards a wall
					if falling_open_wall and \
					   fall_dist >= GRAB_AFTER_FALLING and \
					   velocity.x == 0.0:
						# transition from open to blocked
						# grab
						# TODO: Fix letting go/falling on next frame sometimes.
						grab_anim(facing_dir)
						# move the player against the ledge
						# in 2 steps to make sure the player is as close as
						# possible on both axes so it looks visually correct
						position.y = last_y
						move_and_collide(Vector2(0.0, position.y - last_y))
						move_and_collide(Vector2(grab_coll.shape.b.x, 0.0))
					falling_open_wall = false
				else:
					# open
					falling_open_wall = true
				velocity.x = air_velocity
				last_y = position.y
		Action.GRABBING:
			if grabbing:
				# still grabbing
				if (facing_dir < 0.0 and Input.is_action_just_pressed(&"move_left")) or \
				   (facing_dir > 0.0 and Input.is_action_just_pressed(&"move_right")) or \
				   Input.is_action_just_pressed(&"climb_up"):
					# pressing towards ledge or pressed up
					# start climbing up
					ledge_climb_anim(facing_dir)
				elif (facing_dir > 0.0 and Input.is_action_just_pressed(&"move_left")) or \
					 (facing_dir < 0.0 and Input.is_action_just_pressed(&"move_right")):
					# pressing away from ledge
					# let go
					fall_anim(facing_dir)
					grab_coll.disabled = true
				elif pressed_vert > 0.0:
					# pressed down
					# transition to climbing down the wall
					climb_anim(facing_dir)
					grab_coll.disabled = true
					# move down a little so the player is still detected as
					# against the wall
					move_and_collide(Vector2(0.0, CLIMB_SPEED * delta))
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
								 pressed_horiz,
								 pressed_vert,
								 false, true,
								 stand_check,
								 grab_anim,
								 NO_TURN)
		Action.START_STANDING:
			transition_animation(grounded,
								 pressed_horiz,
								 pressed_vert,
								 false, true,
								 stand_anim,
								 stand_anim,
								 NO_TURN)
		Action.START_CROUCHING:
			transition_animation(grounded,
								 pressed_horiz,
								 pressed_vert,
								 false, false,
								 crouch_anim,
								 crouch_anim,
								 NO_TURN)
		Action.CROUCHING:
			if grounded:
				if Input.is_action_just_pressed(&"climb_up"):
					stand_check(facing_dir)
				elif pressed_horiz != 0.0:
					if pressed_horiz != facing_dir:
						# pressed in opposite direction: turn
						pass
					else:
						start_crawl_anim(facing_dir)
			else:
				# fall
				fall_anim(facing_dir)
		Action.START_CRAWLING:
			transition_animation(grounded,
								 pressed_horiz,
								 pressed_vert,
								 false, false,
								 crawl_anim,
								 crawl_anim,
								 NO_TURN)
		Action.CRAWLING:
			if grounded:
				if Input.is_action_just_pressed(&"climb_up"):
					velocity.x = 0.0
					stand_check(facing_dir)
				elif pressed_horiz == 0.0:
					# stop
					crouch_anim(facing_dir)
				else:
					# continue walking
					velocity.x = CRAWL_SPEED * facing_dir
			else:
				# fall
				velocity.x = 0.0
				fall_anim(facing_dir)
		Action.CLIMBING_IDLE:
			grab_ray.force_raycast_update()
			if grab_ray.is_colliding():
				if (facing_dir > 0.0 and Input.is_action_just_pressed(&"move_left")) or \
				   (facing_dir < 0.0 and Input.is_action_just_pressed(&"move_right")):
					# pressing away from wall
					# let go
					sprite.position.x = 0.0
					fall_anim(facing_dir)
				else:
					if pressed_vert != 0.0:
						climb_anim(facing_dir)
			else:
				sprite.position.x = 0.0
				fall_anim(facing_dir)
				# grab immediately
				fall_dist = GRAB_AFTER_FALLING
		Action.CLIMBING:
			grab_ray.force_raycast_update()
			if grab_ray.is_colliding():
				if pressed_vert > 0.0 and is_on_floor():
					sprite.position.x = 0.0
					stand_anim(facing_dir)
				elif pressed_vert == 0.0:
					velocity.y = 0.0
					climb_idle_anim(facing_dir)
				else:
					velocity.y = CLIMB_SPEED * pressed_vert
			else:
				# enables grab collider
				grab_anim(facing_dir)
				# move player against floor
				move_and_collide(Vector2(0.0, -velocity.y))
				# assure player collides with the ground right away to not fall
				velocity = Vector2.ZERO
				enable_gravity()
				# restore sprite position
				sprite.position.x = 0.0
		Action.DOWN_TO_LEDGE:
			transition_animation(grounded,
								 pressed_horiz,
								 pressed_vert,
								 false, false,
								 down_to_ledge,
								 down_to_ledge,
								 NO_TURN)
		Action.SWIMMING:
			if not in_water:
				# if the player left the water, change actions
				if grounded:
					walk_anim(facing_dir)
				elif velocity.y < 0.0:
					grab_ray.force_raycast_update()
					if grab_ray.is_colliding():
						# grab wall
						# move against wall
						velocity.y = 0.0
						move_and_collide(Vector2(grab_ray.target_position.x, 0.0))
						climb_idle_anim(facing_dir)
					else:
						# jump out
						# preserve movement speed jumping out of water
						air_velocity = velocity.x
						jump_anim(facing_dir)
				else:
					fall_anim(facing_dir)
			else:
				if grounded:
					# landed on bottom underwater
					set_facing_dir(intent_dir)
					stand_anim(facing_dir)
				else:
					# still in water
					if intent_dir != facing_dir and animation_done:
						# at the end of a turn animation continue swim animation
						set_facing_dir(intent_dir)
						swim_anim(facing_dir)

					swim_timer -= delta
					if swim_timer <= 0.0 and Input.is_action_just_pressed(&"jump"):
						swim()
					elif pressed_horiz != 0.0 and pressed_horiz != facing_dir:
						# turn
						animation_done = false
						intent_dir = pressed_horiz
						swimming_turning_anim(intent_dir)

					velocity.x += SWIM_POWER * delta * pressed_horiz

	if gravity != 0.0:
		# if gravity is enabled, make sure it's the correct value
		enable_gravity()

	# always apply gravity, many grounded/grabbing checks depend on this.
	velocity.y += gravity * delta

	if in_water:
		if not grounded and not grabbing and action != Action.SWIMMING:
			# if the player has transitioned to being in water without
			# being transitioned to the swimming state, transition to the swimming
			# state.  Like falling or jumping in to water.
			# allow normal actions to work underwater though.
			swim_anim(facing_dir)
			enable_gravity()
		velocity *= WATER_DRAG

	var dist : float = position.y
	move_and_slide()
	dist = position.y - dist
	fall_dist += dist
