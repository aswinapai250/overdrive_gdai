extends CharacterBody3D
class_name Player

# ============================================================
# OVERDRIVE — Integrated 5-Mechanic Movement Controller
# Slide · Dash · Double Jump · Wall Run · Grappling Hook
# ============================================================

signal speed_changed(current_speed: float, max_speed: float)
signal energy_changed(current_energy: float, max_energy: float)
signal shields_changed(current_shields: int, max_shields: int)
signal multiplier_changed(multiplier: float)
signal score_changed(score: int, distance: float)
signal player_crashed(reason: String)
signal action_feedback(text: String, color: Color)
signal dash_cooldown_changed(ratio: float)
signal coins_changed(coins: int)
signal camera_mode_changed(is_fpp: bool)
signal rewind_state_changed(is_active: bool, available_ratio: float)

# ── Lane Configuration ────────────────────────────────────────
const LANE_WIDTH: float = 3.2
const LANES: Array[float] = [-3.2, 0.0, 3.2]
var current_lane_idx: int = 0
var target_x: float = 0.0

# ── Speed & Momentum ──────────────────────────────────────────
const BASE_SPEED: float       = 18.0
const MAX_NORMAL_SPEED: float = 28.0
const BOOST_SPEED: float      = 38.0
const MIN_SPEED: float        = 9.0
const SPEED_ACCEL: float      = 0.8

var forward_speed: float      = BASE_SPEED
var momentum_multiplier: float = 1.0
var max_multiplier: float     = 4.0
var clean_run_timer: float    = 0.0

# ── Boost ─────────────────────────────────────────────────────
var energy: float             = 50.0
const MAX_ENERGY: float       = 100.0
const BOOST_CONSUMPTION_RATE: float = 22.0
var is_boosting: bool         = false

# ── Gravity & Jump ────────────────────────────────────────────
const GRAVITY: float          = 26.0
const JUMP_VELOCITY: float    = 10.5
const COYOTE_TIME: float      = 0.12
const JUMP_BUFFER: float      = 0.12

var coyote_timer: float       = 0.0
var jump_buffer_timer: float  = 0.0

# ── Double Jump ───────────────────────────────────────────────
const DOUBLE_JUMP_VELOCITY: float = 9.0
var air_jumps_used: int       = 0
const MAX_AIR_JUMPS: int      = 1
var double_jump_particles: CPUParticles3D = null

# ── Slide ─────────────────────────────────────────────────────
var is_sliding: bool          = false
var slide_timer: float        = 0.0
const SLIDE_DURATION: float   = 0.7
var slide_cooldown_timer: float = 0.0
const SLIDE_COOLDOWN: float   = 0.15
var normal_capsule_height: float = 1.8
var slide_capsule_height: float  = 0.65

# ── Dash ──────────────────────────────────────────────────────
const DASH_DURATION: float    = 0.20
const DASH_SPEED: float       = 52.0
const DASH_COOLDOWN: float    = 1.0
var is_dashing: bool          = false
var dash_timer: float         = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector3   = Vector3.ZERO
var dash_particles: CPUParticles3D = null

# ── Wall Run ──────────────────────────────────────────────────
const WALL_RUN_DURATION: float        = 1.4
const WALL_RUN_GRAVITY_SCALE: float   = 0.18
const WALL_RUN_SPEED: float           = 22.0
const WALL_JUMP_VELOCITY_Y: float     = 9.5
const WALL_JUMP_VELOCITY_AWAY: float  = 7.5
const WALL_DETECT_DIST: float         = 1.2
var is_wall_running: bool             = false
var wall_run_timer: float             = 0.0
var wall_run_cooldown_timer: float    = 0.0
var wall_run_side: int                = 0      # -1 = left, +1 = right
var wall_normal: Vector3              = Vector3.ZERO
var wall_run_particles: CPUParticles3D = null
var wall_cast_left: RayCast3D         = null
var wall_cast_right: RayCast3D        = null

# ── Grappling Hook ────────────────────────────────────────────
const GRAPPLE_RANGE: float            = 26.0
const GRAPPLE_PULL_FORCE: float       = 40.0
const GRAPPLE_MAX_SPEED: float        = 30.0
const GRAPPLE_MIN_DIST: float         = 2.5
var is_grappling: bool                = false
var grapple_anchor: Vector3           = Vector3.ZERO
var grapple_rope: MeshInstance3D      = null
var grapple_launched: bool            = false
var grapple_target_node: Node         = null

# ── Player Stats ──────────────────────────────────────────────
var max_shields: int          = 3
var shields: int              = 3
var score: int                = 0
var coins: int                = 0
var distance_traveled: float   = 0.0
var is_dead: bool             = false
var invincibility_timer: float = 0.0

# ── Risk-Reward ───────────────────────────────────────────────
var in_risk_sector: bool      = false
var risk_lane_idx: int        = 1
var risk_multiplier: float    = 1.0
var orbs_towards_shield: int  = 0

# ── Node References ───────────────────────────────────────────
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var overhead_raycast: RayCast3D       = $OverheadRayCast
@onready var body_root: Node3D                 = $BodyRoot
@onready var thruster_particles: CPUParticles3D = $BodyRoot/ThrusterParticles
@onready var slide_sparks: CPUParticles3D      = $SlideSparks
@onready var landing_particles: CPUParticles3D = $LandingParticles
@onready var camera: Camera3D                  = $CameraRig/Camera3D
@onready var camera_rig: Node3D               = $CameraRig
@onready var speed_lines: CPUParticles3D       = $CameraRig/Camera3D/SpeedLines

# ── Audio ─────────────────────────────────────────────────────
var audio_synth: AudioSynthesizer = null

# ── Visual animation state ────────────────────────────────────
var run_cycle_time: float     = 0.0
var landing_squash: float     = 0.0
var camera_shake: float       = 0.0

# ── Camera Perspective (FPP / TPP) ───────────────────────────
const CAM_POS_TPP := Vector3(0.0, 2.1, 4.2)
const CAM_ROT_X_TPP := -0.192
const CAM_POS_FPP := Vector3(0.0, 1.45, -0.15)
const CAM_ROT_X_FPP := -0.05
const CAM_FOV_BASE_TPP := 74.0
const CAM_FOV_BASE_FPP := 82.0

var is_fpp: bool = false
var camera_transition_weight: float = 0.0

