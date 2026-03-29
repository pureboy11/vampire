extends CharacterBody2D

var speed: float      = 80.0
var max_hp: float     = 30.0
var current_hp: float = 30.0
var damage: float     = 8.0
var xp_value: int     = 1

var _player: Node2D        = null
var _knockback: Vector2    = Vector2.ZERO
var _flash_timer: float    = 0.0

const COIN_SCENE = preload("res://scenes/Coin.tscn")

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 2

func _physics_process(delta: float) -> void:
	_find_player_if_needed()
	if _player == null or not is_instance_valid(_player):
		return

	if _flash_timer > 0.0:
		_flash_timer -= delta

	var dir: Vector2 = (_player.global_position - global_position).normalized()
	_knockback = _knockback.lerp(Vector2.ZERO, delta * 8.0)
	velocity   = dir * speed + _knockback
	move_and_slide()

	if global_position.distance_to(_player.global_position) < 28.0:
		_player.take_damage(damage * delta)

func _find_player_if_needed() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var arr := get_tree().get_nodes_in_group("player")
	if not arr.is_empty():
		_player = arr[0] as Node2D

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	current_hp   -= amount
	_knockback    = knockback_dir * 220.0
	_flash_timer  = 0.12
	queue_redraw()
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	remove_from_group("enemies")
	var coin := COIN_SCENE.instantiate()
	get_parent().add_child(coin)
	coin.global_position = global_position
	coin.xp_value        = xp_value
	queue_free()

func _draw() -> void:
	var flashing: bool  = _flash_timer > 0.0
	var body_col: Color = Color(1.0, 0.8, 0.8) if flashing else Color(0.85, 0.1, 0.1)

	draw_circle(Vector2.ZERO, 18, body_col)
	draw_arc(Vector2.ZERO, 18, 0, TAU, 48, Color(1.0, 0.4, 0.4), 2.0)

	var horn_l := PackedVector2Array([Vector2(-12, -14), Vector2(-6, -26), Vector2(-2, -14)])
	var horn_r := PackedVector2Array([Vector2(2, -14),   Vector2(6, -26),  Vector2(12, -14)])
	draw_colored_polygon(horn_l, Color(0.6, 0.0, 0.0))
	draw_colored_polygon(horn_r, Color(0.6, 0.0, 0.0))

	draw_circle(Vector2(-7, -4), 4, Color.WHITE)
	draw_circle(Vector2(7,  -4), 4, Color.WHITE)
	draw_circle(Vector2(-7, -4), 2, Color.BLACK)
	draw_circle(Vector2(7,  -4), 2, Color.BLACK)

	var ratio: float = clamp(current_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-18, -30, 36, 5),              Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-18, -30, 36.0 * ratio, 5.0),  Color(0.1, 0.9, 0.1))

func _process(_delta: float) -> void:
	queue_redraw()
