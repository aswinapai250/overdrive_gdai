extends SceneTree

func _init() -> void:
	print("\n========================================================")
	print("--- BEGIN FPP/TPP CAMERA TOGGLE & TRAVERSAL TEST SUITE ---")
	print("========================================================")

	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load main.tscn!")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame

	var player: Player = main_instance.find_child("Player", true, false)
	assert(player != null, "Player node not found!")
	var hud: HUD = main_instance.find_child("HUD", true, false)
	assert(hud != null, "HUD node not found!")

	# ── TEST 1: Default Camera State (TPP) ──────────────────────
	print("\n[TEST 1] VERIFY DEFAULT THIRD-PERSON PERSPECTIVE (TPP)")
	assert(not player.is_fpp, "Default camera mode must be TPP (is_fpp == false)!")
	assert(player.body_root.visible, "Player model must be visible in TPP!")
	assert(player.camera.current, "Camera3D must be active!")
	print("✔ Initial camera state verified: TPP, player visible, Camera3D active.")

	# ── TEST 2: Toggle to First-Person Perspective (FPP) ────────
	print("\n[TEST 2] TOGGLE PERSPECTIVE TO FIRST-PERSON (FPP)")
	var signaled_mode: Array = []
	player.camera_mode_changed.connect(func(is_first_person: bool): signaled_mode.append(is_first_person))

	player.toggle_camera_mode()
	assert(player.is_fpp, "Camera mode must be FPP after toggle!")
	assert(signaled_mode.size() == 1 and signaled_mode[0] == true, "camera_mode_changed signal must emit (true)!")

	# Simulate 20 physics frames to let camera smoothly lerp to FPP
	for i in range(20):
		player._physics_process(0.016)

	assert(player.camera_transition_weight > 0.8, "Camera transition weight must approach 1.0 (FPP)!")
	assert(not player.body_root.visible, "Player body must be hidden in FPP to prevent view obstruction!")
	assert(player.camera.position.z < 0.5, "Camera must be at eye position ahead of back! Pos Z: %.2f" % player.camera.position.z)
	print("✔ FPP toggle verified: Smooth transition, eye-level camera, player body hidden.")

	# ── TEST 3: Toggle back to Third-Person Perspective (TPP) ───
	print("\n[TEST 3] TOGGLE BACK TO THIRD-PERSON (TPP)")
	player.toggle_camera_mode()
	assert(not player.is_fpp, "Camera mode must be TPP after second toggle!")

	for i in range(20):
		player._physics_process(0.016)

	assert(player.camera_transition_weight < 0.2, "Camera transition weight must approach 0.0 (TPP)!")
	assert(player.body_root.visible, "Player body must be restored to visible in TPP!")
	assert(player.camera.position.z > 3.0, "Camera must be behind player in TPP! Pos Z: %.2f" % player.camera.position.z)
	print("✔ TPP return verified: Player model restored, camera behind player.")

	# ── TEST 4: Camera Toggle During Movement Mechanics ─────────
	print("\n[TEST 4] CAMERA TOGGLE PRESERVES MOVEMENT STATES & VELOCITY")
	
	# Jump state test
	player.velocity.y = 10.5
	var saved_vy = player.velocity.y
	player.toggle_camera_mode() # Switch during jump
	assert(absf(player.velocity.y - saved_vy) < 0.01, "Camera toggle must not alter vertical jump velocity!")

	# Dash state test
	player._try_dash()
	assert(player.is_dashing, "Dash must activate.")
	player.toggle_camera_mode() # Switch during dash
	assert(player.is_dashing, "Camera toggle must not cancel active Dash!")

	# Slide state test
	player._try_slide()
	assert(player.is_sliding, "Slide must activate.")
	player.toggle_camera_mode() # Switch during slide
	assert(player.is_sliding, "Camera toggle must not cancel active Slide!")

	# Wall run state test
	player.is_wall_running = true
	player.wall_run_timer = 1.2
	player.wall_run_side = -1
	player.wall_normal = Vector3(1, 0, 0)
	player.toggle_camera_mode() # Switch during wall run
	assert(player.is_wall_running, "Camera toggle must not cancel active Wall Run!")

	# Grapple state test
	player.is_grappling = true
	player.grapple_anchor = Vector3(0, 6.0, -15.0)
	player.toggle_camera_mode() # Switch during grapple
	assert(player.is_grappling, "Camera toggle must not cancel active Grapple!")

	print("✔ Mechanics preservation verified: No velocity spikes, state resets, or broken abilities during camera toggle.")

	# ── TEST 5: HUD Indicator Synchronization ────────────────────
	print("\n[TEST 5] HUD PERSPECTIVE BADGE SYNCHRONIZATION")
	assert(hud.camera_mode_label != null, "HUD CameraModeLabel must exist!")
	player.is_fpp = true
	hud.update_camera_mode(true)
	assert("FPP" in hud.camera_mode_label.text, "HUD badge must show FPP!")
	player.is_fpp = false
	hud.update_camera_mode(false)
	assert("TPP" in hud.camera_mode_label.text, "HUD badge must show TPP!")
	print("✔ HUD indicator synchronization verified.")

	print("\n========================================================")
	print("ALL FPP/TPP CAMERA & TRAVERSAL TESTS PASSED SUCCESSFULLY!")
	print("========================================================")
	quit(0)
