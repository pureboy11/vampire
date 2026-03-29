extends Area2D

var speed: float       = 400.0
var damage: float      = 20.0
var direction: Vector2 = Vector2.RIGHT
var lifetime: float    = 2.5

func _ready() -> void:
	collision_layer = 4
	collision_mask  = 2
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# 진행 방향으로 노드 회전 (레이저가 방향에 맞게 그려짐)
	if direction != Vector2.ZERO:
		rotation = direction.angle() + PI * 0.5
	position += direction * speed * delta
	lifetime  -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(damage, direction)
		queue_free()

func _draw() -> void:
	# 레이저 빔 — 세 겹 글로우
	draw_line(Vector2(0, -14), Vector2(0, 14), Color(0.0, 0.75, 1.0, 0.25), 9.0)
	draw_line(Vector2(0, -14), Vector2(0, 14), Color(0.25, 0.9, 1.0, 0.75), 4.0)
	draw_line(Vector2(0, -14), Vector2(0, 14), Color(1.0, 1.0, 1.0, 1.0),   1.5)
	# 선두 광점
	draw_circle(Vector2(0, -14), 3.5, Color(0.5, 1.0, 1.0, 0.9))

func _process(_delta: float) -> void:
	queue_redraw()
