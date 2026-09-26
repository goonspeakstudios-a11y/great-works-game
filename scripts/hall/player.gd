extends CharacterBody3D
## First-person walker. WASD or the arrow keys to move, Shift to sprint, Q/E or the
## left/right arrows to turn, and the mouse to look all the way around. Frozen while a
## panel is open.

const SPEED := 2.5
const SPRINT := 4.6
const TURN := 2.0
const MOUSE := 0.0025
const EYE := 1.55

var camera: Camera3D
var frozen := false
var _pitch := 0.0
var _bob := 0.0


func _init() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = EYE
	camera.fov = 70.0
	camera.near = 0.05
	camera.far = 900.0
	add_child(camera)


func look(delta: Vector2) -> void:
	rotation.y -= delta.x * MOUSE
	_pitch = clampf(_pitch - delta.y * MOUSE, -1.35, 1.35)
	camera.rotation.x = _pitch


## Which way the camera faces, flat on the floor.
func facing() -> Vector3:
	return -global_transform.basis.z


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	if frozen:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	rotation.y += (Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")) * TURN * delta
	var fwd := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var side := Input.get_action_strength("strafe_right") - Input.get_action_strength("strafe_left")
	var dir := (global_transform.basis * Vector3(side, 0, -fwd))
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	var speed := SPRINT if Input.is_action_pressed("sprint") else SPEED
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	if dir.length() > 0.1:
		_bob += delta * (12.0 if Input.is_action_pressed("sprint") else 8.0)
		camera.position.y = EYE + sin(_bob) * 0.03
	else:
		camera.position.y = lerpf(camera.position.y, EYE, delta * 6.0)