# ── Time Rewind ───────────────────────────────────────────────
@export var max_history_duration: float = 3.0
@export var rewind_speed_mult: float    = 2.5
var history_buffer: Array[Dictionary]   = []
var history_duration: float             = 0.0
var is_rewinding: bool                  = false
var rewind_particles: CPUParticles3D    = null
var rewind_audio_timer: float           = 0.0

# ── Run Starting Point Boundary ──────────────────────────────
var run_start_position: Vector3         = Vector3.ZERO
var run_start_distance: float           = 0.0
var run_start_recorded: bool            = false

# ═══════════════════════════════════════════════════════════════
#  READY
# ═══════════════════════════════════════════════════════════════
func _ready() -> void:
	add_to_group("player")
	target_x = LANES[current_lane_idx + 1]

	audio_synth = get_tree().root.find_child("AudioSynthesizer", true, false)

	_setup_dash_particles()
	_setup_double_jump_particles()
	_setup_wall_run_raycasts()
	_setup_wall_run_particles()
	_setup_grapple_rope()
	_setup_rewind_particles()

	run_start_position = global_position
	run_start_distance = distance_traveled
	run_start_recorded = true

	emit_signal("speed_changed", forward_speed, BOOST_SPEED)
	emit_signal("energy_changed", energy, MAX_ENERGY)
	emit_signal("shields_changed", shields, max_shields)
	emit_signal("multiplier_changed", momentum_multiplier)
	emit_signal("score_changed", score, distance_traveled)
	emit_signal("coins_changed", coins)
	emit_signal("camera_mode_changed", is_fpp)
	emit_signal("rewind_state_changed", false, 0.0)

# ═══════════════════════════════════════════════════════════════
#  INPUT HANDLING
# ═══════════════════════════════════════════════════════════════
func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	# Grapple: [E] or action "grapple"
	if event.is_action_pressed("grapple") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		_try_grapple()
		get_viewport().set_input_as_handled()
		return

	# Jump: [Space], [W], [Up], or action "jump"
	if event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_W or event.keycode == KEY_UP)):
		if is_grappling:
			_release_grapple()
			velocity.y = JUMP_VELOCITY * 0.75
		jump_buffer_timer = JUMP_BUFFER
		get_viewport().set_input_as_handled()
		return

	# Slide: [S], [Down], or action "slide"
	if event.is_action_pressed("slide") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_S or event.keycode == KEY_DOWN)):
		_try_slide()
		get_viewport().set_input_as_handled()
		return

	# Dash: [Left Shift] tap
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
		_try_dash()
		get_viewport().set_input_as_handled()
		return

	# Toggle Camera Perspective (TPP / FPP): [V] or action "toggle_camera"
	if event.is_action_pressed("toggle_camera") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V):
		toggle_camera_mode()
		get_viewport().set_input_as_handled()
		return

	# Time Rewind: [R] or action "rewind"
	if event.is_action_pressed("rewind") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R):
		if not is_rewinding and can_rewind():
			_start_rewind()
			get_viewport().set_input_as_handled()
			return
	elif event.is_action_released("rewind") or (event is InputEventKey and not event.pressed and event.keycode == KEY_R):
		if is_rewinding:
			_stop_rewind()
			get_viewport().set_input_as_handled()
			return

	if is_rewinding:
		return

# ═══════════════════════════════════════════════════════════════
#  PHYSICS PROCESS
# ═══════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Handle Continuous Rewind Hold Check
	var rewind_held: bool = Input.is_action_pressed("rewind") or Input.is_key_pressed(KEY_R)
	if rewind_held and not is_rewinding and can_rewind():
		_start_rewind()
	elif not rewind_held and is_rewinding:
		_stop_rewind()

	if is_rewinding:
		_process_rewind(delta)
		return

	# ── 1. Tick Timers ─────────────────────────────────────────
	coyote_timer            = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer       = maxf(0.0, jump_buffer_timer - delta)
	slide_cooldown_timer    = maxf(0.0, slide_cooldown_timer - delta)
	wall_run_cooldown_timer = maxf(0.0, wall_run_cooldown_timer - delta)

	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		if not is_fpp:
			_update_invincibility_visual(delta)
	elif not is_fpp and camera_transition_weight <= 0.45:
		body_root.visible = true

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
		emit_signal("dash_cooldown_changed", dash_cooldown_timer / DASH_COOLDOWN)

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			_end_dash()

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			_end_slide()

	if is_wall_running:
		wall_run_timer -= delta
		if wall_run_timer <= 0.0:
			_end_wall_run(false)

	# ── 2. Ground Detection ────────────────────────────────────
	var grounded: bool = is_on_floor()
	if grounded:
		coyote_timer = COYOTE_TIME
		air_jumps_used = 0
		if velocity.y < -3.0:
			_on_land()
		if is_wall_running:
			_end_wall_run(false)

	# ── 3. Gravity ─────────────────────────────────────────────
	if not grounded and not is_dashing:
		if is_wall_running:
			velocity.y -= GRAVITY * WALL_RUN_GRAVITY_SCALE * delta
			velocity.y = maxf(velocity.y, -3.5)
		elif is_grappling:
			# Gentle gravity during grapple so pull force controls flight
			velocity.y -= GRAVITY * 0.35 * delta
		else:
			velocity.y -= GRAVITY * delta

	# ── 4. Wall-Run Detection ──────────────────────────────────
	if not grounded and not is_dashing and not is_grappling and wall_run_cooldown_timer <= 0.0:
		_update_wall_run(delta)

	# ── 5. Jump Execution ──────────────────────────────────────
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			_execute_jump()
		elif is_wall_running:
			_execute_wall_jump()
		elif air_jumps_used < MAX_AIR_JUMPS and not grounded:
			_execute_double_jump()

	# ── 6. Boost ───────────────────────────────────────────────
	var boost_ok: bool = not is_dashing and not is_wall_running
	var boost_pressed: bool = boost_ok and (
		Input.is_action_pressed("boost") or
		Input.is_key_pressed(KEY_SHIFT) or
		Input.is_key_pressed(KEY_F) or
		Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	)
	if boost_pressed and energy > 1.0:
		if not is_boosting:
			is_boosting = true
			if audio_synth:
				audio_synth.play_sfx("boost", 1.0, 0.0)
		energy = maxf(0.0, energy - BOOST_CONSUMPTION_RATE * delta)
	else:
		is_boosting = false

	# ── 7. Speed Progression ───────────────────────────────────
	var target_fwd: float = BASE_SPEED
	if is_boosting:
		target_fwd = BOOST_SPEED
	else:
		target_fwd = lerpf(BASE_SPEED, MAX_NORMAL_SPEED,
			(momentum_multiplier - 1.0) / (max_multiplier - 1.0))

	forward_speed = move_toward(forward_speed, target_fwd, SPEED_ACCEL * 12.0 * delta)

	clean_run_timer += delta
	if clean_run_timer >= 2.5:
		clean_run_timer = 0.0
		_increase_multiplier(0.1)

	# ── 8. Velocity Composition & Steering ─────────────────────
	_apply_velocity(delta)

	# ── 9. Grapple Physics ─────────────────────────────────────
	if is_grappling:
		_update_grapple(delta)

	move_and_slide()

	# ── 10. Score & Signals ────────────────────────────────────
	var frame_dist: float = forward_speed * delta
	distance_traveled += frame_dist
	risk_multiplier = 3.0 if (in_risk_sector and current_lane_idx == risk_lane_idx) else 1.0
	score += int(frame_dist * 2.5 * momentum_multiplier * risk_multiplier)

	emit_signal("speed_changed", forward_speed, BOOST_SPEED)
	emit_signal("energy_changed", energy, MAX_ENERGY)
	emit_signal("score_changed", score, distance_traveled)

	# ── 11. Procedural Visuals & Camera ────────────────────────
	_update_procedural_animations(delta)
	_update_camera(delta)
	_update_grapple_rope()

	# ── 12. Record History Snapshot ────────────────────────────
	_record_snapshot(delta)

