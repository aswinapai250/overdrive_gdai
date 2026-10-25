extends SceneTree

# Verification Test for Player Visibility & Camera Framing
func _init() -> void:
	print("--- BEGIN PLAYER VISIBILITY VERIFICATION TEST ---")
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	
	var player: Player = main.find_child("Player", true, false)
	assert(player != null, "Player node not found!")
	var body_root = player.find_child("BodyRoot", true, false)
	assert(body_root != null, "BodyRoot not found!")
	var camera: Camera3D = player.find_child("Camera3D", true, false)
	assert(camera != null, "Camera3D not found!")
	
	# Check 1: Player mesh visibility & valid materials
	assert(player.visible, "Player root must be visible!")
	assert(body_root.visible, "BodyRoot must be visible!")
	
	var torso: MeshInstance3D = body_root.find_child("Torso", true, false)
	assert(torso != null and torso.visible, "Torso mesh must exist and be visible!")
	var torso_mat = torso.get_surface_override_material(0)
	assert(torso_mat is StandardMaterial3D, "Torso must have a valid StandardMaterial3D!")
	assert(torso_mat.albedo_color.v > 0.8, "Torso must have high-value contrast against dark track!")
	assert(torso_mat.emission_enabled, "Torso must have emission enabled!")
	print("✔ Player mesh and high-contrast emissive materials verified.")

	# Check 2: Camera framing in viewport
	var vp_size = root.get_viewport().get_visible_rect().size
	var screen_pos = camera.unproject_position(player.global_position + Vector3(0, 0.9, 0))
	var norm_y = screen_pos.y / vp_size.y
	assert(norm_y >= 0.4 and norm_y <= 0.72, "Player must be framed in the lower-middle portion of the screen! (Current norm_y: %.2f)" % norm_y)
	print("✔ Player camera framing verified: Centered at %.1f%% screen height (Screen Y: %.1f / %.1f)" % [norm_y * 100.0, screen_pos.y, vp_size.y])

	# Check 3: Visibility during sliding
	player._try_slide()
	for i in range(15):
		player._physics_process(0.016)
		player._update_procedural_animations(0.016)
	assert(player.is_sliding, "Player should be sliding!")
	assert(body_root.visible, "BodyRoot must remain visible during sliding!")
	assert(body_root.global_position.y >= -0.05, "BodyRoot must not sink beneath the floor during slide!")
	var slide_screen_pos = camera.unproject_position(player.global_position + Vector3(0, 0.4, 0))
	var slide_norm_y = slide_screen_pos.y / vp_size.y
	assert(slide_norm_y >= 0.4 and slide_norm_y <= 0.8, "Player must remain visible on screen while sliding!")
	print("✔ Sliding visibility verified: Mesh remains visible and above floor (Y = %.2f)" % body_root.global_position.y)

	# Check 4: Visibility during jumping
	player._end_slide()
	player.velocity.y = player.JUMP_VELOCITY
	for i in range(10):
		player._physics_process(0.016)
		player._update_procedural_animations(0.016)
	assert(player.velocity.y != 0.0, "Player must be in jump arc!")
	assert(body_root.visible, "BodyRoot must remain visible during jumping!")
	var jump_screen_pos = camera.unproject_position(player.global_position + Vector3(0, 0.9, 0))
	var jump_norm_y = jump_screen_pos.y / vp_size.y
	assert(jump_norm_y > 0.1 and jump_norm_y < 0.9, "Player must remain in view during jump arc!")
	print("✔ Jumping visibility verified: Visible throughout jump arc (Y = %.2f)" % player.global_position.y)

	print("\nALL VISIBILITY CHECKS PASSED SUCCESSFULLY! PLAYER IS 100% VISIBLE.")
	print("--- END PLAYER VISIBILITY VERIFICATION TEST ---")
	quit(0)
