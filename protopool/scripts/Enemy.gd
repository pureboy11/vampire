extends CharacterBody2D
class_name Player
# ── 타입: "alien" | "dart" | "ufo" ───────────────────
var enemy_type: String  = "alien"

var speed: float        = 80.0
var max_hp: float       = 30.0
var current_hp: float   = 30.0
var damage: float       = 8.0
var xp_value: int       = 1

var _player: Player = null
var _knockback: Vector2   = Vector2.ZERO
var _flash_timer: float   = 0.0
var _anim: float          = 0.0

const COIN_SCENE = preload("res://scenes/Coin.tscn")

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2
	collision_mask  = 2

	match enemy_type:
		"alien":
			speed    = 80.0;  max_hp = 30.0;  damage = 8.0;  xp_value = 1
		"dart":
			speed    = 165.0; max_hp = 15.0;  damage = 6.0;  xp_value = 1
			_resize_col(10.0)
		"ufo":
			speed    = 40.0;  max_hp = 120.0; damage = 15.0; xp_value = 3
			_resize_col(26.0)

	current_hp = max_hp

func _resize_col(r: float) -> void:
	var col := get_node_or_null("CollisionShape2D")
	if col and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = r

func _physics_process(delta: float) -> void:
	_find_player_if_needed()
	if _player == null or not is_instance_valid(_player):
		return

	_anim += delta * (1.5 if enemy_type == "ufo" else 4.0)

	if _flash_timer > 0.0:
		_flash_timer -= delta

	var dir := (_player.global_position - global_position).normalized()
	_knockback = _knockback.lerp(Vector2.ZERO, delta * 8.0)
	velocity   = dir * speed + _knockback
	move_and_slide()

	# 플레이어 접촉 피해
	var cr := 26.0 if enemy_type == "ufo" else (10.0 if enemy_type == "dart" else 18.0)
	if global_position.distance_to(_player.global_position) < cr + 18.0:
		_player.take_damage(damage * delta)

func _find_player_if_needed() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var arr := get_tree().get_nodes_in_group("player")
	if not arr.is_empty():
		_player = arr[0] as Player

func take_damage(amount: float, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	current_hp  -= amount
	_knockback   = knockback_dir * 220.0
	_flash_timer = 0.12
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	remove_from_group("enemies")
	var coin_count := 3 if enemy_type == "ufo" else 1
	for i in coin_count:
		var coin = COIN_SCENE.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(
			randf_range(-16.0, 16.0), randf_range(-16.0, 16.0)
		)
		coin.xp_value = xp_value
	queue_free()

# ── 드로잉 ────────────────────────────────────────────
func _draw() -> void:
	var fl := _flash_timer > 0.0
	match enemy_type:
		"alien": _draw_alien(fl)
		"dart":  _draw_dart(fl)
		"ufo":   _draw_ufo(fl)

func _draw_hp_bar(width: float, y: float) -> void:
	var ratio: float = clamp(current_hp / max_hp, 0.0, 1.0)
	var hw    := width * 0.5
	draw_rect(Rect2(-hw, y, width,         4), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(-hw, y, width * ratio, 4), Color(0.15, 0.95, 0.3))

# ── 외계인 (기본) ─────────────────────────────────────
func _draw_alien(fl: bool) -> void:
	var bc := Color(1.0, 1.0, 1.0) if fl else Color(0.15, 0.85, 0.35)
	var rc := Color.WHITE           if fl else Color(0.4,  1.0,  0.55)

	draw_circle(Vector2(0, 4), 18, bc)
	draw_arc(Vector2(0, 4), 18, 0, TAU, 48, rc, 2.0)
	draw_circle(Vector2(0, -6), 12, bc.darkened(0.15))

	for xo in [-7, 7]:
		draw_circle(Vector2(xo, -7), 5,   Color(0.0, 0.9, 0.25))
		draw_circle(Vector2(xo, -7), 2.5, Color.BLACK)

	draw_line(Vector2(-5, -18), Vector2(-9, -30), rc, 1.5)
	draw_line(Vector2( 5, -18), Vector2( 9, -30), rc, 1.5)
	draw_circle(Vector2(-9, -30), 3, Color(0.0, 1.0, 0.4))
	draw_circle(Vector2( 9, -30), 3, Color(0.0, 1.0, 0.4))

	_draw_hp_bar(36, -38)

# ── 다트 (플라즈마 구체, 빠름) ────────────────────────
func _draw_dart(fl: bool) -> void:
	var bc := Color(1.0, 1.0, 1.0)          if fl else Color(1.0, 0.35, 0.0)
	var rc := Color.WHITE                    if fl else Color(1.0, 0.65, 0.15)
	var t  := _anim

	# 외부 글로우
	draw_circle(Vector2.ZERO, 13, bc.darkened(0.4))
	# 코어
	draw_circle(Vector2.ZERO, 9,  bc)
	draw_arc(Vector2.ZERO, 9, 0, TAU, 24, rc, 2.0)
	draw_circle(Vector2.ZERO, 5,  Color(1.0, 0.9, 0.5))
	# 회전 플라즈마 스파이크
	for i in 4:
		var a := t + TAU * i / 4.0
		draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 14, Color(1.0, 0.55, 0.0, 0.55), 2.0)

	_draw_hp_bar(22, -24)

# ── UFO (보스급, 느림) ────────────────────────────────
func _draw_ufo(fl: bool) -> void:
	var bc := Color(1.0, 1.0, 1.0) if fl else Color(0.45, 0.08, 0.75)
	var rc := Color.WHITE           if fl else Color(0.75, 0.3,  1.0)
	var t  := _anim

	# 하부 원반
	var disk := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		disk.append(Vector2(cos(a) * 26, sin(a) * 9 + 2))
	draw_colored_polygon(disk, bc)
	draw_polyline(disk, rc, 2.0, true)

	# 상단 돔
	var dome := PackedVector2Array()
	for i in 13:
		var a := PI + TAU * i / 24.0
		dome.append(Vector2(cos(a) * 16, sin(a) * 13 - 1))
	draw_colored_polygon(dome, bc.lightened(0.25))

	# 회전 창문
	for i in 4:
		var a := t + TAU * i / 4.0
		draw_circle(Vector2(cos(a) * 16, sin(a) * 5 + 2), 3.5, Color(0.0, 0.85, 1.0, 0.95))

	# 인력 빔
	draw_line(Vector2(-8, 11), Vector2(-13, 28), Color(0.5, 0.2, 1.0, 0.45), 3.5)
	draw_line(Vector2( 8, 11), Vector2( 13, 28), Color(0.5, 0.2, 1.0, 0.45), 3.5)

	_draw_hp_bar(52, -24)

func _process(_delta: float) -> void:
	queue_redraw()