# ═══════════════════════════════════════════════════════════════
#  VELOCITY COMPOSITION & CENTRE-TRACK RETURN
# ═══════════════════════════════════════════════════════════════
func _apply_velocity(delta: float) -> void:
	if is_dashing:
		var saved_y := velocity.y
		velocity = dash_direction * DASH_SPEED
		velocity.y = saved_y
		target_x = position.x
		return

	if is_wall_running:
		velocity.z = -forward_speed
		velocity.x = 0.0
		return

	if is_grappling:
		target_x = position.x
		return

	velocity.z = -forward_speed

	var steer_input: float = 0.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_input -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_input += 1.0

	var max_boundary_x: float = 7.5 if absf(position.x) > 5.3 else 5.2
	var lateral_speed: float = 10.5 if is_on_floor() else 8.5

	if steer_input != 0.0:
		target_x = clampf(target_x + steer_input * lateral_speed * delta, -max_boundary_x, max_boundary_x)
		position.x = lerpf(position.x, target_x, delta * 14.0)
		velocity.x = (target_x - position.x) * 14.0
	else:
		# If target_x was set explicitly by _change_lane, wall jump, or center return:
		if absf(target_x - position.x) > 0.02:
			position.x = lerpf(position.x, target_x, delta * 12.0)
			velocity.x = (target_x - position.x) * 12.0
		else:
			target_x = position.x
			velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)

	position.x = clampf(position.x, -max_boundary_x, max_boundary_x)
	current_lane_idx = clampi(int(round(position.x / LANE_WIDTH)), -1, 1)

# ── Lane Switching ────────────────────────────────────────────
func _change_lane(dir: int) -> void:
	# If outside main lanes on a side platform or wall-run exit,
	# pressing toward center immediately sets target directly to the center track!
	if absf(position.x) > 3.8:
		if (position.x > 3.8 and dir < 0) or (position.x < -3.8 and dir > 0):
			current_lane_idx = 0
			target_x = LANES[1]  # 0.0 (Center)
			if audio_synth:
				audio_synth.play_sfx("jump", 1.8, -12.0)
			return

	var new_lane: int = clampi(current_lane_idx + dir, -1, 1)
	if new_lane != current_lane_idx:
		current_lane_idx = new_lane
		target_x = LANES[current_lane_idx + 1]
		if audio_synth:
			audio_synth.play_sfx("jump", 1.8, -12.0)

# ═══════════════════════════════════════════════════════════════
#  JUMP VARIANTS
# ═══════════════════════════════════════════════════════════════
func _execute_jump() -> void:
	jump_buffer_timer = 0.0
	coyote_timer      = 0.0
	velocity.y        = JUMP_VELOCITY
	if is_sliding:
		_end_slide()
	if audio_synth:
		audio_synth.play_sfx("jump", randf_range(0.95, 1.05), -2.0)
	emit_signal("action_feedback", "MOMENTUM JUMP!", Color(0.3, 1.0, 0.4))

func _execute_double_jump() -> void:
	jump_buffer_timer = 0.0
	air_jumps_used   += 1
	velocity.y        = DOUBLE_JUMP_VELOCITY
	camera_shake      = 0.12
	if double_jump_particles:
		double_jump_particles.restart()
		double_jump_particles.emitting = true
	if audio_synth:
		audio_synth.play_sfx("jump", 1.25, -1.0)
	emit_signal("action_feedback", "DOUBLE JUMP!", Color(0.2, 1.0, 0.85))

func _execute_wall_jump() -> void:
	jump_buffer_timer = 0.0
	# Launch up and away from the wall directly toward center track
	velocity.y = WALL_JUMP_VELOCITY_Y
	velocity.x = wall_normal.x * WALL_JUMP_VELOCITY_AWAY
	target_x = 0.0         # Set target to center track
	current_lane_idx = 0
	air_jumps_used = 0     # Wall jump resets double jump!
	wall_run_cooldown_timer = 0.25
	_end_wall_run(true)
	camera_shake = 0.20
	if audio_synth:
		audio_synth.play_sfx("jump", 1.1, -2.0)
	emit_signal("action_feedback", "WALL JUMP!", Color(0.6, 1.0, 0.3))

func _on_land() -> void:
	landing_squash = 0.35
	if audio_synth:
		audio_synth.play_sfx("land", 1.0, -4.0)
	if landing_particles:
		landing_particles.restart()
		landing_particles.emitting = true

# ═══════════════════════════════════════════════════════════════
#  SLIDE
# ═══════════════════════════════════════════════════════════════
func _try_slide() -> void:
	if slide_cooldown_timer > 0.0 or is_sliding:
		return
	is_sliding           = true
	slide_timer          = SLIDE_DURATION
	slide_cooldown_timer = SLIDE_DURATION + SLIDE_COOLDOWN
	_set_collision_sliding(true)
	if audio_synth:
		audio_synth.play_sfx("slide", randf_range(0.9, 1.1), -2.0)
	if slide_sparks:
		slide_sparks.emitting = true
	emit_signal("action_feedback", "MOMENTUM SLIDE!", Color(0.2, 0.9, 1.0))

