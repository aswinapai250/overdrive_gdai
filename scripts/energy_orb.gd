extends Area3D
class_name EnergyOrb

@export var is_golden: bool = false
@export var energy_amount: float = 12.0
@export var score_amount: int = 100

var base_y: float = 1.0
var time_offset: float = 0.0
var is_collected: bool = false
var target_player: Node3D = null
var magnet_speed: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D
var halo_ring: MeshInstance3D = null

func _ready() -> void:
	time_offset = randf() * TAU
	base_y = position.y
	body_entered.connect(_on_body_entered)
	_setup_visuals()

func _setup_visuals() -> void:
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.3 if not is_golden else 0.4
	sphere_mesh.height = sphere_mesh.radius * 2.0
	mesh_instance.mesh = sphere_mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	
	if is_golden:
		mat.albedo_color = Color(1.0, 0.82, 0.18)
		ring_mat.albedo_color = Color(1.0, 0.65, 0.1, 0.85)
		energy_amount = 25.0
		score_amount = 300
		if light:
			light.light_color = Color(1.0, 0.75, 0.2)
			light.light_energy = 1.8
	else:
		mat.albedo_color = Color(0.12, 0.85, 0.98)
		ring_mat.albedo_color = Color(0.15, 0.65, 0.95, 0.75)
		if light:
			light.light_color = Color(0.12, 0.85, 0.98)
			light.light_energy = 1.4
			
	mesh_instance.material_override = mat

	# Contained Gyroscopic Halo Ring
	halo_ring = MeshInstance3D.new()
	halo_ring.name = "HaloRing"
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.38 if not is_golden else 0.48
	t_mesh.outer_radius = 0.44 if not is_golden else 0.56
	halo_ring.mesh = t_mesh
	halo_ring.material_override = ring_mat
	add_child(halo_ring)

func _process(delta: float) -> void:
	if is_collected:
		return
		
	var t = Time.get_ticks_msec() / 1000.0 + time_offset
	# Smooth floating bob and gyroscopic spin
	mesh_instance.rotate_y(delta * 2.0)
	mesh_instance.rotate_x(delta * 1.0)
	
	if halo_ring:
		halo_ring.rotate_x(delta * 2.5)
		halo_ring.rotate_z(delta * 1.8)
	
	if target_player:
		# Magnet pull toward player
		magnet_speed += delta * 45.0
		global_position = global_position.move_toward(target_player.global_position + Vector3(0, 0.8, 0), magnet_speed * delta)
		if global_position.distance_to(target_player.global_position + Vector3(0, 0.8, 0)) < 0.6:
			_collect(target_player)
	else:
		position.y = base_y + sin(t * 3.0) * 0.18

func attract_to(player: Node3D) -> void:
	if not is_collected and target_player == null:
		target_player = player

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		_collect(body)

func _collect(player: Node3D) -> void:
	if is_collected:
		return
	is_collected = true
	
	if player.has_method("collect_energy"):
		player.collect_energy(energy_amount, score_amount, is_golden)
	
	# Visual shrink pop
	collision_layer = 0
	collision_mask = 0
	var tween = create_tween().set_parallel(true)
	if mesh_instance:
		tween.tween_property(mesh_instance, "scale", Vector3(0.01, 0.01, 0.01), 0.12).set_ease(Tween.EASE_IN)
	if halo_ring:
		tween.tween_property(halo_ring, "scale", Vector3(0.01, 0.01, 0.01), 0.12).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
