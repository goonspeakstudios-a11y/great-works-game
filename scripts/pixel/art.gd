extends RefCounted
## Characters, props and backgrounds for the guided stories, all drawn in code.
## People are built from a hair style, a beard and a palette; props are small maps;
## backgrounds are 320x180 images built once per stage.

const Pix := preload("res://scripts/pixel/pix.gd")

const SKIN := "c49a78"
const BODY := [
	"..rrrrrrrr..", ".rrrrrrrrRr.", ".rrtrrrrrRr.", ".rrrtrrrrRr.", ".frrrtrrrRf.",
	"..rrrrtrrR..", "..rrrrrtrR..", "..rrrrrrrR..", "..rrrrrrrR..", "..rrrrrrrR..",
	"..rrrrrrrR..", "...s....s..."]


## A standing person, 12 x 19. hair: bald, short, long or wrap (a veil or cap).
## beard: none, short or long.
static func person(hair: String, beard: String) -> Array:
	var rows: Array = []
	match hair:
		"bald":
			rows += ["....ffff....", "...ffffff..."]
		"wrap":
			rows += ["....vvvv....", "...vvvvvv..."]
		_:
			rows += ["....hhhh....", "...hhhhhh..."]
	var l: String = {"long": "..h", "wrap": "..v"}.get(hair, "...")
	var r: String = {"long": "h..", "wrap": "v.."}.get(hair, "...")
	rows += [l + "ffffff" + r, l + "feffef" + r, l + "ffffff" + r]
	match beard:
		"short":
			rows += ["...BffffB...", "....BBBB...."]
		"long":
			rows += ["...BBBBBB...", "....BBBB...."]
		_:
			rows += ["....ffff....", ".....ff....."]
	return rows + BODY


