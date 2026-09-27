extends "res://tests/test_base.gd"
## The assets made ready for Rome and the Greek places still to come: every kit piece builds
## cleanly, the people march and the animals walk the way the Lyceum's soldiers do, the new
## materials, music and sounds are all there, and every map is ready to hang on a wall.

const Kit := preload("res://scripts/hall/kit.gd")
const Greek := preload("res://scripts/hall/kit_greek.gd")
const Rome := preload("res://scripts/hall/kit_rome.gd")
const Tex := preload("res://scripts/hall/textures.gd")
const Music := preload("res://scripts/pixel/music.gd")
const Gallery := preload("res://tools/gallery.gd")
const Areas := preload("res://scripts/hall/kit_greek_areas.gd")
const ALL_BACK := ["water", "leaves", "lamps", "walkway", "sun", "teacher", "household", "soldiers"]
## Every area set piece, by the name of its builder in kit_greek_areas.gd.
const AREAS := ["law_court", "memory_house", "museum_court", "prop_one", "prop_forty_seven",
	"ships", "scaean_gate", "achilles_hut", "forge", "walls", "ithaca_hall", "cyclops_cave", "underworld", "sirens",
	"helicon", "farm", "garden",
	"argos_palace", "areopagus", "thebes_gate", "crossroads", "antigone_tomb", "cithaeron", "pentheus_palace",
	"strepsiades_house", "thinkery", "sardis", "delphi", "thermopylae", "kerameikos", "plague", "corcyra", "melos"]
## Homer's areas, each with its playable beats.
const HOMER := ["ships", "scaean_gate", "achilles_hut", "forge", "walls", "ithaca_hall", "cyclops_cave", "underworld", "sirens"]
const People := preload("res://scripts/hall/kit_greek_people.gd")
const Thinkers := preload("res://scripts/hall/kit_greek_thinkers.gd")
const Props := preload("res://scripts/hall/kit_greek_props.gd")
## The philosophers' areas, by the name of their builder in kit_greek_thinkers.gd.
const THINKERS := ["ephesus", "elea", "court", "cephalus_house", "gyges", "the_line", "cave", "er", "symposium", "prison",
	"politics", "poetics"]

const NEW_ZONES := ["rome", "troy", "theatre", "lesbos", "alexandria", "academy", "helicon", "sardis", "kerameikos",
	"ephesus"]
const NEW_SOUNDS := ["crowd", "arena", "rain", "oars", "loom", "hooves", "flock", "crickets", "drip", "gulls", "owl", "cornu",
	"forge", "sheep", "salpinx", "shades"]
const TEXTURED := ["travertine", "tufa", "brick", "reticulatum", "basalt", "mosaic", "fresco", "porphyry", "giallo", "pine",
	"toga", "rust", "scutum", "scutum_dead", "hoplon_sparta", "hoplon_athens", "hoplon_dead", "persian", "wicker",
	"blackfigure", "papyrus", "sand", "grass", "furrows", "cave", "mist"]


func test_every_new_material_has_its_texture() -> void:
	for kind in TEXTURED:
		var m := Tex.material(kind) as StandardMaterial3D
		check(m != null and m.albedo_texture != null, "%s has a texture" % kind)
	var iron := Tex.material("iron") as StandardMaterial3D
	check(iron != null and iron.metallic > 0.0, "iron shines")
	var shadow := Tex.material("shadow") as StandardMaterial3D
	check(shadow != null and shadow.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED, "a shadow is see-through")
	for kind in ["hoplon_sparta", "hoplon_athens"]:
		var img: Image = (Tex.material(kind) as StandardMaterial3D).albedo_texture.get_image()
		check_eq(img.get_pixel(0, 0).a, 0.0, "%s is round: its corners are cut away" % kind)
	check(Tex.material("hoplon_sparta") != Tex.material("hoplon_athens"), "Sparta and Athens carry different devices")


