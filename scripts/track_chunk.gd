extends Node3D
class_name TrackChunk

const CHUNK_LENGTH: float = 60.0
const LANES: Array[float] = [-3.2, 0.0, 3.2]

# Obstacle Preloads
const SLIDE_BARRIER_SCENE = preload("res://scenes/obstacles/slide_barrier.tscn")
const JUMP_HURDLE_SCENE = preload("res://scenes/obstacles/jump_hurdle.tscn")
const LANE_PILLAR_SCENE = preload("res://scenes/obstacles/lane_pillar.tscn")
const RISK_GATE_SCENE = preload("res://scenes/obstacles/risk_gate.tscn")
const ENERGY_ORB_SCENE = preload("res://scenes/energy_orb.tscn")

var is_risk_sector: bool = false
var risk_lane: int = 1

# Shared Materials for Megastructure Aesthetics
static var mat_dark_steel: StandardMaterial3D = null
static var mat_panel_floor: StandardMaterial3D = null
static var mat_curb_metal: StandardMaterial3D = null
static var mat_substructure: StandardMaterial3D = null
static var mat_cyan_recessed: StandardMaterial3D = null
static var mat_amber_accent: StandardMaterial3D = null
static var mat_tower_facade: StandardMaterial3D = null
static var mat_distant_silhouette: StandardMaterial3D = null
static var mat_window_slit: StandardMaterial3D = null
static var mat_cable: StandardMaterial3D = null

static func _init_materials() -> void:
	if mat_dark_steel != null:
		return
		
	# Dark industrial gunmetal with sleek metallic reflections
	mat_dark_steel = StandardMaterial3D.new()
	mat_dark_steel.albedo_color = Color(0.08, 0.09, 0.12)
	mat_dark_steel.metallic = 0.94
	mat_dark_steel.roughness = 0.22
	
	# Modular floor deck plate with micro-panel feel
	mat_panel_floor = StandardMaterial3D.new()
	mat_panel_floor.albedo_color = Color(0.055, 0.065, 0.085)
	mat_panel_floor.metallic = 0.90
	mat_panel_floor.roughness = 0.26
	
	# Raised curbs and structural perimeter metal
	mat_curb_metal = StandardMaterial3D.new()
	mat_curb_metal.albedo_color = Color(0.12, 0.14, 0.18)
	mat_curb_metal.metallic = 0.96
	mat_curb_metal.roughness = 0.18
	
	# Heavy underside framework in shadow
	mat_substructure = StandardMaterial3D.new()
	mat_substructure.albedo_color = Color(0.04, 0.05, 0.07)
	mat_substructure.metallic = 0.95
	mat_substructure.roughness = 0.45
	
	# Restrained electric cyan recessed illumination
	mat_cyan_recessed = StandardMaterial3D.new()
	mat_cyan_recessed.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_cyan_recessed.albedo_color = Color(0.15, 0.92, 1.0)
	
	# Amber hazard & energy warning accent
	mat_amber_accent = StandardMaterial3D.new()
	mat_amber_accent.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_amber_accent.albedo_color = Color(1.0, 0.72, 0.18)
	
	# Massive tower facade
	mat_tower_facade = StandardMaterial3D.new()
	mat_tower_facade.albedo_color = Color(0.05, 0.06, 0.09)
	mat_tower_facade.metallic = 0.92
	mat_tower_facade.roughness = 0.38
	
	# Distant atmospheric megastructure silhouette
	mat_distant_silhouette = StandardMaterial3D.new()
	mat_distant_silhouette.albedo_color = Color(0.035, 0.05, 0.075)
	mat_distant_silhouette.metallic = 0.85
	mat_distant_silhouette.roughness = 0.55
	
	# Distant vertical window light slits
	mat_window_slit = StandardMaterial3D.new()
	mat_window_slit.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat_window_slit.albedo_color = Color(0.2, 0.8, 1.0, 0.95)
	
	# Structural cables
	mat_cable = StandardMaterial3D.new()
	mat_cable.albedo_color = Color(0.18, 0.20, 0.24)
	mat_cable.metallic = 1.0
	mat_cable.roughness = 0.2

