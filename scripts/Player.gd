extends CharacterBody2D

# ── 스탯 ──────────────────────────────────────────────
var speed: float        = 200.0
var max_hp: float       = 100.0
var current_hp: float   = 100.0
var damage: float       = 20.0
var fire_rate: float    = 1.0
var bullet_speed: float = 400.0
var bullet_count: int   = 1
var magnet_range: float = 90.0

# ── XP / 레벨 ─────────────────────────────────────────
var level: int        = 1
var current_xp: int   = 0
var xp_to_level: int  = 10

# ── 내부 상태 ─────────────────────────────────────────
var shoot_timer: float      = 0.0
var invincible_timer: float = 0.0
var is_dead: bool           = false

const BULLET_SCENE = preload("res://scenes/Bullet.tscn")

signal xp_updated(current: int, required: int)
signal level_up_triggered
signal hp_updated(current: float, maximum: float)
signal player_died

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1
	collision_mask  = 0

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if invincible_timer > 0.0:
		invincible_timer -= delta
	_handle_movement()
	_handle_shooting(delta)
	_attract_coins()

func _handle_movement() -> void:
	var dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up",   "ui_down")
	)
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	velocity = dir * speed
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	shoot_timer += delta
	if shoot_timer >= 1.0 / fire_rate:
		shoot_timer = 0.0
		_shoot()

func _shoot() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	var nearest: Node2D = _nearest_enemy(enemies)
	if nearest == null:
		return

	var base_dir: Vector2 = (nearest.global_position - global_position).normalized()
	for i in range(bullet_count):
		var bullet := BULLET_SCENE.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.damage      = damage
		bullet.speed       = bullet_speed
		if bullet_count == 1:
			bullet.direction = base_dir
		else:
			var spread := deg_to_rad(20.0 * (i - (bullet_count - 1) / 2.0))
			bullet.direction = base_dir.rotated(spread)

func _nearest_enemy(enemies: Array) -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var e2d := e as Node2D
		if e2d == null:
			continue
		var d: float = global_position.distance_to(e2d.global_position)
		if d < min_dist:
			min_dist = d
			nearest  = e2d
	return nearest

func _attract_coins() -> void:
	for coin in get_tree().get_nodes_in_group("coins"):
		if not is_instance_valid(coin):
			continue
		var coin2d := coin as Node2D
		if coin2d == null:
			continue
		if global_position.distance_to(coin2d.global_position) < magnet_range:
			coin.attracted = true

func take_damage(amount: float) -> void:
	if is_dead or invincible_timer > 0.0:
		return
	current_hp -= amount
	invincible_timer = 0.4
	emit_signal("hp_updated", current_hp, max_hp)
	if current_hp <= 0.0:
		current_hp = 0.0
		is_dead    = true
		emit_signal("player_died")

func gain_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_level:
		current_xp  -= xp_to_level
		xp_to_level  = int(xp_to_level * 1.5)
		level        += 1
		emit_signal("level_up_triggered")
	emit_signal("xp_updated", current_xp, xp_to_level)

func apply_upgrade(id: String) -> void:
	match id:
		"damage":       damage       *= 1.30
		"fire_rate":    fire_rate    *= 1.25
		"speed":        speed        *= 1.20
		"bullet_speed": bullet_speed *= 1.25
		"multi_shot":   bullet_count += 1
		"magnet":       magnet_range *= 1.60
		"max_hp":
			max_hp     += 40.0
			current_hp  = min(current_hp + 40.0, max_hp)
			emit_signal("hp_updated", current_hp, max_hp)

func _draw() -> void:
	if is_dead:
		return
	var a: float = 0.45 if invincible_timer > 0.0 else 1.0

	draw_circle(Vector2.ZERO, 20, Color(0.2, 0.45, 1.0, a))
	draw_arc(Vector2.ZERO, 20, 0, TAU, 48, Color(0.6, 0.8, 1.0, a), 2.5)

	for xo: int in [-8, 8]:
		draw_circle(Vector2(xo, -6), 5, Color(1, 1, 1, a))
		draw_circle(Vector2(xo, -6), 2.5, Color(0, 0, 0, a))

	var pts := PackedVector2Array([Vector2(22, -4), Vector2(32, 0), Vector2(22, 4)])
	draw_colored_polygon(pts, Color(0.9, 0.9, 0.3, a))

func _process(_delta: float) -> void:
	queue_redraw()