func test_every_piece_in_the_gallery_builds() -> void:
	var pieces: Dictionary = Gallery.pieces()
	check(pieces.size() >= 45, "the gallery shows every piece (%d)" % pieces.size())
	for name in pieces:
		Kit.detail = pieces[name][0]
		for whole in [true, false]:
			var holder := Node3D.new()
			pieces[name][1].call(holder, whole)
			check(holder.find_children("*", "MeshInstance3D", true, false).size() > 0,
				"%s (%s) has something to see" % [name, "whole" if whole else "lost"])
			holder.free()
	Kit.detail = 1


func test_every_piece_has_a_lost_version() -> void:
	var pieces: Dictionary = Gallery.pieces()
	for name in pieces:
		if pieces[name].size() > 2 and not pieces[name][2]:
			continue  # never lost
		Kit.detail = pieces[name][0]
		var looks: Array = []
		for whole in [true, false]:
			var holder := Node3D.new()
			pieces[name][1].call(holder, whole)
			looks.append(_look(holder))
			holder.free()
		check(looks[0] != looks[1], "%s looks different once lost to the world" % name)
	Kit.detail = 1


## What a built thing looks like, roughly: each mesh's kind, size and stuff, sorted.
static func _look(holder: Node) -> Array:
	var out: Array = []
	for mi in holder.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var stuff := m.material_override.get_instance_id() if m.material_override else 0
		out.append("%s %s %d" % [m.mesh.get_class(), str(m.mesh.get_aabb().size.snappedf(0.01)), stuff])
	out.sort()
	return out


func test_rome_is_built_sharper_than_greece() -> void:
	var pieces: Dictionary = Gallery.pieces()
	for name in ["temple", "legionaries", "gateway", "stone_pines"]:
		check_eq(pieces[name][0], 2, "%s is built at Rome's detail" % name)
	for name in ["hoplites", "theatre", "cave", "trireme"]:
		check_eq(pieces[name][0], 1, "%s is built at Greece's detail" % name)


func test_the_new_armies_march_like_the_macedonians() -> void:
	var holder := Node3D.new()
	var shape := Kit.squad(holder, Vector3.ZERO, 1, 1)
	for sq in [Greek.phalanx(holder, Vector3.ZERO, 2, 4, "sparta"), Greek.phalanx(holder, Vector3.ZERO, 2, 4, "athens", true),
			Rome.century(holder, Vector3.ZERO, 2, 4), Rome.century(holder, Vector3.ZERO, 2, 4, true)]:
		for key in shape:
			check(sq.has(key), "a block has %s, as the Macedonians do" % key)
		check_eq(sq["legs"].size(), 16, "eight men, two legs each")
		check(sq["legs"].all(func(l): return l is Node3D), "each leg swings on its hip")
	check(Rome.century(holder, Vector3.ZERO, 1, 1, true)["speed"] < Rome.century(holder, Vector3.ZERO, 1, 1)["speed"],
		"the dead drag their feet")
	for legs in [Greek.hoplite(holder, Vector3.ZERO), Greek.immortal(holder, Vector3.ZERO), Greek.achaean(holder, Vector3.ZERO),
			Rome.legionary(holder, Vector3.ZERO)]:
		check_eq(legs.size(), 2, "every soldier walks on two legs")
	holder.free()


func test_the_undead_have_cold_eyes() -> void:
	var holder := Node3D.new()
	var builders := [func(h): Greek.hoplite(h, Vector3.ZERO, "sparta", true), func(h): Greek.immortal(h, Vector3.ZERO, true),
		func(h): Greek.achaean(h, Vector3.ZERO, true), func(h): Rome.legionary(h, Vector3.ZERO, true)]
	for build in builders:
		var one := Node3D.new()
		holder.add_child(one)
		build.call(one)
		var eyes := one.find_children("*", "MeshInstance3D", true, false).filter(
			func(m): return (m as MeshInstance3D).material_override == Tex.material("soulfire"))
		check_eq(eyes.size(), 2, "two cold lights in the skull")
	holder.free()


