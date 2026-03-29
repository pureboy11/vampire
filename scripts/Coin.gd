extends Area2D

var xp_value: int        = 1
var attracted: bool      = false
var attract_speed: float = 320.0

var _player: Node2D    = null
var _bob_timer: float  = 0.0

func _ready() -> void:
	add_to_group("coins")
	collision_layer = 8
	collision_mask  = 1
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_bob_timer += delta

	if _player == null or not is_instance_valid(_player):
		var arr := get_tree().get_nodes_in_group("player")
		if not arr.is_empty():
			_player = arr[0] as Node2D

	if attracted and _player != null and is_instance_valid(_player):
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		position += dir * attract_speed * delta
		if global_position.distance_to(_player.global_position) < 20.0:
			_collect()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if _player != null and is_instance_valid(_player):
		_player.gain_xp(xp_value)
	queue_free()

func _draw() -> void:
	var bob: float = sin(_bob_timer * 4.0) * 2.0
	draw_circle(Vector2(0.0, bob), 9.0,  Color(0.9, 0.65, 0.0))
	draw_circle(Vector2(-2.0, bob - 2.0), 4.0, Color(1.0, 0.95, 0.4))
	draw_arc(Vector2(0.0, bob), 9.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.2), 1.5)

func _process(_delta: float) -> void:
	queue_redraw()
