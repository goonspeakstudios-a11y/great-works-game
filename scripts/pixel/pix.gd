extends RefCounted
## Palette, sprite maps and drawing helpers for the pixel look.
## The game draws at 320x180 and the window scales it up by whole numbers.

const W := 320
const H := 180

const P := {
	"void": Color("0d0c10"), "stoneDD": Color("1e1b22"), "stoneD": Color("2e2a33"),
	"stone": Color("4a4450"), "stoneL": Color("6c6470"), "ash": Color("a9a092"),
	"bone": Color("d6ccba"), "cloak": Color("3c4a52"), "cloakD": Color("26323a"),
	"skin": Color("c8a484"), "wood": Color("5a4632"), "ghost": Color("a6c8cc"),
	"ghostD": Color("5f858c"), "gold": Color("e0b660"), "ember": Color("d0602c"),
	"emberL": Color("f0b050"), "red": Color("8a2e2a"), "tunic": Color("d8ccb4"),
	"leaf": Color("6f8a4a"), "leafD": Color("4a5e32"), "horse": Color("7a5236"),
	"horseL": Color("9a6e4a"), "bars": Color("c05040"),
}

const HERO := [[
	"...hhh..w", "..hhhhh.w", "..hhhff.w", "..hhhff.w", "...hhh..w", "..ccccc.w",
	".ccccccaw", ".cCcccc.w", ".cCcccc.w", ".cCcccc.w", ".cCccccCw", "..cCccCCw",
	"..cccccCw", "..l...l.w", "..l...l.."], [
	"...hhh..w", "..hhhhh.w", "..hhhff.w", "..hhhff.w", "...hhh..w", "..ccccc.w",
	".ccccccaw", ".cCcccc.w", ".cCcccc.w", ".cCcccc.w", ".cCccccCw", "..cCccCCw",
	"..cccccCw", "...l.l..w", "...l.l..."]]
const HERO_PAL := {"h": "cloak", "f": "skin", "c": "cloak", "C": "cloakD", "l": "cloakD", "w": "wood", "a": "skin"}

const THING := {
	"stone": ["..sSs..", ".sLsSS.", "sLssssS", "sssssSS", ".SSSSS."],
	"oak": ["..gGg..", ".gggGg.", "gGgggGg", ".gGgGg.", "...w...", "...w...", ".ppppp.", "..ppp.."],
	"horse": ["........HH..", ".......HHHH.", "......HHH.HH", "HHHHHHHHH...", "HhhhhhhhH...",
		".HHHHHHH....", ".H.H..H.H...", ".H.H..H.H..."],
	"masked": ["....HH...", "...HHHH..", "..HHH.HH.", "...HHH...", "....f....", "..ccccc..",
		".cbbbbbc.", ".cbbbbbc.", ".cbbbbbc.", "..bbbbb..", "..k...k..", "..l...l.."],
}
const THING_PAL := {"s": "stone", "S": "stoneD", "L": "stoneL", "g": "leaf", "G": "leafD", "w": "wood",
	"p": "red", "H": "horse", "h": "horseL", "f": "skin", "c": "red", "b": "tunic", "k": "tunic", "l": "skin"}

const MAN := ["....fff....", "...fffff...", "...fffff...", "....fff....", ".....f.....",
	"..bbbbbbb..", ".bbbbbbbbb.", ".f.bbbbb.f.", ".f.bbbbb.f.", ".f.bbbbb.f.", "...bbbbb...",
	"...bbbbb...", "...kkkkk...", "...kkkkk...", "...l...l...", "...l...l...", "...l...l...",
	"..ll...ll.."]
const MAN_CLOAK := ["...........", "...........", "...........", "...........", "...........",
	".cc.....cc.", ".cc.....cc.", "cc.......cc", "cc.......cc", "cc.......cc", "c.........c",
	"...........", "...........", "...........", "...........", "...........", "...........",
	"..........."]
