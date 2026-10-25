extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: Control = $CanvasLayer/HUD
@onready var audio_synth: AudioSynthesizer = $AudioSynthesizer
@onready var track_manager: TrackManager = $TrackManager

func _ready() -> void:
	track_manager.player_node = player
	_connect_signals()

func _connect_signals() -> void:
	player.speed_changed.connect(hud.update_speed)
	player.energy_changed.connect(hud.update_energy)
	player.shields_changed.connect(hud.update_shields)
	player.multiplier_changed.connect(hud.update_multiplier)
	player.score_changed.connect(hud.update_score)
	player.action_feedback.connect(hud.show_feedback)
	player.player_crashed.connect(_on_player_crashed)
	player.dash_cooldown_changed.connect(hud.update_dash_cooldown)
	player.coins_changed.connect(hud.update_coins)
	player.camera_mode_changed.connect(hud.update_camera_mode)
	player.rewind_state_changed.connect(hud.update_rewind)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_T or (player != null and player.is_dead and event.keycode == KEY_R))):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if hud.has_method("set_paused"):
		hud.set_paused(get_tree().paused)

func _on_player_crashed(reason: String) -> void:
	hud.show_game_over(reason, player.score, player.distance_traveled)
