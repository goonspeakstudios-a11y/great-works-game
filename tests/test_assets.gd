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

const NEW_ZONES := ["rome", "troy", "theatre", "lesbos", "alexandria", "academy", "helicon", "sardis", "kerameikos",
	"ephesus"]
const NEW_SOUNDS := ["crowd", "arena", "rain", "oars", "loom", "hooves", "flock", "crickets", "drip", "gulls", "owl", "cornu",
	"forge", "sheep", "salpinx", "shades"]
const TEXTURED := ["travertine", "tufa", "brick", "reticulatum", "basalt", "mosaic", "fresco", "porphyry", "giallo", "pine",
	"toga", "rust", "scutum", "scutum_dead", "hoplon_sparta", "hoplon_athens", "hoplon_dead", "persian", "wicker",
	"blackfigure", "papyrus", "sand", "grass", "furrows", "cave"]


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
		var holder := Node3D.new()
		Kit.detail = pieces[name][0]
		pieces[name][1].call(holder)
		var meshes := holder.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() > 0, "%s has something to see" % name)
		holder.free()
	Kit.detail = 1


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
