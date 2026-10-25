extends Node3D
class_name TrackManager

const CHUNK_LENGTH: float = 60.0
const INITIAL_CHUNKS: int = 6

var active_chunks: Array[Node3D] = []
var next_spawn_z: float = 30.0 # Chunk origin is at its center (z from +30 to -30 for first chunk)
var chunk_counter: int = 0
var difficulty: float = 1.0

@export var player_node: Node3D

func _ready() -> void:
	# Initial track spawn
	for i in range(INITIAL_CHUNKS):
		_spawn_next_chunk()

func _process(_delta: float) -> void:
	if not player_node:
		return
		
	# Check if player has moved forward enough to recycle the oldest chunk
	if active_chunks.size() > 0:
		var oldest_chunk = active_chunks[0]
		# The back edge of the oldest chunk is at oldest_chunk.position.z + (CHUNK_LENGTH / 2)
		# When player passes beyond it by 35 meters, remove it
		if player_node.position.z < oldest_chunk.position.z - (CHUNK_LENGTH * 0.5) - 35.0:
			active_chunks.remove_at(0)
			oldest_chunk.queue_free()
			_spawn_next_chunk()

func _spawn_next_chunk() -> void:
	var chunk = TrackChunk.new()
	chunk.position = Vector3(0, 0, next_spawn_z - (CHUNK_LENGTH * 0.5))
	add_child(chunk)
	chunk.setup(chunk_counter, difficulty)
	
	active_chunks.append(chunk)
	next_spawn_z -= CHUNK_LENGTH
	chunk_counter += 1
	difficulty = 1.0 + float(chunk_counter) * 0.05
