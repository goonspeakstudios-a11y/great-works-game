extends Node3D
## An animated person built from the Quaternius base bodies (CC0), with a
## hairstyle, a colored tunic and a floating name. All bodies share one
## skeleton, so every clip in the Universal Animation Library fits them.

const BODIES := {
	"male": "res://assets/quaternius/characters/Superhero_Male_FullBody.gltf",
	"female": "res://assets/quaternius/characters/Superhero_Female_FullBody.gltf",
}
const HAIR_DIR := "res://assets/quaternius/hair/"
const ANIMATIONS := "res://assets/quaternius/animations/UAL1_Standard.glb"
const BLEND := 0.25
const NAME_HEIGHT := 2.05

static var _library: AnimationLibrary

var anim: AnimationPlayer
var skeleton: Skeleton3D
var current := ""


## body: "male" or "female"; hair: a file name in HAIR_DIR without .gltf, or "".
func build(display_name: String, body: String, hair: String, tunic: Color) -> void:
	var model: Node3D = load(BODIES.get(body, BODIES["male"])).instantiate()
	model.rotation.y = PI  # the models face +Z; Godot's forward is -Z
	add_child(model)
	skeleton = model.find_children("*", "Skeleton3D")[0]
	_dress(tunic)
	if hair != "":
		_add_hair(hair)
	anim = AnimationPlayer.new()
	model.add_child(anim)
	anim.root_node = anim.get_path_to(model)
	anim.add_animation_library("", library())
	play("Idle")
	if display_name != "":
		var tag := Label3D.new()
		tag.text = display_name
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.position = Vector3(0, NAME_HEIGHT, 0)
		tag.font_size = 48
		tag.pixel_size = 0.006
		tag.outline_size = 12
		add_child(tag)


static func library() -> AnimationLibrary:
	if _library == null:
		var src: Node = load(ANIMATIONS).instantiate()
		var player: AnimationPlayer = src.find_children("*", "AnimationPlayer")[0]
		_library = player.get_animation_library("").duplicate(true)
		for n in ["Idle", "Idle_Talking", "Walk", "Jog_Fwd", "Sitting_Idle", "Sword_Idle"]:
			if _library.has_animation(n):
				_library.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		src.free()
	return _library


func play(clip: String) -> void:
	if clip == current or anim == null:
		return
	if not anim.has_animation(clip):
		push_error("No animation named %s" % clip)
		return
	current = clip
	anim.play(clip, BLEND)


## A simple Greek chiton (tunic) in the given color, riding on the torso and
## hip bones so it follows the animations. Placeholder until real outfits.
func _dress(color: Color) -> void:
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = color
	cloth.roughness = 0.95
	var belt := StandardMaterial3D.new()
	belt.albedo_color = color.darkened(0.55)
	# [bone, top radius, bottom radius, height, center height in the rest pose, material]
	for part in [
		["spine_02", 0.17, 0.19, 0.5, 1.2, cloth],
		["pelvis", 0.19, 0.27, 0.46, 0.76, cloth],
		["pelvis", 0.195, 0.195, 0.05, 0.97, belt],
	]:
		var mesh := CylinderMesh.new()
		mesh.top_radius = part[1]
		mesh.bottom_radius = part[2]
		mesh.height = part[3]
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = part[5]
		var bone := skeleton.find_bone(part[0])
		var attach := BoneAttachment3D.new()
		attach.bone_name = part[0]
		skeleton.add_child(attach)
		attach.add_child(mi)
		# Place the piece where it belongs in the rest pose, whatever way the bone points.
		var want := Transform3D(Basis.from_scale(Vector3(1, 1, 0.75)), Vector3(0, part[4], 0))
		mi.transform = skeleton.get_bone_global_rest(bone).affine_inverse() * want


## Hair files carry their own copy of the skeleton; move the mesh onto ours.
func _add_hair(hair: String) -> void:
	var src: Node = load(HAIR_DIR + hair + ".gltf").instantiate()
	for mi in src.find_children("*", "MeshInstance3D"):
		mi.owner = null
		mi.get_parent().remove_child(mi)
		skeleton.add_child(mi)
		mi.skeleton = mi.get_path_to(skeleton)
	src.free()