func setup(chunk_index: int, difficulty: float) -> void:
	_init_materials()
	_create_track_geometry()
	_create_scenery(chunk_index)
	
	# First two chunks: Smooth onboarding with immediate mechanic testing
	if chunk_index < 2:
		_spawn_intro_orbs()
		if chunk_index == 0:
			# Starting area: prominent overhead grapple anchor right in view + left wall-run
			_create_grapple_anchor(Vector3(0, 6.2, 0))
			_create_wall_run_wall(-5.8, -20.0, 36.0, 5.5)
			_create_side_platform_and_ramps(-5.8, -20.0, 36.0)
		elif chunk_index == 1:
			# Chunk 1: grapple anchor + right wall-run + elevated double-jump platform
			_create_grapple_anchor(Vector3(0, 6.2, -15))
			_create_wall_run_wall(5.8, -22.0, 36.0, 5.5)
			_create_side_platform_and_ramps(5.8, -22.0, 36.0)
			_create_elevated_platform(0.0, 2.2, -10.0, 16.0)
		return
		
	# Decide pattern based on index and difficulty
	if chunk_index % 5 == 0:
		_spawn_risk_reward_pattern()
	else:
		_spawn_procedural_pattern(chunk_index, difficulty)

func _create_track_geometry() -> void:
	# 1. Main Ground Physics Collider (12.0m width, 1.0m thickness, 60m length at y = -0.5)
	var static_body = StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(12.0, 1.0, CHUNK_LENGTH)
	col_shape.shape = box
	col_shape.position = Vector3(0, -0.5, 0)
	static_body.add_child(col_shape)
	add_child(static_body)
	
	# 2. Suspended Platform Deck Structure
	var deck = MeshInstance3D.new()
	var deck_mesh = BoxMesh.new()
	deck_mesh.size = Vector3(11.6, 0.3, CHUNK_LENGTH)
	deck.mesh = deck_mesh
	deck.position = Vector3(0, -0.15, 0)
	deck.material_override = mat_panel_floor
	add_child(deck)
	
	# Transverse expansion seams every 15 meters
	for z_seam in [-22.5, -7.5, 7.5, 22.5]:
		var seam = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(11.8, 0.02, 0.2)
		seam.mesh = s_mesh
		seam.position = Vector3(0, 0.01, z_seam)
		seam.material_override = mat_substructure
		add_child(seam)
	
	# 3. Recessed Cyan Lane Dividers
	for div_x in [-1.6, 1.6]:
		var channel = MeshInstance3D.new()
		var ch_mesh = BoxMesh.new()
		ch_mesh.size = Vector3(0.18, 0.02, CHUNK_LENGTH)
		channel.mesh = ch_mesh
		channel.position = Vector3(div_x, 0.005, 0)
		channel.material_override = mat_substructure
		add_child(channel)
		
		var strip = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.06, 0.02, CHUNK_LENGTH)
		strip.mesh = s_mesh
		strip.position = Vector3(div_x, 0.015, 0)
		strip.material_override = mat_cyan_recessed
		add_child(strip)
		
		for p_z in range(-25, 30, 10):
			var tick = MeshInstance3D.new()
			var t_mesh = BoxMesh.new()
			t_mesh.size = Vector3(0.14, 0.025, 0.8)
			tick.mesh = t_mesh
			tick.position = Vector3(div_x, 0.02, p_z)
			tick.material_override = mat_cyan_recessed
			add_child(tick)

	# 4. Containment Curbs (x = -5.8 and x = +5.8)
	for side_x in [-5.8, 5.8]:
		var dir_sign = 1.0 if side_x > 0 else -1.0
		
		var curb = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(0.65, 0.55, CHUNK_LENGTH)
		curb.mesh = c_mesh
		curb.position = Vector3(side_x, 0.25, 0)
		curb.material_override = mat_curb_metal
		add_child(curb)
		
		var inner_light = MeshInstance3D.new()
		var il_mesh = BoxMesh.new()
		il_mesh.size = Vector3(0.05, 0.08, CHUNK_LENGTH)
		inner_light.mesh = il_mesh
		inner_light.position = Vector3(side_x - dir_sign * 0.3, 0.35, 0)
		inner_light.material_override = mat_cyan_recessed
		add_child(inner_light)

	# 5. Underside Mega-Spine & Cantilever Brackets
	var spine = MeshInstance3D.new()
	var sp_mesh = BoxMesh.new()
	sp_mesh.size = Vector3(4.5, 1.8, CHUNK_LENGTH)
	spine.mesh = sp_mesh
	spine.position = Vector3(0, -1.2, 0)
	spine.material_override = mat_substructure
	add_child(spine)
	
	for z_rib in [-20, 0, 20]:
		var rib = MeshInstance3D.new()
		var r_mesh = BoxMesh.new()
		r_mesh.size = Vector3(13.2, 0.7, 1.2)
		rib.mesh = r_mesh
		rib.position = Vector3(0, -0.65, z_rib)
		rib.material_override = mat_dark_steel
		add_child(rib)
		
	var pier = MeshInstance3D.new()
	var pier_mesh = CylinderMesh.new()
	pier_mesh.top_radius = 2.8
	pier_mesh.bottom_radius = 3.6
	pier_mesh.height = 140.0
	pier_mesh.radial_segments = 12
	pier.mesh = pier_mesh
	pier.position = Vector3(0, -70.0, 0)
	pier.material_override = mat_substructure
	add_child(pier)

