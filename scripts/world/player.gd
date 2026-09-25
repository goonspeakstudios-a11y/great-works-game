extends CharacterBody3D
## Third-person walker. WASD or arrow keys move relative to the camera;
## Q and E (or right-mouse drag) turn the camera.

const Blocks := preload("res://scripts/world/blocks.gd")
const SPEED := 5.5
const TURN_SPEED := 2.2
const GRAVITY := 18.0

var rig: Node3D          # camera pivot, owned by the world
var enabled := true
var body: Node3D


func _ready() -> void:
	body = Blocks.figure("You", Color(0.25, 0.4, 0.75))
	add_child(body)
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	shape.shape = cap
	shape.position.y = 0.85
	add_child(shape)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var input := Vector2.ZERO
	if enabled:
		input.x = _axis(KEY_D, KEY_RIGHT) - _axis(KEY_A, KEY_LEFT)
		input.y = _axis(KEY_S, KEY_DOWN) - _axis(KEY_W, KEY_UP)
		if rig:
			rig.rotation.y += (_axis(KEY_Q, KEY_NONE) - _axis(KEY_E, KEY_NONE)) * TURN_SPEED * delta
	var dir := Vector3(input.x, 0, input.y).normalized()
	if rig:
		dir = dir.rotated(Vector3.UP, rig.rotation.y)
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	if dir.length() > 0.1:
		body.rotation.y = lerp_angle(body.rotation.y, atan2(-dir.x, -dir.z), 12.0 * delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if enabled and rig and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rig.rotation.y -= event.relative.x * 0.005


func _axis(a: Key, b: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or (b != KEY_NONE and Input.is_physical_key_pressed(b)) else 0.0
