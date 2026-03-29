extends Area2D

var xp_value: int        = 1
var attracted: bool      = false
var attract_speed: float = 320.0

var _player: CharacterBody2D = null
var _bob: float       = 0.0
var _spin: float      = 0.0

func _ready() -> void:
	add_to_group("coins")
	collision_layer = 8
	collision_mask  = 1
	body_entered.connect(_on_body_entered)
	_spin = randf() * TAU

func _physics_process(delta: float) -> void:
	_bob  += delta * 3.5
	_spin += delta * 2.5

	if _player == null or not is_instance_valid(_player):
		var arr := get_tree().get_nodes_in_group("player")
		if not arr.is_empty():
			_player = arr[0]

	if attracted and _player != null and is_instance_valid(_player):
		var dir := (_player.global_position - global_position).normalized()
		position  += dir * attract_speed * delta
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
	var bob  := sin(_bob) * 2.5
	var glow := 0.6 + 0.4 * sin(_bob * 1.4)
	var s    := 8.0

	# 외곽 글로우
	draw_circle(Vector2(0, bob), 12, Color(0.0, 0.65, 1.0, 0.18 * glow))

	# 크리스탈 다이아몬드 몸체
	var pts := PackedVector2Array([
		Vector2(0,   bob - s * 1.35),
		Vector2(s,   bob),
		Vector2(0,   bob + s * 0.8),
		Vector2(-s,  bob),
	])
	draw_colored_polygon(pts, Color(0.1, 0.65, 1.0, 0.9))
	draw_polyline(
		PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
		Color(0.55, 1.0, 1.0), 1.5
	)

	# 내부 반사선
	draw_line(Vector2(0, bob - s * 0.9), Vector2(s * 0.5, bob),
		Color(1.0, 1.0, 1.0, 0.45 * glow), 1.5)

	# 중심 빛
	draw_circle(Vector2(0, bob), 3, Color(0.75, 1.0, 1.0, glow))

func _process(_delta: float) -> void:
	queue_redraw()