func test_every_animal_stands_on_four_legs() -> void:
	var holder := Node3D.new()
	for kind in Greek.BEASTS:
		var b := Greek.beast(holder, Vector3.ZERO, 0.0, kind)
		check_eq(b["legs"].size(), 4, "a %s has four legs" % kind)
		check(b["head"] is Node3D and b["tail"] is Node3D, "a %s has a head and a tail to move" % kind)
	var statue := Greek.beast(holder, Vector3.ZERO, 0.0, "horse", "bronze", 2.0)
	var mats: Array = statue["root"].find_children("*", "MeshInstance3D", true, false).map(
		func(m): return (m as MeshInstance3D).material_override)
	check(mats.all(func(m): return m == Tex.material("bronze")), "a statue is all bronze")
	check_eq(statue["root"].scale, Vector3.ONE * 2.0, "and as big as asked")
	holder.free()


func test_ships_have_their_oars() -> void:
	var holder := Node3D.new()
	check_eq(Greek.ship(holder, Vector3.ZERO, 0.0, "trireme")["oars"].size(), 102, "a trireme rows three banks of 17 a side")
	check_eq(Greek.ship(holder, Vector3.ZERO, 0.0, "pentekonter")["oars"].size(), 24, "a black ship rows one bank of 12 a side")
	holder.free()


func test_the_cave_throws_a_shadow_for_each_thing_carried() -> void:
	var holder := Node3D.new()
	var cave := Greek.cave(holder, Vector3.ZERO, 0.0)
	check_eq(cave["bearers"].size(), 4, "four things carried past the fire")
	check_eq(cave["shadows"].size(), cave["bearers"].size(), "each thing throws its shadow")
	check(cave["fire"] is OmniLight3D, "the fire lights it")
	for s in cave["shadows"]:
		var sh: Node3D = s["node"]
		check(sh.position.z < -8.0, "the shadows fall on the back wall")
		check(sh.find_children("*", "MeshInstance3D", true, false).all(
			func(m): return (m as MeshInstance3D).material_override == Tex.material("shadow")), "and are only shadows")
	holder.free()


func test_romes_gateway_keeps_greeces_promise() -> void:
	var holder := Node3D.new()
	check(Rome.gateway(holder, Vector3.ZERO, 0.0, true) is OmniLight3D, "an open gateway glows")
	check(Rome.gateway(holder, Vector3(5, 0, 0), 0.0, false) == null, "a closed one does not")
	var bodies := holder.get_child(1).find_children("*", "StaticBody3D", true, false)
	check(bodies.size() > 3, "a closed one bars the way")
	holder.free()


func test_the_theatre_has_three_doors_and_an_altar() -> void:
	var holder := Node3D.new()
	var t := Greek.theatre(holder, Vector3.ZERO, 0.0)
	check_eq(t["doors"].size(), 3, "the skene's three doors")
	check(t["crane_at"] is Vector3, "somewhere for the god to come down")
	var ruin := Greek.theatre(holder, Vector3(80, 0, 0), 0.0, 12, false)
	check(ruin["doors"].is_empty(), "the ruined skene has no doors left")
	check(ruin["root"].get_child_count() < t["root"].get_child_count(), "and fewer stones")
	holder.free()