func _end_slide() -> void:
	if overhead_raycast and overhead_raycast.is_colliding():
		slide_timer = 0.15
		return
	is_sliding = false
	_set_collision_sliding(false)
	if slide_sparks:
		slide_sparks.emitting = false

func _set_collision_sliding(sliding: bool) -> void:
	if not collision_shape:
		return
	var cap := collision_shape.shape as CapsuleShape3D
	if cap:
		if sliding:
			cap.height = slide_capsule_height
			collision_shape.position.y = slide_capsule_height * 0.5
		else:
			cap.height = normal_capsule_height
			collision_shape.position.y = normal_capsule_height * 0.5

# ═══════════════════════════════════════════════════════════════
#  DASH
# ═══════════════════════════════════════════════════════════════
func _try_dash() -> void:
	if dash_cooldown_timer > 0.0:
		if dash_cooldown_timer / DASH_COOLDOWN > 0.5:
			emit_signal("action_feedback", "DASH RECHARGING...", Color(0.5, 0.5, 0.7))
		return
	if is_dashing:
		return

	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	if dir == Vector2.ZERO:
		dir = Vector2(0.0, -1.0)
	dir = dir.normalized()
	dash_direction = Vector3(dir.x, 0.0, dir.y).normalized()

	is_dashing   = true
	dash_timer   = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN

	if is_wall_running:
		_end_wall_run(false)
	if is_grappling:
		_release_grapple()

	if dash_particles:
		dash_particles.emitting = true
	if audio_synth:
		audio_synth.play_sfx("boost", 1.55, -3.0)
	camera_shake = 0.18

	var dn: String = "FORWARD"
	if dir.y > 0.1 and absf(dir.x) < 0.5:    dn = "BACK"
	elif dir.x < -0.5 and absf(dir.y) < 0.5:  dn = "LEFT"
	elif dir.x > 0.5 and absf(dir.y) < 0.5:   dn = "RIGHT"
	elif dir.x < -0.1 and dir.y < -0.1:        dn = "FWD-LEFT"
	elif dir.x > 0.1 and dir.y < -0.1:         dn = "FWD-RIGHT"
	elif dir.x < -0.1 and dir.y > 0.1:         dn = "BACK-LEFT"
	elif dir.x > 0.1 and dir.y > 0.1:          dn = "BACK-RIGHT"
	emit_signal("action_feedback", "DASH " + dn + "!", Color(0.15, 0.95, 1.0))

func _end_dash() -> void:
	is_dashing     = false
	dash_timer     = 0.0
	dash_direction = Vector3.ZERO
	if dash_particles:
		dash_particles.emitting = false

	# Snap target_x to nearest lane if on main track, or stay at current x if on side platform
	if absf(position.x) <= 4.2:
		var best_dist := INF
		var best_x    := target_x
		for lx: float in LANES:
			var d := absf(position.x - lx)
			if d < best_dist:
				best_dist = d
				best_x    = lx
		target_x = best_x
		for i in range(LANES.size()):
			if LANES[i] == best_x:
				current_lane_idx = i - 1
	else:
		target_x = position.x

# ═══════════════════════════════════════════════════════════════
#  WALL RUN
# ═══════════════════════════════════════════════════════════════
func _setup_wall_run_raycasts() -> void:
	# Left wall detection ray
	wall_cast_left = RayCast3D.new()
	wall_cast_left.name            = "WallCastLeft"
	wall_cast_left.target_position = Vector3(-WALL_DETECT_DIST, 0.0, 0.0)
	wall_cast_left.collision_mask  = 1
	wall_cast_left.enabled         = true
	add_child(wall_cast_left)
	wall_cast_left.position = Vector3(0.0, 0.9, 0.0)

	# Right wall detection ray
	wall_cast_right = RayCast3D.new()
	wall_cast_right.name            = "WallCastRight"
	wall_cast_right.target_position = Vector3(WALL_DETECT_DIST, 0.0, 0.0)
	wall_cast_right.collision_mask  = 1
	wall_cast_right.enabled         = true
	add_child(wall_cast_right)
	wall_cast_right.position = Vector3(0.0, 0.9, 0.0)

func _setup_wall_run_particles() -> void:
	var p := CPUParticles3D.new()
	p.name     = "WallRunSparks"
	p.emitting = false
	p.amount   = 18
	p.lifetime = 0.28

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 1.0, 0.5, 0.9)
	var mesh := BoxMesh.new()
	mesh.size     = Vector3(0.05, 0.05, 0.14)
	mesh.material = mat
	p.mesh = mesh

	p.emission_shape        = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.18
	p.direction             = Vector3(0, 0, 1)
	p.spread                = 40.0
	p.gravity               = Vector3(0, -4.0, 0)
	p.initial_velocity_min  = 2.0
	p.initial_velocity_max  = 6.0

	add_child(p)
	wall_run_particles = p

func _update_wall_run(_delta: float) -> void:
	if wall_cast_left == null or wall_cast_right == null:
		return

	wall_cast_left.force_raycast_update()
	wall_cast_right.force_raycast_update()

	var touching_left:  bool = wall_cast_left.is_colliding()
	var touching_right: bool = wall_cast_right.is_colliding()

	# Validate near-vertical wall normal (exclude floors and ceilings)
	if touching_left:
		var norm = wall_cast_left.get_collision_normal()
		if absf(norm.y) > 0.25:
			touching_left = false
	if touching_right:
		var norm = wall_cast_right.get_collision_normal()
		if absf(norm.y) > 0.25:
			touching_right = false

	if not touching_left and not touching_right:
		if is_wall_running:
			_end_wall_run(false)
		return

	if absf(velocity.z) < 6.0:
		if is_wall_running:
			_end_wall_run(false)
		return

	if not is_wall_running:
		if touching_left:
			wall_run_side = -1
			wall_normal   = wall_cast_left.get_collision_normal()
		elif touching_right:
			wall_run_side = 1
			wall_normal   = wall_cast_right.get_collision_normal()
		else:
			return

		is_wall_running = true
		wall_run_timer  = WALL_RUN_DURATION
		air_jumps_used  = 0

		if wall_run_particles:
			wall_run_particles.emitting = true
		if audio_synth:
			audio_synth.play_sfx("slide", 1.3, -6.0)
		emit_signal("action_feedback", "WALL RUN!", Color(0.5, 1.0, 0.4))
	else:
		if wall_run_side == -1 and touching_left:
			wall_normal = wall_cast_left.get_collision_normal()
		elif wall_run_side == 1 and touching_right:
			wall_normal = wall_cast_right.get_collision_normal()
		else:
			_end_wall_run(false)

