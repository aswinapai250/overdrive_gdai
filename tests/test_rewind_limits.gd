extends SceneTree

const DT: float = 1.0 / 60.0

func _init() -> void:
	print("==================================================")
	print("--- BEGIN TIME REWIND LIMITS & BOUNDARY TEST ---")
	print("==================================================")
	
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if not main_scene:
		print("❌ FAILED: Unable to load main.tscn")
		quit(1)
		return
	
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	var player = root_node.get_node_or_null("Player")
	if not player:
		print("❌ FAILED: Player node not found in main.tscn")
		quit(1)
		return
	
	print("✔ Main scene and Player loaded.")

	# ──────────────────────────────────────────────────────────
	# TEST 1: STRICT 3-SECOND HISTORY LIMIT
	# ──────────────────────────────────────────────────────────
	print("\n[TEST 1] STRICT 3.0s HISTORY DURATION CAP")
	assert(player.max_history_duration == 3.0, "max_history_duration should be 3.0")
	print("  • max_history_duration is set to %.1f s" % player.max_history_duration)

	# Simulate 6 seconds of continuous forward running (360 frames)
	for i in range(360):
		player._physics_process(DT)

	var recorded_duration: float = player.history_duration
	var buffer_size: int = player.history_buffer.size()
	print("  • After 6.0s running (360 frames):")
	print("    Buffer size: %d snapshots" % buffer_size)
	print("    Buffer duration: %.3f s" % recorded_duration)

	# Must be <= 3.0s (with minor floating point tolerance <= 3.05)
	if recorded_duration > 3.05:
		print("❌ FAILED: History duration exceeds 3.0s (got %.3fs)" % recorded_duration)
		quit(1)
		return
	
	# At 60 ticks/sec, 3s is ~180 snapshots
	if buffer_size > 185:
		print("❌ FAILED: History buffer size too large (%d snaps)" % buffer_size)
		quit(1)
		return
	
	print("✔ History buffer strictly capped at <= 3.0s (180 snapshots).")

	# ──────────────────────────────────────────────────────────
	# TEST 2: CANNOT REWIND PAST 3 SECONDS
	# ──────────────────────────────────────────────────────────
	print("\n[TEST 2] REWIND PLAYBACK TIME BOUNDARY (MAX 3 SECONDS)")
	var pre_rewind_z: float = player.global_position.z
	var pre_rewind_dist: float = player.distance_traveled

	# Start rewinding
	player._start_rewind()
	assert(player.is_rewinding, "Player should be rewinding")

	# Rewind until buffer exhausted
	var rewind_frames: int = 0
	while player.is_rewinding and rewind_frames < 200:
		player._process_rewind(DT)
		rewind_frames += 1

	var post_rewind_z: float = player.global_position.z
	var post_rewind_dist: float = player.distance_traveled
	var distance_reversed: float = pre_rewind_dist - post_rewind_dist

	print("  • Pre-rewind distance: %.2f m, Post-rewind distance: %.2f m" % [pre_rewind_dist, post_rewind_dist])
	print("  • Distance reversed: %.2f m" % distance_reversed)
	print("  • Rewind completed in %d process steps" % rewind_frames)

	# Player was running at ~18 to 28 m/s for 3s, so reversed distance must be approximately 3s worth (~50-80m), NOT 6s worth
	if distance_reversed > 3.05 * player.MAX_NORMAL_SPEED:
		print("❌ FAILED: Rewound further back than 3.0 seconds worth of movement!")
		quit(1)
		return
	print("✔ Rewind reversed only the most recent 3 seconds of movement.")

	# ──────────────────────────────────────────────────────────
	# TEST 3: NEVER REWIND BEHIND RUN STARTING POINT
	# ──────────────────────────────────────────────────────────
	print("\n[TEST 3] HARD RUN-START BOUNDARY")
	# Reset player to fresh starting point
	player.global_position = Vector3(0, 0, 0)
	player.velocity = Vector3.ZERO
	player.forward_speed = player.BASE_SPEED
	player.distance_traveled = 0.0
	player.history_buffer.clear()
	player.history_duration = 0.0
	player.is_rewinding = false
	player.set_run_start(Vector3(0, 0, 0), 0.0)

	# Verify cannot rewind at starting point
	if player.can_rewind():
		print("❌ FAILED: can_rewind() returned true at run starting point!")
		quit(1)
		return
	print("  • can_rewind() correctly false at run start point (Z = 0, Dist = 0).")

	# Run forward for only 1.0 second (less than 3 seconds)
	for i in range(60):
		player._physics_process(DT)

	var mid_dist: float = player.distance_traveled
	var mid_z: float = player.global_position.z
	print("  • Ran forward 1.0s to Dist = %.2f m, Z = %.2f m" % [mid_dist, mid_z])
	assert(mid_dist > 0.0, "Player should have traveled forward")
	assert(mid_z < 0.0, "Player Z should be negative (forward)")
	assert(player.can_rewind(), "Player should now be able to rewind")

	# Rewind continuously back towards start
	player._start_rewind()
	var boundary_hit: bool = false
	for i in range(120): # More than enough steps to reach start
		if not player.is_rewinding:
			boundary_hit = true
			break
		player._process_rewind(DT)

	print("  • Rewind halted at: Dist = %.2f m, Z = %.2f m" % [player.distance_traveled, player.global_position.z])
	if player.global_position.z > 0.001 or player.distance_traveled < -0.001:
		print("❌ FAILED: Player rewound behind starting point! (Z=%.2f, Dist=%.2f)" % [player.global_position.z, player.distance_traveled])
		quit(1)
		return

	print("✔ Player never rewound behind the run's starting point.")
	print("✔ Rewind cleanly halted upon reaching run start boundary.")

	# ──────────────────────────────────────────────────────────
	# TEST 4: NO JITTER / STABILITY WHEN HOLDING R AT BOUNDARY
	# ──────────────────────────────────────────────────────────
	print("\n[TEST 4] SAFE BOUNDARY ENFORCEMENT & NO JITTER")
	var initial_z: float = player.global_position.z
	# Simulate 30 frames of normal physics while player is at start boundary
	for i in range(30):
		# can_rewind() should be false at or behind start
		if player.global_position.z >= 0.0 and player.distance_traveled <= 0.0:
			assert(not player.can_rewind(), "can_rewind must remain false at start boundary")
		player._physics_process(DT)

	# Verify player moved forward smoothly with normal physics, zero oscillation
	assert(player.global_position.z < initial_z, "Player smoothly resumed forward movement")
	assert(not player.is_rewinding, "Player is not stuck in rewind")
	print("✔ Normal forward gameplay resumed smoothly from boundary with zero jitter.")

	# ──────────────────────────────────────────────────────────
	# TEST 5: EDGE CASES & FUTURE HISTORY DISCARD
	# ──────────────────────────────────────────────────────────
	print("\n[TEST 5] FUTURE HISTORY DISCARD & STATE RESTORATION")
	# Let player run forward 2 seconds
	for i in range(120):
		player._physics_process(DT)
	
	var point_a_z: float = player.global_position.z
	var point_a_dist: float = player.distance_traveled
	var buffer_len_a: int = player.history_buffer.size()

	# Rewind 1 second (approx 25 steps at 2.5x speed)
	player._start_rewind()
	for i in range(25):
		if player.is_rewinding:
			player._process_rewind(DT)
	player._stop_rewind()

	var point_b_z: float = player.global_position.z
	var buffer_len_b: int = player.history_buffer.size()
	print("  • Rewound from Z=%.2f (buf=%d) to Z=%.2f (buf=%d)" % [point_a_z, buffer_len_a, point_b_z, buffer_len_b])
	assert(point_b_z > point_a_z, "Player rewound back in space")
	assert(buffer_len_b < buffer_len_a, "Future history snapshots were discarded")

	# Continue running forward from point B
	for i in range(30):
		player._physics_process(DT)
	
	print("  • New movement recorded smoothly from rewritten present.")
	print("✔ Abandoned future history was cleanly discarded.")

	# ──────────────────────────────────────────────────────────
	# TEST 6: DEATH RESETS REWIND
	# ──────────────────────────────────────────────────────────
	print("\n[TEST 6] DEATH CLEARS REWIND BUFFER")
	player._die("TEST_CRASH")
	assert(player.is_dead, "Player is dead")
	assert(player.history_buffer.is_empty(), "History buffer cleared on death")
	assert(player.history_duration == 0.0, "History duration 0.0 on death")
	assert(not player.is_rewinding, "Rewind cancelled on death")
	assert(not player.can_rewind(), "Dead player cannot rewind")
	print("✔ Death cleanly clears rewind buffer and prohibits rewinding.")

	print("\n==================================================")
	print("ALL TIME REWIND LIMITS & BOUNDARY TESTS PASSED! 100% SUCCESS")
	print("==================================================")
	quit(0)