func test_every_new_zone_has_its_music() -> void:
	for z in NEW_ZONES:
		check(Music.ZONES.has(z), "%s has its music" % z)
		var layers: Array = Music.ZONES[z]["layers"]
		var ghost: Array = layers.filter(func(l): return l["file"] == "%s_ghost" % z)
		check(ghost.size() == 1 and ghost[0].get("until", "") == "teacher", "%s is only an echo until its teacher is back" % z)
		var tunes: Array = layers.filter(func(l): return l.get("music", false))
		check(tunes.size() >= 5, "%s has its ghost and four layers" % z)
		for l in tunes:
			var stream := load(Music.file_for(l["file"])) as AudioStreamWAV
			check(stream != null, "%s loads" % l["file"])
			if stream:
				check(absf(stream.get_length() - 48.0) < 0.01, "%s is one 48 s loop, in step with the rest" % l["file"])
		check(not Music.plan(z, []).any(func(l): return l["file"] != "%s_ghost" % z and l["music"]),
			"a lost %s plays only its ghost" % z)


func test_every_new_sound_is_there() -> void:
	for f in NEW_SOUNDS:
		check(ResourceLoader.exists(Music.file_for(f)), "%s is there" % f)


func test_every_map_is_ready() -> void:
	var ids: Array = []
	for f in DirAccess.get_files_at("res://content/maps"):
		if f.ends_with(".json"):
			ids.append(f.get_basename())
	for want in ["1200bc", "480bc", "431bc", "335bc", "300bc", "44bc", "117ad", "170ad", "270ad"]:
		check(ids.has(want), "the map of %s is made" % want)
	for id in ids:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://content/maps/%s.json" % id))
		check(data is Dictionary, "%s's data loads" % id)
		if not data is Dictionary:
			continue
		check(load("res://assets/maps/%s.png" % id) is Texture2D, "%s's image loads" % id)
		check(data["regions"].size() >= 2, "%s shows at least two powers" % id)
		check(data["pins"].filter(func(p): return p["main"]).size() == 1, "%s has one main place" % id)
		for p in data["pins"]:
			check(p["at"][0] >= 0 and p["at"][0] < data["size"][0] and p["at"][1] >= 0 and p["at"][1] < data["size"][1],
				"%s: %s is on the map" % [id, p["name"]])


func test_every_area_builds_whole_and_lost_with_its_spots() -> void:
	var builders: Array = AREAS.map(func(n): return Callable(Areas, n)) + THINKERS.map(func(n): return Callable(Thinkers, n))
	for stage in 6:
		builders.append(func(h: Node3D, at: Vector3, yaw: float, back: Array) -> Dictionary:
			return Thinkers.city_in_speech(h, at, yaw, stage, back))
	for build: Callable in builders:
		var name: String = str(build.get_method()) if build.is_standard() else "city_in_speech"
		for back in [ALL_BACK, []]:
			var holder := Node3D.new()
			var area: Dictionary = build.call(holder, Vector3(3, 0, -2), 0.5, back)
			for key in ["root", "spots", "people", "flicker", "sway", "birds", "squads"]:
				check(area.has(key), "%s has %s" % [name, key])
			var spots: Dictionary = area["spots"]
			for key in ["teacher", "book", "seat", "facts", "stones"]:
				check(spots.has(key), "%s has a %s spot" % [name, key])
			check(spots["stones"].size() >= 5, "%s has room for a lesson's stones (%d)" % [name, spots["stones"].size()])
			check(spots["facts"].size() >= 2, "%s has room for its facts" % name)
			check(spots["teacher"] is Vector3 and spots["book"] is Vector3, "%s's spots are places" % name)
			check(spots["stones"].all(func(p): return p is Vector3 and Vector2(p.x - 3, p.z + 2).length() < 60.0),
				"%s's stones are in the area" % name)
			if back.is_empty():
				check(area["people"].all(func(p): return p.get("shade", false)), "%s's people are shades while it is lost" % name)
			holder.free()


func test_the_memory_house_has_twenty_places_in_order() -> void:
	var holder := Node3D.new()
	var area := Areas.memory_house(holder, Vector3.ZERO, 0.0, ALL_BACK)
	check_eq(area["loci"].size(), 20, "twenty places, five a side")
	var hands := holder.find_children("*", "MeshInstance3D", true, false).filter(
		func(m): return (m as MeshInstance3D).material_override == Tex.material("gold"))
	check(hands.size() >= 4 * 6, "a golden hand at every fifth place")
	for k in 19:
		check(area["loci"][k].distance_to(area["loci"][k + 1]) < 7.0, "place %d leads on to the next" % (k + 1))
	holder.free()