func _end_wall_run(from_wall_jump: bool) -> void:
	if not is_wall_running:
		return
	is_wall_running = false
	wall_run_timer  = 0.0
	wall_run_side   = 0
	wall_normal     = Vector3.ZERO
	if wall_run_particles:
		wall_run_particles.emitting = false

	if not from_wall_jump:
		# Sync target_x to nearest lane or stay at current x
		if absf(position.x) <= 4.2:
			var best_dist := INF
			var best_x    := target_x
			for lx: float in LANES:
				var d := absf(position.x - lx)
				if d < best_dist:
					best_dist = d
					best_x    = lx
			target_x = best_x
		else:
			target_x = position.x

# ═══════════════════════════════════════════════════════════════
#  GRAPPLING HOOK
# ═══════════════════════════════════════════════════════════════
func _setup_grapple_rope() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "GrappleRope"
	mi.visible = false
	mi.top_level = true

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.15, 0.95, 1.0, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat

	mi.mesh = ImmediateMesh.new()
	add_child(mi)
	grapple_rope = mi

func _find_grapple_target() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var cam_pos = camera.global_position
	var cam_fwd = -camera.global_transform.basis.z

	# 1. Direct camera raycast check
	var ray_end = cam_pos + cam_fwd * GRAPPLE_RANGE
	var query = PhysicsRayQueryParameters3D.create(cam_pos, ray_end, 1, [self])
	var direct_hit = space_state.intersect_ray(query)
	if direct_hit and not direct_hit.is_empty():
		var col = direct_hit.collider
		if col and (col.is_in_group("grapple_anchor") or col.has_meta("is_grapple_anchor")):
			return {"hit": true, "point": direct_hit.position, "node": col}

	# 2. Query nodes in group "grapple_anchor" within range & forward view volume
	var anchors = get_tree().get_nodes_in_group("grapple_anchor")
	var best_pos = Vector3.ZERO
	var best_dist = INF
	var best_node = null

	for a in anchors:
		if not is_instance_valid(a) or not (a is Node3D):
			continue

		var a_pos: Vector3 = a.global_position
		var to_a: Vector3 = a_pos - global_position
		# Track runs in -Z direction: anchor must be ahead of player
		if to_a.z > 2.0:
			continue
		var dist = to_a.length()
		if dist > GRAPPLE_RANGE or dist < 2.5:
			continue

		# Forward dot check relative to track direction Vector3(0, 0, -1)
		var dir_to_a = to_a.normalized()
		if dir_to_a.dot(Vector3(0, 0, -1)) < 0.25:
			continue

		# Line of sight raycast
		var los_query = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.2, 0), a_pos, 1, [self])
		var los_hit = space_state.intersect_ray(los_query)
		if los_hit.is_empty() or los_hit.collider == a:
			if dist < best_dist:
				best_dist = dist
				best_pos = a_pos
				best_node = a

	if best_dist < INF:
		return {"hit": true, "point": best_pos, "node": best_node}

	return {"hit": false, "point": Vector3.ZERO, "node": null}

func _try_grapple() -> void:
	if is_grappling:
		_release_grapple()
		return

	var target = _find_grapple_target()
	if not target.hit:
		emit_signal("action_feedback", "NO ANCHOR IN RANGE", Color(0.7, 0.4, 0.4))
		return

	grapple_anchor      = target.point
	grapple_target_node = target.node
	is_grappling        = true
	grapple_launched    = true

	if is_wall_running:
		_end_wall_run(false)

	if grapple_rope:
		grapple_rope.visible = true

	if audio_synth:
		audio_synth.play_sfx("boost", 0.9, -4.0)
	emit_signal("action_feedback", "GRAPPLE ATTACHED!", Color(0.15, 0.95, 1.0))

func _update_grapple(delta: float) -> void:
	var to_anchor := grapple_anchor - global_position
	var dist      := to_anchor.length()

	if dist < GRAPPLE_MIN_DIST:
		_release_grapple()
		# Release boost forward
		velocity.z = minf(velocity.z, -forward_speed * 1.15)
		return

	# Accelerate player smoothly toward anchor
	var pull_dir := to_anchor.normalized()
	velocity += pull_dir * GRAPPLE_PULL_FORCE * delta

	# Maintain forward speed along track
	if velocity.z > -forward_speed * 0.8:
		velocity.z = move_toward(velocity.z, -forward_speed, 18.0 * delta)

	# Cap max velocity
	if velocity.length() > GRAPPLE_MAX_SPEED:
		velocity = velocity.normalized() * GRAPPLE_MAX_SPEED

func _release_grapple() -> void:
	if not is_grappling:
		return
	is_grappling        = false
	grapple_launched    = false
	grapple_anchor      = Vector3.ZERO
	grapple_target_node = null
	if grapple_rope:
		grapple_rope.visible = false
	target_x = position.x
	emit_signal("action_feedback", "GRAPPLE RELEASED", Color(0.4, 0.9, 1.0))

func _update_grapple_rope() -> void:
	if not is_grappling or not grapple_rope:
		return

	var im := grapple_rope.mesh as ImmediateMesh
	if not im:
		return

	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(grapple_rope.to_local(global_position + Vector3(0, 1.0, -0.2)))
	im.surface_add_vertex(grapple_rope.to_local(grapple_anchor))
	im.surface_end()

# ═══════════════════════════════════════════════════════════════
#  PARTICLES SETUP
# ═══════════════════════════════════════════════════════════════
func _setup_dash_particles() -> void:
	var p := CPUParticles3D.new()
	p.name          = "DashTrail"
	p.emitting      = false
	p.amount        = 32
	p.lifetime      = 0.22
	p.one_shot      = false
	p.explosiveness = 0.0
	p.randomness    = 0.4

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.12, 0.92, 1.0, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := BoxMesh.new()
	mesh.size     = Vector3(0.06, 0.06, 0.3)
	mesh.material = mat
	p.mesh = mesh

	p.emission_shape        = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3
	p.direction             = Vector3(0, 0, 1)
	p.spread                = 35.0
	p.gravity               = Vector3.ZERO
	p.initial_velocity_min  = 8.0
	p.initial_velocity_max  = 16.0
	p.scale_amount_min      = 0.5
	p.scale_amount_max      = 1.4

	add_child(p)
	p.position  = Vector3(0.0, 0.95, 0.1)
	dash_particles = p

