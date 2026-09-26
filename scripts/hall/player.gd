extends CharacterBody3D
## First-person walker. WASD or the arrow keys to move, Shift to sprint, Space to jump, Q/E or the
## left/right arrows to turn, and the mouse to look all the way around. Frozen while a
## panel is open.

const SPEED := 2.5
const SPRINT := 4.6
const SPRINT_MAX := 7.5  # holding Shift builds up to this
const SPRINT_BUILD := 4.0  # seconds of holding to get there
const TURN := 2.0
const MOUSE := 0.0025
const EYE := 1.55
const JUMP := 4.2  # about half a metre up

var camera: Camera3D
var frozen := false
var seated := false  # sitting on a bench: look around, no walking
var speed_scale := 1.0  # the Esc menu's walking speed
var look_scale := 1.0  # and its mouse speed
var _sprint_held := 0.0
var _pitch := 0.0
var _bob := 0.0
var _shape: CollisionShape3D


func _init() -> void:
	_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	_shape.shape = capsule
	_shape.position.y = 0.85
	add_child(_shape)
	camera = Camera3D.new()
	camera.position.y = EYE
	camera.fov = 70.0
	camera.near = 0.05
	camera.far = 900.0
	add_child(camera)


func look(delta: Vector2) -> void:
	rotation.y -= delta.x * MOUSE * look_scale
	_pitch = clampf(_pitch - delta.y * MOUSE * look_scale, -1.35, 1.35)
	camera.rotation.x = _pitch


## Which way the camera faces, flat on the floor.
func facing() -> Vector3:
	return -global_transform.basis.z


## Sit at a spot facing yaw. The bench is solid, so the body stops colliding while seated:
## otherwise physics would push it up on top of the seat.
func sit(at: Vector3, yaw: float) -> void:
	seated = true
	_shape.disabled = true
	position = Vector3(at.x, position.y, at.z)
	rotation.y = yaw
	velocity = Vector3.ZERO


## Stand up (optionally stepping aside first); a no-op when already standing.
func stand(step: Vector3 = Vector3.ZERO) -> void:
	if not seated:
		return
	seated = false
	_shape.disabled = false
	position += step
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if seated:  # no collision while seated, so no gravity and no sliding either
		camera.position.y = lerpf(camera.position.y, EYE - 0.45, minf(1.0, delta * 3.0))
		return
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
	var sprinting := Input.is_action_pressed("sprint") and dir.length() > 0.1
	_sprint_held = _sprint_held + delta if sprinting else 0.0
	var run := lerpf(SPRINT, SPRINT_MAX, smoothstep(0.0, SPRINT_BUILD, _sprint_held))
	var speed := (run if sprinting else SPEED) * speed_scale
	if InputMap.has_action("jump") and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	if dir.length() > 0.1:
		_bob += delta * (12.0 if Input.is_action_pressed("sprint") else 8.0)
		camera.position.y = EYE + sin(_bob) * 0.03
	else:
		camera.position.y = lerpf(camera.position.y, EYE, delta * 6.0)