func test_the_forty_seventh_counts_nine_and_sixteen_to_twenty_five() -> void:
	var holder := Node3D.new()
	var sq: Dictionary = Greek.tiled_squares(holder, Vector3.ZERO, 0.0)["squares"]
	check_eq([sq[3].size(), sq[4].size(), sq[5].size()], [9, 16, 25], "3 x 3, 4 x 4 and 5 x 5 tiles")
	var lost: Dictionary = Greek.tiled_squares(holder, Vector3(20, 0, 0), 0.0, 1.0, false)["squares"]
	check(lost[5].size() < 25, "lost, some are missing")
	holder.free()


func test_homer_is_played_as_the_scenes_hero() -> void:
	for name in HOMER:
		var holder := Node3D.new()
		var area: Dictionary = Callable(Areas, name).call(holder, Vector3.ZERO, 0.0, ALL_BACK)
		check(area.has("beats") and not area["beats"].is_empty(), "%s has moments to play" % name)
		for beat in area.get("beats", {}):
			var b: Dictionary = area["beats"][beat]
			check(b["at"] is Vector3, "%s/%s happens somewhere" % [name, beat])
			check(People.HEROES.has(b["hero"]), "%s/%s is seen through a hero's eyes (%s)" % [name, beat, b["hero"]])
		holder.free()
	for hero in People.HEROES:
		var cam := Node3D.new()
		var arms := People.hero_arms(cam, hero)
		check_eq(arms["hands"].size(), 2, "%s has two hands in view" % hero)
		check(cam.find_children("*", "CollisionObject3D", true, false).is_empty(), "%s's arms touch nothing" % hero)
		check(arms["root"].position.z < 0.0 and arms["root"].position.y < 0.0, "%s's arms are low in front of the eyes" % hero)
		cam.free()


func test_the_underworld_is_crowded_with_the_dead() -> void:
	var holder := Node3D.new()
	var area := Areas.underworld(holder, Vector3.ZERO, 0.0, ALL_BACK)
	check(area["shades"].size() >= 16, "the dead come in crowds")
	var named: Array = area["shades"].map(func(s): return s["who"]).filter(func(w): return w != "")
	for who in ["teiresias", "anticleia", "elpenor", "achilles_shade"]:
		check(named.has(who), "%s is among them" % who)
	check(area["shades"].all(func(s): return s["home"].distance_to(s["trench"]) > 3.0), "they begin away from the blood")
	check(area["people"].all(func(p): return p.get("shade", false)), "every one of them a shade, even when all is back")
	holder.free()


func test_the_cyclops_cave_is_shut_by_its_stone() -> void:
	var holder := Node3D.new()
	var area := Areas.cyclops_cave(holder, Vector3.ZERO, 0.0, ALL_BACK)
	check(area["stone"] is Node3D and not area["stone"].find_children("*", "CollisionObject3D", true, false).is_empty(),
		"the stone bars the way out")
	check(area["rams"].size() >= 3, "rams to cling under")
	check(area["cyclops"].has("eye"), "his one eye")
	holder.free()


func test_the_areopagus_votes_and_thermopylae_has_both_armies() -> void:
	var holder := Node3D.new()
	var court := Areas.areopagus(holder, Vector3.ZERO, 0.0, ALL_BACK)
	check(court["urns"] is Vector3, "the urns stand ready")
	check(court["people"].size() >= 12 + 5, "twelve judges and the Furies")
	var narrows := Areas.thermopylae(holder, Vector3(200, 0, 0), 0.0, ALL_BACK)
	check_eq(narrows["squads"].size(), 2, "the Spartans and the Immortals")
	for sq in narrows["squads"]:
		check(sq.has("legs") and sq.has("speed"), "each marches like the Macedonians")
	var funeral := Areas.kerameikos(holder, Vector3(400, 0, 0), 0.0, ALL_BACK)
	check_eq(funeral["coffins"].size(), 10, "a coffin for each of the ten tribes")
	holder.free()