func _setup_double_jump_particles() -> void:
	var p := CPUParticles3D.new()
	p.name          = "DoubleJumpBurst"
	p.emitting      = false
	p.amount        = 28
	p.lifetime      = 0.35
	p.one_shot      = true
	p.explosiveness = 0.88
	p.randomness    = 0.5

	var mat := StandardMaterial3D.new()
	mat.shading_mode  = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color  = Color(0.15, 1.0, 0.88, 0.9)
	mat.transparency  = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.material = mat
	p.mesh = mesh

	p.emission_shape        = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3
	p.direction             = Vector3(0, 1, 0)
	p.spread                = 90.0
	p.gravity               = Vector3.ZERO
	p.initial_velocity_min  = 3.0
	p.initial_velocity_max  = 8.0
	p.scale_amount_min      = 0.4
	p.scale_amount_max      = 1.2

	add_child(p)
	p.position = Vector3(0.0, 0.5, 0.0)
	double_jump_particles = p

# ═══════════════════════════════════════════════════════════════
#  DAMAGE, HEALTH & RESET
# ═══════════════════════════════════════════════════════════════
func take_hit(damage: float, speed_drop: float, warning_msg: String) -> void:
	if is_dead or invincibility_timer > 0.0:
		return
	shields -= 1
	emit_signal("shields_changed", shields, max_shields)
	momentum_multiplier = 1.0
	clean_run_timer     = 0.0
	forward_speed       = maxf(MIN_SPEED, forward_speed - speed_drop)
	emit_signal("multiplier_changed", momentum_multiplier)
	camera_shake        = 0.55
	invincibility_timer = 1.2
	if audio_synth:
		audio_synth.play_sfx("hit", randf_range(0.9, 1.1), 2.0)
	emit_signal("action_feedback", warning_msg, Color(1.0, 0.2, 0.2))
	if shields <= 0:
		_die(warning_msg)

func _die(reason: String) -> void:
	if is_dead:
		return
	is_dead       = true
	forward_speed = 0.0
	velocity      = Vector3.ZERO
	is_dashing    = false
	dash_timer    = 0.0
	dash_cooldown_timer = 0.0
	is_wall_running = false
	_release_grapple()
	if is_rewinding:
		_stop_rewind()
	history_buffer.clear()
	history_duration = 0.0
	if dash_particles:
		dash_particles.emitting = false
	if wall_run_particles:
		wall_run_particles.emitting = false
	emit_signal("dash_cooldown_changed", 0.0)
	if audio_synth:
		audio_synth.play_sfx("game_over", 1.0, 4.0)
	emit_signal("player_crashed", reason)

# ═══════════════════════════════════════════════════════════════
#  COLLECTABLES / GAME EVENTS
# ═══════════════════════════════════════════════════════════════
func collect_energy(amount: float, pts: int, is_golden: bool) -> void:
	if is_dead:
		return
	energy = minf(MAX_ENERGY, energy + amount)
	coins += 3 if is_golden else 1
	emit_signal("coins_changed", coins)
	score += int(pts * momentum_multiplier * risk_multiplier)
	if is_golden:
		_increase_multiplier(0.2)
		emit_signal("action_feedback", "GOLDEN MATRIX! +300", Color(1.0, 0.85, 0.2))
	else:
		emit_signal("action_feedback", "+ENERGY", Color(0.2, 0.9, 1.0))
	if audio_synth:
		audio_synth.play_sfx("orb", 1.0 + (energy / MAX_ENERGY) * 0.4, -2.0)
	orbs_towards_shield += 1
	if orbs_towards_shield >= 5:
		orbs_towards_shield = 0
		if shields < max_shields:
			shields += 1
			emit_signal("shields_changed", shields, max_shields)
			emit_signal("action_feedback", "SHIELD RESTORED!", Color(0.1, 1.0, 0.5))

func register_perfect_slide() -> void:
	if is_dead:
		return
	score += int(250 * momentum_multiplier * risk_multiplier)
	_increase_multiplier(0.25)
	forward_speed = minf(BOOST_SPEED, forward_speed + 3.0)
	if audio_synth:
		audio_synth.play_sfx("perfect_slide", 1.0, 0.0)
	emit_signal("action_feedback", "PERFECT SLIDE! +250", Color(1.0, 0.6, 0.1))

func notify_risk_sector(risk_lane: int) -> void:
	in_risk_sector = true
	risk_lane_idx  = risk_lane
	var lane_name  = "RIGHT" if risk_lane > 0 else "LEFT"
	emit_signal("action_feedback", "OVERDRIVE ZONE: " + lane_name + " LANE 3X!", Color(1.0, 0.3, 0.4))
	energy = minf(MAX_ENERGY, energy + 20.0)

func _increase_multiplier(amount: float) -> void:
	var old: float = momentum_multiplier
	momentum_multiplier = minf(max_multiplier, momentum_multiplier + amount)
	if momentum_multiplier != old:
		emit_signal("multiplier_changed", momentum_multiplier)

# ═══════════════════════════════════════════════════════════════
#  STATE QUERIES (used by obstacle.gd and test suites)
# ═══════════════════════════════════════════════════════════════
func is_sliding_active() -> bool:
	return is_sliding

func is_dashing_active() -> bool:
	return is_dashing

func is_wall_running_active() -> bool:
	return is_wall_running

func is_grappling_active() -> bool:
	return is_grappling

# ═══════════════════════════════════════════════════════════════
#  PROCEDURAL ANIMATIONS & CAMERA
# ═══════════════════════════════════════════════════════════════
func _update_invincibility_visual(_delta: float) -> void:
	body_root.visible = int(invincibility_timer * 20.0) % 2 == 0