static func colors(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[k] = Color(d[k])
	return out


static func pal(hair: String, robe: String, robe_dark: String, trim: String, beard: String = "",
		skin: String = SKIN) -> Dictionary:
	return colors({"h": hair, "v": hair, "f": skin, "e": "2a1a14", "B": beard if beard != "" else hair,
		"r": robe, "R": robe_dark, "t": trim, "s": "5a3a22"})


static func actor(who: String, hair: String, beard: String, palette: Dictionary, at: Vector2,
		scale: int = 2) -> Dictionary:
	return {"name": who, "rows": person(hair, beard), "pal": palette, "at": at, "scale": scale,
		"alpha": 1.0, "visible": true}


# ---------- props: 10x10 maps with their own colours ----------

const PROP_PAL := {
	"s": "4a4450", "S": "2e2a33", "L": "8c8490", "o": "b0643a", "O": "7a4028", "g": "6f8a4a",
	"G": "4a5e32", "w": "6a4e32", "r": "c03a3a", "R": "7a2020", "y": "e0b050", "Y": "a07a30",
	"q": "5a8ab0", "Q": "3a5a7a", "H": "7a5236", "h": "9a6e4a", "d": "a08058", "D": "6a5038",
	"e": "6a4a2a", "W": "e8e4dc", "f": "c49a78", "k": "1a1410", "B": "d0ccc4", "n": "5a3a24",
	"t": "d8d0c0", "c": "3a5a8a", "x": "9aa4b0", "X": "5a6470", "z": "f0e070", "b": "f4f0e8",
}
const PROP := {
	"stone": ["..........", "..........", "..........", "...sLs....", "..sLsss...", ".sssssSs..",
		".ssssSSS..", "..SSSSS...", "..........", ".........."],
	"statue": ["...LLL....", "..LLLLL...", "..LLLL....", "...LL.....", "..LLLLL...", ".LLLLLLL..",
		"..LLLLL...", "...sss....", "..sssss...", ".SSSSSSS.."],
	"jar": ["..oo..oo..", "...oooo...", "...oOoo...", "..oooooo..", ".ooooooOo.", ".oooooOOo.",
		".ooooooOo.", "..ooooOo..", "...oooo...", "....oo...."],
	"oak": ["...gGg....", ".ggGggGg..", "gGgggGggg.", "ggGggggGg.", ".gGgGggg..", "...ggg....",
		"....w.....", "....w.....", "...www....", "..wwwww..."],
	"rose": ["....rr....", "...rRrr...", "...rrRr...", "....rr....", "....g.....", "..gg.g....",
		"....g.gg..", "....g.....", "....g.....", "....g....."],
	"wheat": [".y..y..y..", ".yy.yy.yy.", ".yy.yy.yy.", ".y..y..y..", ".w..w..w..", ".w..w..w..",
		"..w.w.w...", "...www....", "....w.....", "....w....."],
	"fish": ["..........", "..........", ".q...qqq..", ".qq.qqqqq.", ".qqqqqqkqq", ".qq.qqqqq.",
		".q...qqq..", "..........", "..........", ".........."],
	"horse": ["......HH..", ".....HHHH.", "....HHH.HH", "HHHHHHH...", "HhhhhhH...", ".HHHHHH...",
		".H.H.H.H..", ".H.H.H.H..", "..........", ".........."],
	"dog": ["..........", ".......dd.", ".......ddd", "d.dddddd..", ".ddddddd..", "..dDdddD..",
		"..d.d.d.d.", "..d.d.d.d.", "..........", ".........."],
	"eagle": ["....WW....", "...WWWy...", "e..eeee..e", "ee.eeee.ee", "eeeeeeeeee", ".eeeeeeee.",
		"...eeee...", "...e..e...", "..........", ".........."],
	"socrates": ["...ffff...", "..ffffff..", "..fkffkf..", "..ffffff..", "..BBffBB..", "...BBBB...",
		"..tttttt..", ".tttttttt.", ".tttttttt.", ".tttttttt."],
	"plato": ["..nnnnnn..", "..nffffn..", "..fkffkf..", "..ffffff..", "..nnnnnn..", "...nnnn...",
		"..cccccc..", ".ccctcccc.", ".cccttccc.", ".ccccttcc."],
	"coin": ["..........", "..........", "...yyyy...", "..yzyyYy..", "..yyyyYy..", "..yyyyYy..",
		"..yYYYYy..", "...yyyy...", "..........", ".........."],
	"trumpet": ["..........", "........yy", "......yyyy", "yyyyyyyyzy", "YYYYYYYyyy", "......yyyy",
		"........yy", "..........", "..........", ".........."],
	"goat": ["..........", "..W....W..", "...WWWWW..", "..WWkWkW..", "...WWWWW..", "WWWWWWWW..",
		"WWWWWWWW..", ".W.W.W.W..", ".W.W.W.W..", ".........."],
	"cloud": ["...xxxx...", ".xxxxxxxx.", "xxxXxxxxxx", "xXXXXXXXXx", ".XXXXXXXX.", "...z..z...",
		"..z..z....", "...z..z...", "..z...z...", ".........."],
	"toga_goat": ["..........", "..W....W..", "...WWWWW..", "..WWkWkW..", "...WWWWW..", "rbbbbbbb..",
		"brbbbbbb..", ".W.W.W.W..", ".W.W.W.W..", ".........."],
	"baker": ["...bbbb...", "..bbbbbb..", "...ffff...", "...fkkf...", "...ffff...", "bbbbbbbbbb",
		"bbbbbbbbbb", "..bbbbbb..", "..bb..bb..", "..bb..bb.."],
	"bread": ["..........", "..........", "...oooo...", "..oyoyoo..", ".oooooooo.", ".oOOOOOOo.",
		"..........", "..........", "..........", ".........."],
	"amulet": ["...y..y...", "....yy....", "....yy....", "...rrrr...", "..rRrrRr..", "..rrzzrr..",
		"..rRrrRr..", "...rrrr...", "..........", ".........."],
	"oil": ["....oo....", "....oo....", "...yyyy...", "..yyyyyy..", "..yyyYyy..", "..yyyYyy..",
		"..yyyyyy..", "...yyyy...", "..........", ".........."],
	"cloak": ["..cccccc..", ".cccccccc.", ".ccQcccQc.", ".cccQcQcc.", ".ccccQccc.", ".cccccccc.",
		".cccccccc.", "..........", "..........", ".........."],
}


static func prop(ci: CanvasItem, what: String, feet: Vector2, s: int = 1, alpha: float = 1.0) -> void:
	var p := {}
	for k in PROP_PAL:
		p[k] = Color(PROP_PAL[k])
	Pix.sprite(ci, PROP[what], p, feet, s, false, alpha)


# ---------- backgrounds ----------

static func _img() -> Image:
	return Image.create(Pix.W, Pix.H, false, Image.FORMAT_RGBA8)


static func _rect(img: Image, x: int, y: int, w: int, h: int, c: String) -> void:
	img.fill_rect(Rect2i(x, y, w, h), Color(c))


## Fills a rectangle with a few tones picked at random, for plaster, sand and grass.
static func _grain(img: Image, x: int, y: int, w: int, h: int, tones: Array, rng: RandomNumberGenerator) -> void:
	var cs := tones.map(func(c): return Color(c))
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var n := rng.randf()
			img.set_pixel(xx, yy, cs[0] if n < 0.7 else (cs[1] if n < 0.92 else cs[2]))


static func _tiles(img: Image, y0: int, tw: int, th: int, a: String, b: String, mortar: String) -> void:
	for y in range(y0, Pix.H):
		for x in Pix.W:
			var bx := x / tw
			var by := (y - y0) / th
			var c := a if (bx + by) % 2 == 0 else b
			if x % tw == 0 or (y - y0) % th == 0:
				c = mortar
			img.set_pixel(x, y, Color(c))


static func _column(img: Image, x: int, top: int, bottom: int) -> void:
	_rect(img, x - 2, top, 14, 3, "e0d8c8")
	_rect(img, x, top + 3, 10, bottom - top - 6, "d8d0c0")
	_rect(img, x + 7, top + 3, 3, bottom - top - 6, "aaa294")
	for fx in [x + 2, x + 5]:
		_rect(img, fx, top + 3, 1, bottom - top - 6, "c4bcac")
	_rect(img, x - 2, bottom - 3, 14, 3, "c8c0b0")


static func tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


static func villa() -> ImageTexture:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	_grain(img, 0, 0, Pix.W, 104, ["b8a484", "ac987a", "c4b294"], rng)
	_rect(img, 0, 76, Pix.W, 1, "c8a060")
	_rect(img, 0, 78, Pix.W, 8, "8a3a2a")
	_rect(img, 0, 87, Pix.W, 1, "c8a060")
	for y in range(16, 70):  # the window: sunset over the sea
		for x in range(24, 96):
			var c := "e8b070" if y < 30 else ("d8905c" if y < 40 else ("c07050" if y < 48 else ("3a5a7a" if (x + y * 3) % 17 else "5a7a9a")))
			img.set_pixel(x, y, Color(c))
	_rect(img, 22, 14, 76, 2, "6a5040")
	_rect(img, 22, 70, 76, 3, "6a5040")
	_rect(img, 22, 14, 2, 58, "6a5040")
	_rect(img, 96, 14, 2, 58, "6a5040")
	_rect(img, 58, 16, 2, 54, "6a5040")
	_rect(img, 0, 100, Pix.W, 4, "5a3a2a")
	_tiles(img, 104, 16, 8, "7a4a32", "6a4030", "4a2a1e")
	_rect(img, 172, 8, 140, 88, "3a2a1e")  # the game board
	_rect(img, 174, 10, 136, 84, "5a4028")
	return tex(img)


static func lyceum() -> ImageTexture:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 70:
		for x in Pix.W:
			img.set_pixel(x, y, Color("9ec0d4") if y < 40 else Color("b8d0dc"))
	for i in 9:  # olive trees behind the walk
		var cx := 20 + i * 38 + rng.randi_range(-6, 6)
		for y in range(40, 92):
			for x in range(maxi(0, cx - 18), mini(Pix.W, cx + 18)):
				if Vector2((x - cx) / 1.3, y - 62).length() < 17 + rng.randf() * 3:
					img.set_pixel(x, y, Color("4e6a3e") if rng.randf() < 0.7 else Color("3a5230"))
	_rect(img, 0, 0, Pix.W, 12, "c8bca8")
	for x in range(0, Pix.W, 8):
		_rect(img, x, 10, 4, 3, "a89c88")
	_grain(img, 0, 92, Pix.W, 20, ["8a9a6a", "7a8a5a", "9aaa7a"], rng)
	for x in range(18, Pix.W, 48):
		_column(img, x, 12, 112)
	_tiles(img, 112, 20, 10, "a89a88", "9a8c7a", "7a6c5c")
	return tex(img)


static func agora() -> ImageTexture:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	_rect(img, 0, 0, Pix.W, 34, "a8c4d4")
	_rect(img, 0, 28, Pix.W, 8, "c8bca8")
	_rect(img, 0, 36, Pix.W, 48, "b0a490")
	for x in range(6, Pix.W, 30):
		_rect(img, x, 36, 8, 48, "d0c8b8")
		_rect(img, x + 6, 36, 2, 48, "a0988a")
	_grain(img, 0, 84, Pix.W, 96, ["9a8a6a", "8a7a5a", "aa9a7a"], rng)
	for stall in [[196, 124], [8, 70]]:  # striped awnings over wooden counters
		var sx: int = stall[0]
		var w: int = stall[1]
		for x in range(sx, sx + w):
			var c := "8a3a2a" if ((x - sx) / 8) % 2 == 0 else "d8d0c0"
			_rect(img, x, 58, 1, 12, c)
		_rect(img, sx, 70, w, 2, "5a3a2a")
		_rect(img, sx + 2, 72, 3, 34, "5a4028")
		_rect(img, sx + w - 5, 72, 3, 34, "5a4028")
		_rect(img, sx, 100, w, 12, "6a4a30")
		_rect(img, sx, 100, w, 2, "8a6a48")
	return tex(img)


static func roman_room() -> ImageTexture:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	_grain(img, 0, 0, Pix.W, 60, ["c8b890", "bcac84", "d0c098"], rng)
	_rect(img, 0, 60, Pix.W, 40, "8a3a2a")
	for x in range(20, Pix.W, 60):
		_rect(img, x, 64, 36, 32, "7a3024")
		_rect(img, x + 2, 66, 32, 28, "9a4a36")
	_rect(img, 0, 100, Pix.W, 4, "3a2a20")
	_tiles(img, 104, 8, 8, "d8d0c0", "2a2622", "b0a898")
	return tex(img)


static func court() -> ImageTexture:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	_grain(img, 0, 0, Pix.W, 100, ["b8ac94", "aca088", "c4b8a0"], rng)
	for x in range(10, Pix.W, 52):
		_column(img, x, 0, 100)
	_rect(img, 110, 62, 100, 38, "8a7a64")  # the judge's platform
	_rect(img, 110, 62, 100, 3, "a89a84")
	_rect(img, 150, 44, 20, 22, "6a2a2a")
	_tiles(img, 100, 20, 10, "c8c0b0", "b8b0a0", "8a8272")
	for y in [118, 138]:
		_rect(img, 4, y, 70, 6, "6a4a30")
		_rect(img, 246, y, 70, 6, "6a4a30")
	return tex(img)


## Top-down plan of your house: five rooms in a row, doors between them.
const HOUSE_ROOMS := [Rect2i(12, 44, 52, 84), Rect2i(68, 44, 58, 84), Rect2i(130, 44, 58, 84),
	Rect2i(192, 44, 58, 84), Rect2i(254, 44, 56, 84)]


static func house() -> ImageTexture:
	var img := _img()
	_rect(img, 0, 0, Pix.W, Pix.H, "141218")
	_rect(img, 8, 40, 306, 92, "5a4a3a")
	for i in HOUSE_ROOMS.size():
		var r: Rect2i = HOUSE_ROOMS[i]
		var a: String = ["c8bca0", "d0c4a8", "b8a888", "c8b89c", "6a8a4a"][i]
		var b: String = ["b0a488", "b8ac90", "a09070", "b0a084", "5a7a3e"][i]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				img.set_pixel(x, y, Color(a if ((x / 6) + (y / 6)) % 2 == 0 else b))
		if i < HOUSE_ROOMS.size() - 1:
			_rect(img, r.end.x, 76, 4, 20, a)  # door to the next room
	_rect(img, 84, 70, 26, 26, "3a6a8a")  # atrium pool
	_rect(img, 86, 72, 22, 22, "4a7a9a")
	_rect(img, 134, 48, 20, 10, "5a3a2a")  # kitchen hearth
	_rect(img, 138, 50, 12, 6, "c05a2a")
	for yy in [52, 110]:  # dining couches
		_rect(img, 200, yy, 42, 10, "8a2e2a")
	for p in [Vector2i(262, 52), Vector2i(296, 60), Vector2i(270, 112), Vector2i(298, 108)]:
		_rect(img, p.x, p.y, 8, 8, "3a5a2a")
	_rect(img, 8, 76, 4, 20, "c8bca0")  # front door
	return tex(img)


static func site() -> ImageTexture:
	var img := _img()
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for y in 50:
		for x in Pix.W:
			img.set_pixel(x, y, Color("e8d8b0") if y < 20 else Color("c8dce4"))
	_rect(img, 0, 44, Pix.W, 10, "4a7a9a")
	for x in range(6, 110, 14):  # the Library's colonnade far off
		_rect(img, x, 26, 6, 20, "d8d0c0")
	_rect(img, 2, 22, 112, 5, "c8c0b0")
	_grain(img, 0, 54, Pix.W, 126, ["c8b48a", "bca47a", "d4c49a"], rng)
	for b in [[262, 92], [276, 92], [268, 84], [290, 100], [240, 110]]:
		_rect(img, b[0], b[1], 14, 8, "b0a898")
		_rect(img, b[0], b[1], 14, 2, "d0c8b8")
	return tex(img)