# ═══════════════════════════════════════════════════════════════
#  PARKOUR COMPONENTS: GRAPPLE ANCHORS, WALL-RUN WALLS, RAMPS
# ═══════════════════════════════════════════════════════════════

func _create_grapple_anchor(pos: Vector3) -> Node3D:
	var anchor_root = Node3D.new()
	anchor_root.position = pos
	anchor_root.name = "GrappleAnchor"
	
	# Visual mounting ring (emissive cyan)
	var ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.7
	ring_mesh.outer_radius = 1.4
	ring.mesh = ring_mesh
	ring.rotation.x = PI * 0.5
	ring.material_override = mat_cyan_recessed
	anchor_root.add_child(ring)

	# Inner concentric counter-aligned ring
	var inner_ring = MeshInstance3D.new()
	var ir_mesh = TorusMesh.new()
	ir_mesh.inner_radius = 0.25
	ir_mesh.outer_radius = 0.5
	inner_ring.mesh = ir_mesh
	inner_ring.rotation.y = PI * 0.25
	inner_ring.material_override = mat_cyan_recessed
	anchor_root.add_child(inner_ring)
	
	# Heavy dark steel bracket with hazard winglets
	var bracket = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(3.6, 0.45, 0.8)
	bracket.mesh = b_mesh
	bracket.material_override = mat_dark_steel
	anchor_root.add_child(bracket)

	for bx in [-1.7, 1.7]:
		var hazard_tip = MeshInstance3D.new()
		var ht_mesh = BoxMesh.new()
		ht_mesh.size = Vector3(0.25, 0.55, 0.85)
		hazard_tip.mesh = ht_mesh
		hazard_tip.position = Vector3(bx, 0, 0)
		hazard_tip.material_override = mat_amber_accent
		anchor_root.add_child(hazard_tip)
	
	# Amber beacon core in center
	var core = MeshInstance3D.new()
	var c_mesh = SphereMesh.new()
	c_mesh.radius = 0.35
	c_mesh.height = 0.7
	core.mesh = c_mesh
	core.material_override = mat_amber_accent
	anchor_root.add_child(core)

	# OmniLight3D beacon highlight
	var beacon_light = OmniLight3D.new()
	beacon_light.light_color = Color(0.2, 0.9, 1.0)
	beacon_light.light_energy = 1.4
	beacon_light.omni_range = 14.0
	beacon_light.position = Vector3(0, -0.6, 0)
	anchor_root.add_child(beacon_light)
	
	# Solid physics body on layer 1 in group "grapple_anchor"
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group("grapple_anchor")
	body.set_meta("is_grapple_anchor", true)
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.4, 2.0, 3.4)
	col.shape = box
	body.add_child(col)
	anchor_root.add_child(body)
	
	add_child(anchor_root)
	return anchor_root