func _update_procedural_animations(delta: float) -> void:
	if not body_root:
		return

	# Lateral banking tilt
	var lateral_offset: float = target_x - position.x
	var target_roll: float    = clampf(-lateral_offset * 0.15, -0.35, 0.35)
	body_root.rotation.z = lerpf(body_root.rotation.z, target_roll, delta * 15.0)

	if is_sliding:
		body_root.scale      = body_root.scale.lerp(Vector3(1.15, 0.42, 1.25), delta * 18.0)
		body_root.position.y = lerpf(body_root.position.y, 0.0, delta * 18.0)
		body_root.rotation.x = lerpf(body_root.rotation.x, -0.35, delta * 18.0)
	elif is_wall_running:
		var lean: float = -0.32 * float(wall_run_side)
		body_root.rotation.z = lerpf(body_root.rotation.z, lean, delta * 12.0)
		body_root.scale      = body_root.scale.lerp(Vector3(1.0, 1.05, 1.0), delta * 12.0)
	elif not is_on_floor():
		body_root.scale      = body_root.scale.lerp(Vector3(0.92, 1.08, 0.92), delta * 12.0)
		body_root.position.y = lerpf(body_root.position.y, 0.05, delta * 12.0)
		body_root.rotation.x = lerpf(body_root.rotation.x, 0.15, delta * 12.0)
	else:
		run_cycle_time += delta * forward_speed * 0.8
		var bob: float = sin(run_cycle_time * 2.0) * 0.06
		landing_squash = move_toward(landing_squash, 0.0, delta * 2.0)
		var sy: float  = 1.0 - landing_squash
		var sxz: float = 1.0 + landing_squash * 0.5
		body_root.scale      = body_root.scale.lerp(Vector3(sxz, sy, sxz), delta * 15.0)
		body_root.position.y = lerpf(body_root.position.y, bob, delta * 15.0)
		body_root.rotation.x = lerpf(body_root.rotation.x, sin(run_cycle_time) * 0.05, delta * 15.0)

	# Thruster particle intensity
	if thruster_particles:
		thruster_particles.emitting = true
		if is_dashing:
			thruster_particles.speed_scale = 3.5
		elif is_boosting:
			thruster_particles.speed_scale = 2.0
		elif is_wall_running:
			thruster_particles.speed_scale = 1.6
		else:
			thruster_particles.speed_scale = 1.0

func toggle_camera_mode() -> void:
	is_fpp = not is_fpp
	emit_signal("camera_mode_changed", is_fpp)
	if audio_synth:
		audio_synth.play_sfx("jump", 1.8 if is_fpp else 1.4, -10.0)
	var mode_name := "FIRST-PERSON [FPP]" if is_fpp else "THIRD-PERSON [TPP]"
	emit_signal("action_feedback", mode_name, Color(0.2, 0.9, 1.0) if is_fpp else Color(0.85, 0.9, 1.0))

func _update_camera(delta: float) -> void:
	if not camera:
		return

	# Smooth perspective transition
	var target_weight: float = 1.0 if is_fpp else 0.0
	camera_transition_weight = move_toward(camera_transition_weight, target_weight, delta * 5.5)

	# Calculate mode-specific target positions with slide lowerings
	var tpp_pos := Vector3(0.0, 1.8 if is_sliding else 2.1, 4.2)
	var fpp_pos := Vector3(0.0, 0.72 if is_sliding else 1.45, -0.15)
	
	# Interpolate position and pitch
	camera.position = tpp_pos.lerp(fpp_pos, camera_transition_weight)
	camera.rotation.x = lerpf(CAM_ROT_X_TPP, CAM_ROT_X_FPP, camera_transition_weight)

	# In FPP, exclude/hide body model to prevent any internal clipping or view obstruction
	if body_root:
		if is_fpp or camera_transition_weight > 0.45:
			body_root.visible = false
		elif invincibility_timer <= 0.0:
			body_root.visible = true

	# Dynamic FOV based on speed, state, and perspective mode
	var base_fov: float = lerpf(CAM_FOV_BASE_TPP, CAM_FOV_BASE_FPP, camera_transition_weight)
	var speed_fov_boost: float = (forward_speed - BASE_SPEED) / (BOOST_SPEED - BASE_SPEED) * 14.0
	var target_fov: float = base_fov + speed_fov_boost
	if is_wall_running:
		target_fov += 4.0
	elif is_grappling:
		target_fov += 6.0
	camera.fov = lerpf(camera.fov, target_fov, delta * 8.0)

	# Speed lines
	if speed_lines:
		speed_lines.emitting = is_boosting or forward_speed > 26.0 or is_wall_running or is_grappling

	# Camera shake (restrained in FPP for comfort & readability)
	if camera_shake > 0.0:
		camera_shake = move_toward(camera_shake, 0.0, delta * 2.5)
		var shake_scale: float = 0.10 if is_fpp else 0.18
		camera.h_offset = (randf() * 2.0 - 1.0) * camera_shake * shake_scale
		camera.v_offset = (randf() * 2.0 - 1.0) * camera_shake * shake_scale
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

	# Camera banking during wall run
	if is_wall_running:
		camera_rig.rotation.z = lerpf(camera_rig.rotation.z, 0.09 * float(wall_run_side), delta * 8.0)
	else:
		camera_rig.rotation.z = lerpf(camera_rig.rotation.z, 0.0, delta * 8.0)

# ═══════════════════════════════════════════════════════════════
#  TIME REWIND IMPLEMENTATION
# ═══════════════════════════════════════════════════════════════
func _setup_rewind_particles() -> void:
	var p := CPUParticles3D.new()
	p.name          = "RewindParticles"
	p.emitting      = false
	p.amount        = 40
	p.lifetime      = 0.32
	p.one_shot      = false
	p.explosiveness = 0.0
	p.randomness    = 0.5

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.18, 0.90, 1.0, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := BoxMesh.new()
	mesh.size     = Vector3(0.08, 0.08, 0.45)
	mesh.material = mat
	p.mesh = mesh

	p.emission_shape        = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents  = Vector3(0.7, 0.9, 0.7)
	p.direction             = Vector3(0, 0, -1)
	p.spread                = 20.0
	p.gravity               = Vector3.ZERO
	p.initial_velocity_min  = 8.0
	p.initial_velocity_max  = 16.0
	p.scale_amount_min      = 0.5
	p.scale_amount_max      = 1.5

	add_child(p)
	p.position = Vector3(0.0, 0.9, 0.0)
	rewind_particles = p

func set_run_start(pos: Vector3, dist: float = 0.0) -> void:
	run_start_position = pos
	run_start_distance = dist
	run_start_recorded = true

func _is_snapshot_at_or_behind_start(snap: Dictionary) -> bool:
	if not run_start_recorded:
		return false
	var snap_pos: Vector3 = snap.get("pos", global_position)
	var snap_dist: float = snap.get("dist", distance_traveled)
	# Track runs along -Z. snap_pos.z >= run_start_position.z is at or behind start.
	return snap_dist <= run_start_distance or snap_pos.z >= run_start_position.z

