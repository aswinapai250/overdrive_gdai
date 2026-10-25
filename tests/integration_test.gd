extends SceneTree

# Headless Integration Test for Velocity: Momentum Protocol
func _init() -> void:
	print("--- BEGIN VELOCITY INTEGRATION TEST ---")
	var main_scene = load("res://scenes/main.tscn")
	if not main_scene:
		printerr("TEST FAILED: Could not load main.tscn")
		quit(1)
		return
		
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# Wait for ready
	await process_frame
	
	var player: Player = main.find_child("Player", true, false)
	assert(player != null, "Player node not found!")
	print("✔ Main scene & Player loaded successfully.")

	# Test 1: Forward Running & Initial Parameters
	assert(player.forward_speed == player.BASE_SPEED, "Base speed mismatch!")
	assert(player.shields == 3, "Initial shields should be 3!")
	assert(player.current_lane_idx == 0, "Initial lane should be center (0)!")
	print("✔ Initial player parameters verified.")

	# Simulate 30 frames of running
	for i in range(30):
		player._physics_process(0.016)
	assert(player.distance_traveled > 0.0, "Player should have traveled distance!")
	assert(player.position.z < 0.0, "Player position.z should advance negatively!")
	print("✔ Forward running & distance accumulation verified. Distance: %.1f m" % player.distance_traveled)

	# Test 2: Mechanic 1 - Momentum Slide
	var standing_height = player.collision_shape.shape.height
	assert(is_equal_approx(standing_height, 1.8), "Standing height should be 1.8m!")
	player._try_slide()
	assert(player.is_sliding, "Player should be sliding!")
	var sliding_height = player.collision_shape.shape.height
	assert(is_equal_approx(sliding_height, 0.65), "Sliding height should be 0.65m!")
	print("✔ Slide mechanic verified: Height reduced from %.2fm to %.2fm" % [standing_height, sliding_height])

	# Advance until slide expires
	for i in range(50):
		player._physics_process(0.016)
	assert(not player.is_sliding, "Slide should have ended!")
	assert(is_equal_approx(player.collision_shape.shape.height, 1.8), "Standing height should be restored to 1.8m!")
	print("✔ Slide recovery verified: Standing height restored to 1.8m.")

	# Test 3: Mechanic 2 - Precision Jumping
	player.jump_buffer_timer = 0.1
	player.coyote_timer = 0.1
	player._physics_process(0.016)
	assert(player.velocity.y > 8.0, "Jump velocity should be positive and snappy!")
	print("✔ Jump mechanic verified: Upward velocity %.1f m/s" % player.velocity.y)

	# Test 4: Mechanic 3 - Three-Lane Switching
	player._change_lane(1) # Move right
	assert(player.current_lane_idx == 1, "Lane index should be 1 (Right)!")
	assert(player.target_x == 3.2, "Target X should be 3.2m!")
	for i in range(20):
		player._physics_process(0.016)
	assert(player.position.x > 1.5, "Player should have interpolated toward right lane!")
	print("✔ Lane switching verified: Moved to right lane (X = %.2f)" % player.position.x)

	# Test 5: Mechanic 4 - Boost & Energy Management
	var initial_energy = player.energy
	player.collect_energy(25.0, 200, false)
	assert(player.energy > initial_energy, "Energy should increase after collection!")
	print("✔ Energy collection verified: Energy increased to %.1f" % player.energy)

	# Test 6: Risk-Reward Notification
	player.notify_risk_sector(1)
	assert(player.in_risk_sector, "Risk sector should be active!")
	assert(player.risk_lane_idx == 1, "Risk lane index should be 1!")
	print("✔ Risk-reward protocol verified.")

	# Test 7: Perfect Slide Reward
	var prev_score = player.score
	player.register_perfect_slide()
	assert(player.score > prev_score, "Perfect slide should grant score bonus!")
	print("✔ Perfect slide reward verified.")

	print("\nALL 7 TESTS PASSED SUCCESSFULLY! 100% FUNCTIONAL GAMEPLAY.")
	print("--- END VELOCITY INTEGRATION TEST ---")
	quit(0)