func test_the_divided_line_is_cut_in_plato_s_proportion() -> void:
	var holder := Node3D.new()
	var area := Thinkers.the_line(holder, Vector3.ZERO, 0.0, ALL_BACK)
	var segs: Array = area["segments"]
	check_eq(segs.map(func(s): return s["name"]), ["images", "things", "mathematicals", "forms"], "four parts, dim to bright")
	var lengths: Array = segs.map(func(s): return (s["from"] as Vector3).distance_to(s["to"]))
	check(is_equal_approx(lengths[1] / lengths[0], (lengths[2] + lengths[3]) / (lengths[0] + lengths[1])),
		"the visible part is cut in the same ratio as the whole line")
	check(is_equal_approx(lengths[3] / lengths[2], lengths[1] / lengths[0]), "and so is the intelligible part")
	check(is_equal_approx(lengths[1], lengths[2]), "so the two middle parts come out equal")
	holder.free()


func test_er_sees_the_spindle_and_the_lives() -> void:
	var holder := Node3D.new()
	var area := Thinkers.er(holder, Vector3.ZERO, 0.0, ALL_BACK)
	check_eq(area["whorls"].size(), 8, "eight whorls, one inside the next")
	check(area["speeds"][7] < area["speeds"][1] and area["speeds"][0] > 0.0 and area["speeds"][1] < 0.0,
		"the whole turns one way, the inner seven the other, the eighth fastest")
	check(area["lives"].size() > 6, "more patterns of lives than souls choosing at once")
	check(area["banks"].size() >= 3, "room at Lethe's bank to drink")
	var still := Props.spindle_of_necessity(holder, Vector3(100, 0, 0), false)
	check(still["speeds"].all(func(v): return v == 0.0), "lost, the whorls stand still")
	var gyges := Thinkers.gyges(holder, Vector3(200, 0, 0), 0.0, ALL_BACK)
	check(gyges["ring"] is Node3D, "the ring is in the horse")
	check(Thinkers.gyges(holder, Vector3(300, 0, 0), 0.0, [])["ring"] == null, "and gone when the place is lost")
	holder.free()


func test_the_city_in_speech_grows_and_turns_into_the_soul() -> void:
	var holder := Node3D.new()
	var last := -1
	for stage in 6:
		var city := Thinkers.city_in_speech(holder, Vector3(stage * 120.0, 0, 0), 0.0, stage, ALL_BACK)
		check_eq(city["stage"], stage, "stage %d is built" % stage)
		check(city["buildings"].size() > last or stage == 0, "stage %d raises more buildings than the last" % stage)
		last = city["buildings"].size()
		check(city["slots"].is_empty() == (stage == 5), "stage %d %s" % [stage, "is finished" if stage == 5 else "has room for the next"])
		check(city["soul"]["root"].visible == (stage == 5), "the soul shows %s" % ("at last" if stage == 5 else "not yet"))
		check_eq(city["soul"]["parts"].keys(), ["appetite", "spirit", "reason"], "the soul has its three parts")
		var orders: Dictionary = city["orders"]
		check((orders["producers"].size() > 0) == (stage >= 1), "stage %d: the producers" % stage)
		check((orders["auxiliaries"].size() > 0) == (stage >= 3), "stage %d: the auxiliaries" % stage)
		check((orders["guardians"].size() > 0) == (stage >= 4), "stage %d: the guardians" % stage)
		check(city["soul"]["root"].find_children("*", "CollisionObject3D", true, false).is_empty(), "the soul is not in the way")
	holder.free()