func _create_wall_run_wall(x_pos: float, z_start: float, z_length: float, height: float = 5.5) -> Node3D:
	var wall_root = Node3D.new()
	wall_root.name = "WallRunWall"
	var z_center = z_start + (z_length * 0.5)
	wall_root.position = Vector3(x_pos, height * 0.5, z_center)
	
	# 1. Main Wall Mesh Slab
	var wall_mesh = MeshInstance3D.new()
	var box_m = BoxMesh.new()
	box_m.size = Vector3(0.5, height, z_length)
	wall_mesh.mesh = box_m
	wall_mesh.material_override = mat_dark_steel
	wall_root.add_child(wall_mesh)
	
	# 2. Glowing Cyan Running Guide Strips (signals wall-runnable surface)
	var dir_facing = -1.0 if x_pos > 0 else 1.0
	for strip_y in [-height * 0.22, height * 0.15]:
		var strip = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.08, 0.14, z_length * 0.96)
		strip.mesh = s_mesh
		strip.position = Vector3(dir_facing * 0.27, strip_y, 0)
		strip.material_override = mat_cyan_recessed
		wall_root.add_child(strip)
		
	# 3. Top reinforced framing trim
	var top_trim = MeshInstance3D.new()
	var tt_mesh = BoxMesh.new()
	tt_mesh.size = Vector3(0.62, 0.18, z_length)
	top_trim.mesh = tt_mesh
	top_trim.position = Vector3(0, height * 0.5 + 0.08, 0)
	top_trim.material_override = mat_curb_metal
	wall_root.add_child(top_trim)

	# 4. Vertical structural ribs and distinct entry/exit hazard beacons
	for z_rib in [-z_length * 0.48, 0.0, z_length * 0.48]:
		var rib = MeshInstance3D.new()
		var r_mesh = BoxMesh.new()
		r_mesh.size = Vector3(0.68, height + 0.35, 0.55)
		rib.mesh = r_mesh
		rib.position = Vector3(0, 0, z_rib)
		rib.material_override = mat_substructure
		wall_root.add_child(rib)
		
		var hazard = MeshInstance3D.new()
		var h_mesh = BoxMesh.new()
		h_mesh.size = Vector3(0.35, 0.45, 0.45)
		hazard.mesh = h_mesh
		hazard.position = Vector3(dir_facing * 0.36, height * 0.5 + 0.1, z_rib)
		hazard.material_override = mat_amber_accent
		wall_root.add_child(hazard)

		# Vertical illuminated pylon at entry/exit points
		if absf(z_rib) > 1.0:
			var pylon_light = MeshInstance3D.new()
			var pl_mesh = BoxMesh.new()
			pl_mesh.size = Vector3(0.12, height * 0.8, 0.12)
			pylon_light.mesh = pl_mesh
			pylon_light.position = Vector3(dir_facing * 0.38, 0, z_rib)
			pylon_light.material_override = mat_amber_accent
			wall_root.add_child(pylon_light)
		
	# 4. Solid Physics Collider for Wall Running
	var static_body = StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	static_body.add_to_group("wall_run_surface")
	static_body.set_meta("is_wall_run_surface", true)
	
	var col = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(0.65, height, z_length)
	col.shape = box_col
	static_body.add_child(col)
	wall_root.add_child(static_body)
	
	add_child(wall_root)
	return wall_root

func _create_side_platform_and_ramps(x_side: float, z_start: float, z_length: float) -> void:
	var width = 2.4
	var p_x = (x_side + (0.5 * width)) if x_side > 0 else (x_side - (0.5 * width))
	var z_center = z_start + (z_length * 0.5)
	
	# Side landing platform at y = 0.0
	var platform = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(width, 0.3, z_length)
	platform.mesh = p_mesh
	platform.position = Vector3(p_x, -0.15, z_center)
	platform.material_override = mat_panel_floor
	add_child(platform)
	
	# Solid physics floor for side platform
	var p_body = StaticBody3D.new()
	p_body.collision_layer = 1
	p_body.collision_mask = 0
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, 1.0, z_length)
	col.shape = box
	col.position = Vector3(p_x, -0.5, z_center)
	p_body.add_child(col)
	add_child(p_body)
	
	# Connecting return ramp: angled transition funnelling back into main track at exit
	var ramp = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(2.0, 0.28, 6.0)
	ramp.mesh = r_mesh
	var ramp_x = x_side * 0.65
	var ramp_z = z_start - 3.0 # toward negative Z (exit)
	ramp.position = Vector3(ramp_x, -0.14, ramp_z)
	ramp.rotation.y = (PI * 0.08) if x_side > 0 else (-PI * 0.08)
	ramp.material_override = mat_panel_floor
	add_child(ramp)
	
	var r_body = StaticBody3D.new()
	r_body.collision_layer = 1
	r_body.collision_mask = 0
	var r_col = CollisionShape3D.new()
	var r_box = BoxShape3D.new()
	r_box.size = Vector3(2.2, 1.0, 6.0)
	r_col.shape = r_box
	r_col.position = ramp.position + Vector3(0, -0.38, 0)
	r_col.rotation.y = ramp.rotation.y
	r_body.add_child(r_col)
	add_child(r_body)