func can_rewind() -> bool:
	if is_dead:
		return false
	if history_buffer.size() < 2:
		return false
	if run_start_recorded:
		if distance_traveled <= run_start_distance and global_position.z >= run_start_position.z:
			return false
		var last_idx: int = history_buffer.size() - 1
		if last_idx >= 0 and _is_snapshot_at_or_behind_start(history_buffer[last_idx]):
			return false
	return true

func _record_snapshot(delta: float) -> void:
	if is_dead or is_rewinding:
		return

	# Never record snapshots behind the starting point
	if run_start_recorded:
		if distance_traveled < run_start_distance or global_position.z > run_start_position.z:
			return

	var physics_fps: float = float(Engine.physics_ticks_per_second) if Engine.physics_ticks_per_second > 0 else 60.0
	var max_snaps: int = maxi(1, int(round(max_history_duration * physics_fps)))

	history_buffer.push_back({
		"pos": global_position,
		"rot": body_root.rotation if body_root else Vector3.ZERO,
		"vel": velocity,
		"fwd_speed": forward_speed,
		"target_x": target_x,
		"lane": current_lane_idx,
		"grounded": is_on_floor(),
		"energy": energy,
		"dist": distance_traveled,
		"sliding": is_sliding,
		"wall_running": is_wall_running,
		"dashing": is_dashing,
		"grappling": is_grappling,
		"air_jumps": air_jumps_used,
		"dash_cooldown": dash_cooldown_timer,
		"momentum": momentum_multiplier,
		"delta": delta
	})
	history_duration += delta

	# Continuously remove older snapshots beyond max_history_duration (strict 3.0s limit)
	while (history_duration > max_history_duration or history_buffer.size() > max_snaps) and not history_buffer.is_empty():
		var oldest: Dictionary = history_buffer.pop_front()
		history_duration = maxf(0.0, history_duration - oldest.get("delta", 1.0 / physics_fps))

	var ratio: float = clampf(history_duration / max_history_duration, 0.0, 1.0)
	emit_signal("rewind_state_changed", false, ratio)

func _start_rewind() -> void:
	if is_rewinding or not can_rewind() or is_dead:
		return
	is_rewinding = true

	if is_grappling:
		_release_grapple()
	if is_wall_running:
		is_wall_running = false
	if is_dashing:
		is_dashing = false

	if rewind_particles:
		rewind_particles.restart()
		rewind_particles.emitting = true
	if audio_synth:
		audio_synth.play_sfx("boost", 1.8, -4.0)
	emit_signal("action_feedback", "TEMPORAL REWIND", Color(0.2, 0.9, 1.0))

func _stop_rewind() -> void:
	if not is_rewinding:
		return
	is_rewinding = false

	if rewind_particles:
		rewind_particles.emitting = false

	if not is_sliding:
		_set_collision_sliding(false)

	var ratio: float = clampf(history_duration / max_history_duration, 0.0, 1.0)
	emit_signal("rewind_state_changed", false, ratio)

func _process_rewind(delta: float) -> void:
	if history_buffer.size() < 2 or not can_rewind():
		_stop_rewind()
		emit_signal("action_feedback", "REWIND EXHAUSTED", Color(0.7, 0.7, 0.9))
		return

	var physics_fps: float = float(Engine.physics_ticks_per_second) if Engine.physics_ticks_per_second > 0 else 60.0
	var steps_to_rewind: int = maxi(1, int(round(rewind_speed_mult)))
	var snapshot: Dictionary = {}
	var hit_start_boundary: bool = false

	for _s in range(steps_to_rewind):
		if history_buffer.is_empty():
			break
		var candidate: Dictionary = history_buffer.pop_back()
		history_duration = maxf(0.0, history_duration - candidate.get("delta", 1.0 / physics_fps))

		if _is_snapshot_at_or_behind_start(candidate):
			snapshot = candidate
			hit_start_boundary = true
			# Discard any older pre-start snapshots to ensure buffer is clean
			while not history_buffer.is_empty():
				var old: Dictionary = history_buffer.pop_back()
				history_duration = maxf(0.0, history_duration - old.get("delta", 1.0 / physics_fps))
			break
		else:
			snapshot = candidate

	if snapshot.is_empty():
		_stop_rewind()
		return

	# Hard boundary enforcement: never restore position behind run's starting point
	if run_start_recorded:
		if snapshot["pos"].z > run_start_position.z:
			snapshot["pos"].z = run_start_position.z
		if snapshot["dist"] < run_start_distance:
			snapshot["dist"] = run_start_distance

	# Restore physical state
	global_position   = snapshot["pos"]
	velocity          = snapshot["vel"]
	forward_speed     = snapshot["fwd_speed"]
	target_x          = snapshot["target_x"]
	current_lane_idx  = snapshot["lane"]
	distance_traveled = snapshot["dist"]
	energy            = snapshot["energy"]
	air_jumps_used    = snapshot.get("air_jumps", 0)
	dash_cooldown_timer = snapshot.get("dash_cooldown", 0.0)
	momentum_multiplier = snapshot.get("momentum", 1.0)

	if body_root and snapshot.has("rot"):
		body_root.rotation = snapshot["rot"]

	# Mechanics safety and synchronization
	if snapshot.get("sliding", false):
		if not is_sliding:
			is_sliding = true
			_set_collision_sliding(true)
	else:
		if is_sliding:
			_end_slide()

	if is_grappling:
		_release_grapple()
	if is_wall_running:
		is_wall_running = false
	if is_dashing:
		is_dashing = false

	if rewind_particles:
		rewind_particles.emitting = true

	rewind_audio_timer += delta
	if rewind_audio_timer >= 0.18:
		rewind_audio_timer = 0.0
		if audio_synth:
			audio_synth.play_sfx("slide", 2.2, -8.0)

	var ratio: float = clampf(history_duration / max_history_duration, 0.0, 1.0)
	emit_signal("rewind_state_changed", true, ratio)
	emit_signal("speed_changed", forward_speed, BOOST_SPEED)
	emit_signal("energy_changed", energy, MAX_ENERGY)
	emit_signal("score_changed", score, distance_traveled)

	_update_camera(delta)

	if hit_start_boundary:
		_stop_rewind()
		emit_signal("action_feedback", "START BOUNDARY REACHED", Color(0.4, 0.8, 1.0))