const MAN_WREATH := ["...gGgGg...", "..g.....g..", "...........", "...........", "...........",
	"...........", "...........", "...........", "...........", "...........", "...........",
	"...........", "...........", "...........", "...........", "...........", "...........",
	"..........."]
const MAN_MASK := [".....HHH...", "...HHHHHH..", "..HHHHHhHH.", "...HHH..HH.", "....HH.....",
	"...........", "...........", "...........", "...........", "...........", "...........",
	"...........", "...........", "...........", "...........", "...........", "...........",
	"..........."]
const MAN_PAL := {"f": "skin", "b": "tunic", "k": "tunic", "l": "skin", "c": "red", "g": "leaf",
	"G": "leafD", "H": "horse", "h": "horseL"}

## 7x7 icons: the four differences on the tree, and the statue's marks.
const ICON := {
	"body": ["..LLL..", ".LLLLL.", "LLLLLLS", "sLLLLSS", "ssLLSSS", ".ssSSS.", "..sSS.."],
	"life": ["...g...", ".gg.gg.", "gGg.gGg", ".g.g.g.", "...g...", "...g...", ".www..."],
	"senses": [".......", "..bbb..", ".bbkbb.", "bbkKkbb", ".bbkbb.", "..bbb..", "......."],
	"reason": ["...o...", "..oo...", "..oyo..", ".oyyo..", ".oyyyo.", ".oyyyo.", "..ooo.."],
	"cloak": [".ccccc.", "cccCccc", "ccCcCcc", "ccCcCcc", "cCccCcc", "cCcccCc", "ccc.ccc"],
	"wreath": ["..gGg..", ".g...g.", "g.....G", "G.....g", "g.....G", ".g...g.", "..GgG.."],
	"mask": ["....HH.", "..HHHH.", ".HHHhHH", "HHHH.HH", ".HHH...", "..HH...", "......."],
	"laugh": [".bbbbb.", "bbbbbbb", "bk.b.kb", "bbbbbbb", "bkbbbkb", ".bkkkb.", "..bbb.."],
	"flame": ["...o...", "..oo...", "..oyo..", ".oyyo..", ".oyyyo.", ".oyyyo.", "..ooo.."],
}
const ICON_PAL := {"L": "stoneL", "s": "stone", "S": "stoneD", "g": "leaf", "G": "leafD", "w": "wood",
	"b": "bone", "k": "void", "K": "stoneDD", "o": "ember", "y": "emberL", "c": "red", "C": "void",
	"H": "horse", "h": "horseL"}

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func dith(x: int, y: int) -> float:
	return (BAYER[(x & 3) + ((y & 3) << 2)] + 0.5) / 16.0


## Draws a sprite map with its bottom-centre at `feet`.
static func sprite(ci: CanvasItem, rows: Array, pal: Dictionary, feet: Vector2, s: int = 1,
		flip: bool = false, alpha: float = 1.0, outline: bool = true) -> void:
	if outline:
		var edge := {}
		for k in pal:
			edge[k] = "void"
		for o in [Vector2(-s, 0), Vector2(s, 0), Vector2(0, -s), Vector2(0, s)]:
			sprite(ci, rows, edge, feet + o, s, flip, alpha * 0.8, false)
	var h := rows.size()
	var w := (rows[0] as String).length()
	var ox := roundi(feet.x - w * s / 2.0)
	var oy := roundi(feet.y) - h * s
	for j in h:
		var row: String = rows[j]
		for i in w:
			var ch := row[w - 1 - i] if flip else row[i]
			if ch == "." or not pal.has(ch):
				continue
			var col: Color = P[pal[ch]]
			col.a *= alpha
			ci.draw_rect(Rect2(ox + i * s, oy + j * s, s, s), col)


static func text(ci: CanvasItem, at: Vector2, words: String, size: int, col: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(roundf(at.x - width / 2.0), roundf(at.y))
	ci.draw_string(font, pos + Vector2(0, 0.5), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a * 0.9))
	ci.draw_string(font, pos, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