func _create_elevated_platform(x_pos: float, y_pos: float, z_start: float, z_length: float) -> void:
	var width = 3.4
	var z_center = z_start + (z_length * 0.5)
	
	# Visual deck
	var deck = MeshInstance3D.new()
	var d_mesh = BoxMesh.new()
	d_mesh.size = Vector3(width, 0.3, z_length)
	deck.mesh = d_mesh
	deck.position = Vector3(x_pos, y_pos - 0.15, z_center)
	deck.material_override = mat_panel_floor
	add_child(deck)
	
	# Glowing edge trims
	for ex in [-width * 0.5 + 0.05, width * 0.5 - 0.05]:
		var trim = MeshInstance3D.new()
		var t_mesh = BoxMesh.new()
		t_mesh.size = Vector3(0.08, 0.08, z_length)
		trim.mesh = t_mesh
		trim.position = Vector3(x_pos + ex, y_pos + 0.02, z_center)
		trim.material_override = mat_cyan_recessed
		add_child(trim)
		
	# Solid physics collider
	var body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, 0.5, z_length)
	col.shape = box
	col.position = Vector3(x_pos, y_pos - 0.25, z_center)
	body.add_child(col)
	add_child(body)
	
	# Golden energy orbs along elevated platform
	for oz in range(int(z_start + 3), int(z_start + z_length - 2), 4):
		var orb = ENERGY_ORB_SCENE.instantiate()
		orb.position = Vector3(x_pos, y_pos + 0.8, float(oz))
		orb.is_golden = true
		add_child(orb)

# ═══════════════════════════════════════════════════════════════
#  SCENERY & PROCEDURAL PATTERNS
# ═══════════════════════════════════════════════════════════════

func _create_scenery(chunk_idx: int) -> void:
	# Archways with overhead grapple anchors at z = ±18m
	for z_pos in [-18.0, 18.0]:
		var arch = Node3D.new()
		arch.position = Vector3(0, 0, z_pos)
		
		# Overhead beam
		var beam = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(14.6, 0.9, 1.2)
		beam.mesh = b_mesh
		beam.position = Vector3(0, 5.8, 0)
		beam.material_override = mat_dark_steel
		arch.add_child(beam)
		
		# Recessed downward illumination strip
		var flood = MeshInstance3D.new()
		var fl_mesh = BoxMesh.new()
		fl_mesh.size = Vector3(11.0, 0.08, 0.25)
		flood.mesh = fl_mesh
		flood.position = Vector3(0, 5.32, 0)
		flood.material_override = mat_cyan_recessed
		arch.add_child(flood)
		
		# Vertical columns
		for px in [-6.8, 6.8]:
			var col = MeshInstance3D.new()
			var c_mesh = BoxMesh.new()
			c_mesh.size = Vector3(1.2, 6.4, 1.4)
			col.mesh = c_mesh
			col.position = Vector3(px, 2.9, 0)
			col.material_override = mat_dark_steel
			arch.add_child(col)
			
			var caution = MeshInstance3D.new()
			var ct_mesh = BoxMesh.new()
			ct_mesh.size = Vector3(0.2, 0.5, 0.2)
			caution.mesh = ct_mesh
			caution.position = Vector3(px + (0.55 if px > 0 else -0.55), 1.6, 0)
			caution.material_override = mat_amber_accent
			arch.add_child(caution)
			
		add_child(arch)
		# Designated Grapple Anchor attached to every arch beam
		_create_grapple_anchor(Vector3(0, 6.4, z_pos))

	# Midground megastructure towers
	var side_toggle = 1.0 if (chunk_idx % 2 == 0) else -1.0
	var tower_x = side_toggle * 34.0
	
	var tower = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(16.0, 160.0, 22.0)
	tower.mesh = t_mesh
	tower.position = Vector3(tower_x, 40.0, 0)
	tower.material_override = mat_tower_facade
	add_child(tower)
	
	for wx in [-4.0, 0.0, 4.0]:
		var slit = MeshInstance3D.new()
		var sl_mesh = BoxMesh.new()
		sl_mesh.size = Vector3(0.4, 110.0, 0.3)
		slit.mesh = sl_mesh
		var face_offset = -8.1 if tower_x > 0 else 8.1
		slit.position = Vector3(tower_x + face_offset, 40.0, wx)
		slit.material_override = mat_window_slit
		add_child(slit)

	# Distant colossal horizon towers in fog
	for dist_x in [-75.0, 75.0]:
		var bg_tower = MeshInstance3D.new()
		var bt_mesh = BoxMesh.new()
		bt_mesh.size = Vector3(28.0, 240.0, 36.0)
		bg_tower.mesh = bt_mesh
		bg_tower.position = Vector3(dist_x, 70.0, -10.0 if dist_x > 0 else 10.0)
		bg_tower.material_override = mat_distant_silhouette
		add_child(bg_tower)

		for bz in [-8.0, 0.0, 8.0]:
			var bg_slit = MeshInstance3D.new()
			var bs_mesh = BoxMesh.new()
			bs_mesh.size = Vector3(0.5, 140.0, 0.4)
			bg_slit.mesh = bs_mesh
			var slit_face_x = -14.1 if dist_x > 0 else 14.1
			bg_slit.position = Vector3(dist_x + slit_face_x, 70.0, bz)
			bg_slit.material_override = mat_window_slit
			add_child(bg_slit)

	if chunk_idx % 2 == 0:
		var skybridge = MeshInstance3D.new()
		var sb_mesh = BoxMesh.new()
		sb_mesh.size = Vector3(160.0, 5.0, 7.0)
		skybridge.mesh = sb_mesh
		skybridge.position = Vector3(0, 36.0, 0.0)
		skybridge.material_override = mat_tower_facade
		add_child(skybridge)

		var conduit = MeshInstance3D.new()
		var cd_mesh = CylinderMesh.new()
		cd_mesh.top_radius = 0.8
		cd_mesh.bottom_radius = 0.8
		cd_mesh.height = 160.0
		conduit.mesh = cd_mesh
		conduit.rotation.z = PI * 0.5
		conduit.position = Vector3(0, 32.5, 2.5)
		conduit.material_override = mat_cable
		add_child(conduit)

