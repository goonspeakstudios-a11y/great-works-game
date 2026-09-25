extends "res://tests/test_base.gd"

const Character := preload("res://scripts/world/character.gd")
const Content := preload("res://scripts/content.gd")


func test_bodies_share_skeleton_with_animations() -> void:
	var lib := Character.library()
	for clip in ["Idle", "Idle_Talking", "Walk", "Jog_Fwd", "Fixing_Kneeling", "Sword_Idle"]:
		check(lib.has_animation(clip), "animation %s exists" % clip)
	check_eq(lib.get_animation("Idle").loop_mode, Animation.LOOP_LINEAR, "idle loops")
	for body in Character.BODIES:
		var c := Character.new()
		c.build("", body, "Hair_Beard", Color.RED)
		check_eq(c.skeleton.get_bone_count(), 65, "%s skeleton" % body)
		var track_path := str(lib.get_animation("Walk").track_get_path(0))
		var bone := track_path.get_slice(":", 1)
		check(c.skeleton.find_bone(bone) >= 0, "%s has animated bone %s" % [body, bone])
		check_eq(c.current, "Idle", "starts idle")
		c.play("Walk")
		check_eq(c.current, "Walk", "switches clip")
		c.free()


func test_every_scene_end_pose_is_a_real_animation() -> void:
	var content := Content.new()
	content.load_all()
	var lib := Character.library()
	for st in content.stories:
		for step in st["steps"]:
			for beat in step.get("beats", []):
				if beat.has("then"):
					check(lib.has_animation(beat["then"]), "%s: animation %s exists" % [step["id"], beat["then"]])
