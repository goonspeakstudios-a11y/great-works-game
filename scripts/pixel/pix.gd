extends RefCounted
## Palette and drawing helpers for the pixel look.
## The game draws at 320x180 and the window scales it up by whole numbers.

const W := 320
const H := 180

const P := {
	"void": Color("0d0c10"), "stoneDD": Color("1e1b22"), "stoneD": Color("2e2a33"),
	"stone": Color("4a4450"), "stoneL": Color("6c6470"), "ash": Color("a9a092"),
	"bone": Color("d6ccba"), "ghost": Color("a6c8cc"), "ghostD": Color("5f858c"),
	"gold": Color("e0b660"), "ink": Color("2a2018"), "parchment": Color("d8c8a0"),
	"rope": Color("8a6a40"),
}

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


static func dith(x: int, y: int) -> float:
	return (BAYER[(x & 3) + ((y & 3) << 2)] + 0.5) / 16.0


## Draws a sprite map with its bottom-centre at `feet`. Palette values are Colors or P names.
static func sprite(ci: CanvasItem, rows: Array, pal: Dictionary, feet: Vector2, s: int = 1,
		flip: bool = false, alpha: float = 1.0, outline: bool = true) -> void:
	if outline:
		var edge := {}
		for k in pal:
			edge[k] = P["void"]
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
			var v: Variant = pal[ch]
			var col: Color = v if v is Color else P[v]
			col.a *= alpha
			ci.draw_rect(Rect2(ox + i * s, oy + j * s, s, s), col)


static func text(ci: CanvasItem, at: Vector2, words: String, size: int, col: Color, centred: bool = true,
		shadow: bool = true) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(roundf(at.x - (width / 2.0 if centred else 0.0)), roundf(at.y))
	if shadow:
		ci.draw_string(font, pos + Vector2(0, 0.5), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, col.a * 0.8))
	ci.draw_string(font, pos, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