func _spawn_intro_orbs() -> void:
	for z_offset in range(-20, 25, 10):
		var orb = ENERGY_ORB_SCENE.instantiate()
		orb.position = Vector3(0, 1.0, z_offset)
		add_child(orb)

func _spawn_procedural_pattern(chunk_idx: int, _diff: float) -> void:
	var pattern_type = (chunk_idx % 4)
	
	match pattern_type:
		0:
			# PATTERN 0 — SLIDE, GRAPPLE & LEFT WALL-RUN:
			# Low slide barrier in center with clearance beneath
			var slide_obs = SLIDE_BARRIER_SCENE.instantiate()
			slide_obs.position = Vector3(LANES[1], 0, -8)
			add_child(slide_obs)
			
			# Overhead grapple anchor allowing grapple swing directly over the barrier
			_create_grapple_anchor(Vector3(0, 6.2, -8))
			
			# Left wall-run section with connecting ramps
			_create_wall_run_wall(-5.8, -22.0, 38.0, 5.5)
			_create_side_platform_and_ramps(-5.8, -22.0, 38.0)
			
			# Energy Orbs rewarding clean traversal
			for oz in [-14, -20]:
				var orb = ENERGY_ORB_SCENE.instantiate()
				orb.position = Vector3(LANES[1], 0.6, oz)
				add_child(orb)
				
		1:
			# PATTERN 1 — JUMP, DOUBLE JUMP & RIGHT WALL-RUN:
			# Ground hurdle requiring jump
			var hurdle = JUMP_HURDLE_SCENE.instantiate()
			hurdle.position = Vector3(LANES[1], 0, -4)
			add_child(hurdle)
			
			# Elevated sky-runner platform reachable via Double Jump or Grapple
			_create_elevated_platform(LANES[0], 2.4, -20.0, 18.0)
			
			# Right wall-run wall spanning the chunk
			_create_wall_run_wall(5.8, -22.0, 38.0, 5.5)
			_create_side_platform_and_ramps(5.8, -22.0, 38.0)
			
			# Overhead grapple anchor
			_create_grapple_anchor(Vector3(LANES[1], 6.2, -4))
			
		2:
			# PATTERN 2 — DUAL WALL-RUN ARENA & GAP TRAVERSE:
			# Both left and right wall-run walls active!
			_create_wall_run_wall(-5.8, -24.0, 44.0, 5.5)
			_create_side_platform_and_ramps(-5.8, -24.0, 44.0)
			_create_wall_run_wall(5.8, -24.0, 44.0, 5.5)
			_create_side_platform_and_ramps(5.8, -24.0, 44.0)
			
			# Slide barrier and ground hurdle in alternating lanes
			var slide = SLIDE_BARRIER_SCENE.instantiate()
			slide.position = Vector3(LANES[1], 0, 6)
			add_child(slide)
			
			var hurdle = JUMP_HURDLE_SCENE.instantiate()
			hurdle.position = Vector3(LANES[2], 0, -12)
			add_child(hurdle)
			
			# Grapple anchors for fluid aerial transfers
			_create_grapple_anchor(Vector3(0, 6.2, -3))
			
		3:
			# PATTERN 3 — SLALOM, BOOST & RECOVERY TRAVERSE:
			var pil1 = LANE_PILLAR_SCENE.instantiate()
			pil1.position = Vector3(LANES[0], 0, 12)
			add_child(pil1)
			
			var pil2 = LANE_PILLAR_SCENE.instantiate()
			pil2.position = Vector3(LANES[2], 0, -6)
			add_child(pil2)
			
			# Overhead grapple anchor allowing straight flight over pillars
			_create_grapple_anchor(Vector3(0, 6.2, 3))
			
			# Left wall-run section
			_create_wall_run_wall(-5.8, -20.0, 36.0, 5.5)
			_create_side_platform_and_ramps(-5.8, -20.0, 36.0)
			
			# Energy trail zig-zagging through slalom
			var orb1 = ENERGY_ORB_SCENE.instantiate()
			orb1.position = Vector3(LANES[1], 1.0, 8)
			add_child(orb1)
			var orb2 = ENERGY_ORB_SCENE.instantiate()
			orb2.position = Vector3(LANES[0], 1.0, -8)
			add_child(orb2)
			var orb3 = ENERGY_ORB_SCENE.instantiate()
			orb3.position = Vector3(LANES[2], 1.0, -22)
			add_child(orb3)

