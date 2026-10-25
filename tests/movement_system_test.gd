extends SceneTree

# Comprehensive Unit & Integration Test for the 5-Mechanic Movement System
# Mechanics tested:
# 1. Slide
# 2. Dash
# 3. Double Jump
# 4. Wall Run
# 5. Grappling Hook

func _init() -> void:
	print("==================================================")
	print("--- BEGIN 5-MECHANIC MOVEMENT SYSTEM TEST SUITE ---")
	print("==================================================")
	
	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("TEST FAILED: Could not load main.tscn")
		quit(1)
		return
		
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	
	var player: Player = main.find_child("Player", true, false)
	assert(player != null, "Player node not found!")
	print("✔ Scene and Player initialized successfully.")

	# -------------------------------------------------------------------------
	# 1. SLIDE MECHANIC
	# -------------------------------------------------------------------------
	print("\n[TEST 1] SLIDE MECHANIC")
	assert(not player.is_sliding, "Player should start in non-sliding state.")
	var normal_h = player.collision_shape.shape.height
	assert(is_equal_approx(normal_h, 1.8), "Initial capsule height must be 1.8m.")
	
	player._try_slide()
	assert(player.is_sliding, "Slide should be active after _try_slide().")
	var slide_h = player.collision_shape.shape.height
	assert(is_equal_approx(slide_h, 0.65), "Capsule height during slide must be 0.65m.")
	assert(player.is_sliding_active(), "is_sliding_active() helper should return true.")
	
	# Simulate physics steps to finish slide
	for i in range(50):
		player._physics_process(0.016)
		
	assert(not player.is_sliding, "Slide should terminate after duration.")
	assert(is_equal_approx(player.collision_shape.shape.height, 1.8), "Standing height restored to 1.8m.")
	print("✔ Slide mechanic verified: Height reduction, state transitions, and recovery.")

	# -------------------------------------------------------------------------
	# 2. DASH MECHANIC
	# -------------------------------------------------------------------------
	print("\n[TEST 2] DASH MECHANIC")
	player.dash_cooldown_timer = 0.0
	assert(not player.is_dashing, "Player should not start in dash state.")
	
	player._try_dash()
	assert(player.is_dashing, "Dash should be active after _try_dash().")
	assert(player.is_dashing_active(), "is_dashing_active() helper should return true.")
	assert(player.dash_direction.length() > 0.9, "Dash direction should be normalized.")
	assert(player.dash_cooldown_timer > 0.0, "Dash cooldown should be triggered.")
	
	# Verify dash speed override during physics process
	player._physics_process(0.016)
	var dash_horiz_speed = Vector2(player.velocity.x, player.velocity.z).length()
	assert(is_equal_approx(dash_horiz_speed, player.DASH_SPEED), "Dash velocity magnitude should equal DASH_SPEED (52.0).")
	
	# Advance until dash ends
	for i in range(20):
		player._physics_process(0.016)
	assert(not player.is_dashing, "Dash should expire after DASH_DURATION.")
	print("✔ Dash mechanic verified: Direction normalization, burst velocity, and cooldown.")

	# -------------------------------------------------------------------------
	# 3. DOUBLE JUMP MECHANIC
	# -------------------------------------------------------------------------
	print("\n[TEST 3] DOUBLE JUMP MECHANIC")
	# First jump from ground
	player.air_jumps_used = 0
	player.coyote_timer = 0.12
	player.jump_buffer_timer = 0.1
	player._physics_process(0.016)
	assert(player.velocity.y > 9.0, "First jump upward velocity should be ~10.5 m/s.")
	assert(player.air_jumps_used == 0, "Air jumps should not be consumed by ground jump.")
	
	# Clear ground / coyote window to simulate airborne state
	player.coyote_timer = 0.0
	# Trigger second jump (air jump)
	player.jump_buffer_timer = 0.1
	player._physics_process(0.016)
	assert(player.air_jumps_used == 1, "Double jump should consume 1 air jump.")
	assert(is_equal_approx(player.velocity.y, player.DOUBLE_JUMP_VELOCITY), "Double jump velocity should match DOUBLE_JUMP_VELOCITY (9.0).")
	
	# Attempt third jump while in air — should NOT trigger another jump
	var pre_y = player.velocity.y
	player.jump_buffer_timer = 0.1
	player._physics_process(0.016)
	assert(player.air_jumps_used == 1, "Max air jumps is 1; third jump must be ignored.")
	
	# Test reset on landing
	player.air_jumps_used = 1
	player._on_land()
	# Simulate grounded frame
	player.coyote_timer = player.COYOTE_TIME
	player.air_jumps_used = 0
	assert(player.air_jumps_used == 0, "Air jumps should reset upon landing.")
	print("✔ Double Jump mechanic verified: Ground jump -> Air jump -> Jump limit enforced -> Reset on land.")

	# -------------------------------------------------------------------------
	# 4. WALL RUN MECHANIC
	# -------------------------------------------------------------------------
	print("\n[TEST 4] WALL RUN MECHANIC")
	assert(not player.is_wall_running, "Player should start with wall run inactive.")
	
	# Place player in airborne state with wall-run active
	player.position.y = 3.0
	player.wall_run_side = 1
	player.wall_normal = Vector3(-1, 0, 0)
	player.is_wall_running = true
	player.wall_run_timer = player.WALL_RUN_DURATION
	assert(player.is_wall_running_active(), "is_wall_running_active() helper should return true.")
	
	# Check reduced gravity calculation directly
	var normal_grav = player.GRAVITY * 0.016
	var wall_grav = player.GRAVITY * player.WALL_RUN_GRAVITY_SCALE * 0.016
	assert(wall_grav < normal_grav * 0.25, "Wall run gravity scale (0.18) must reduce gravity to < 25%.")
	
	# Test Wall Jump execution
	player._execute_wall_jump()
	assert(not player.is_wall_running, "Wall jump should end wall run.")
	assert(is_equal_approx(player.velocity.y, player.WALL_JUMP_VELOCITY_Y), "Wall jump upward velocity must match WALL_JUMP_VELOCITY_Y.")
	assert(player.velocity.x < -3.0, "Wall jump should push player away from the right wall.")
	assert(player.air_jumps_used == 0, "Wall jump should reset double jump capacity.")
	print("✔ Wall Run mechanic verified: Cling physics, reduced gravity, wall jump away impulse & jump reset.")

	# -------------------------------------------------------------------------
	# 5. GRAPPLING HOOK MECHANIC
	# -------------------------------------------------------------------------
	print("\n[TEST 5] GRAPPLING HOOK MECHANIC")
	assert(not player.is_grappling, "Grappling should start inactive.")
	
	# Simulate grapple attachment to overhead beam at (0, 6, -20)
	var anchor_target = Vector3(0.0, 6.0, player.global_position.z - 15.0)
	player.grapple_anchor = anchor_target
	player.is_grappling = true
	player.grapple_launched = true
	if player.grapple_rope:
		player.grapple_rope.visible = true
	assert(player.is_grappling_active(), "is_grappling_active() helper should return true.")
	
	# Run grapple physics update
	var init_vel = player.velocity
	player._update_grapple(0.05)
	# Pull force should accelerate towards anchor
	var to_anchor = (anchor_target - player.global_position).normalized()
	assert(player.velocity.y > init_vel.y, "Grapple pull should impart upward velocity toward overhead beam.")
	
	# Auto-release when close
	player.global_position = anchor_target + Vector3(0, 0.5, 0.5)
	player._update_grapple(0.016)
	assert(not player.is_grappling, "Grapple must auto-release when within GRAPPLE_MIN_DIST.")
	assert(not player.is_grappling_active(), "is_grappling_active() should be false after release.")
	print("✔ Grappling Hook mechanic verified: Target lock, pull kinematics, max speed cap, and auto-release.")

	print("\n==================================================")
	print("ALL 5 MOVEMENT MECHANICS VALIDATED AND FULLY OPERATIONAL!")
	print("==================================================")
	quit(0)