func _spawn_risk_reward_pattern() -> void:
	is_risk_sector = true
	risk_lane = 1 if randf() > 0.5 else -1
	var risk_lane_actual = 2 if risk_lane > 0 else 0
	var safe_lane_actual = 1 # Center
	
	# Spawn overhead Risk Gate archway at chunk entrance (z = +25)
	var gate = RISK_GATE_SCENE.instantiate()
	gate.position = Vector3(0, 0, 25)
	gate.risk_lane_index = risk_lane
	add_child(gate)
	
	# Overhead grapple anchors for high-speed parkour
	_create_grapple_anchor(Vector3(0, 6.2, 5))
	_create_grapple_anchor(Vector3(0, 6.2, -15))
	
	# Wall run on the non-risk side providing bypass
	var wall_x = -5.8 if risk_lane_actual == 2 else 5.8
	_create_wall_run_wall(wall_x, -22.0, 40.0, 5.5)
	_create_side_platform_and_ramps(wall_x, -22.0, 40.0)
	
	# 1. RISK LANE:
	var slide_risk = SLIDE_BARRIER_SCENE.instantiate()
	slide_risk.position = Vector3(LANES[risk_lane_actual], 0, 10)
	slide_risk.is_high_risk = true
	add_child(slide_risk)
	
	var hurdle_risk = JUMP_HURDLE_SCENE.instantiate()
	hurdle_risk.position = Vector3(LANES[risk_lane_actual], 0, -12)
	hurdle_risk.is_high_risk = true
	add_child(hurdle_risk)
	
	# Golden Energy Orbs in risk lane
	for oz in [18, 2, -5, -20, -26]:
		var g_orb = ENERGY_ORB_SCENE.instantiate()
		g_orb.is_golden = true
		g_orb.position = Vector3(LANES[risk_lane_actual], 1.0 if oz != -12 else 2.2, oz)
		add_child(g_orb)
		
	# 2. SAFE LANE (Center):
	for oz in [5, -15]:
		var s_orb = ENERGY_ORB_SCENE.instantiate()
		s_orb.position = Vector3(LANES[safe_lane_actual], 1.0, oz)
		add_child(s_orb)
