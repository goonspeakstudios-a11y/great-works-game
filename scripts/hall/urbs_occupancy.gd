extends RefCounted
## The feasibility map of the city of Rome: one byte to every half-metre of ground, saying what
## stands there (nothing, water, the river's bank, the wall, a monument, an open square, a grove,
## a street, a lane, a house, a fountain or a tomb, a tree), painted in the order the city is
## built and read by everything placed after. A lane is laid only where its whole length is
## free, a house only where its whole box is, a basin only on free pavement with a house behind.
## Painting is a native fill of each row's span; a box is read in one copy of its bounding
## rectangle and a native count of each row's span, so the whole city is tested in a second.
##
## Kinds, and what they stop: VOID (off the map, a cleared zone) stops everything; WATER and
## WALL stop everything; BANK (the ground beside the water) and OPEN (a square, a view corridor)
## stop houses and lanes but not what grows; MONUMENT and FURNITURE stop houses, lanes and
## plants; GROVE stops houses only; ROAD and LANE stop houses and plants; HOUSE stops all but
## what its own plot planted; TREE stops the furniture set out after it.

const RES := 0.5  # metres a cell
enum {FREE, WATER, BANK, WALL, MONUMENT, OPEN, GROVE, ROAD, LANE, HOUSE, FURNITURE, TREE, VOID = 255}
const NAMES := {FREE: "free", WATER: "water", BANK: "bank", WALL: "wall", MONUMENT: "monument", OPEN: "open", GROVE: "grove",
	ROAD: "road", LANE: "lane", HOUSE: "house", FURNITURE: "furniture", TREE: "tree", VOID: "void"}
## What a house may not stand on: everything. What a lane may not cross: everything but a grove.
## What a plant may not stand in: the built and the water. What a piece of furniture may not
## stand on: the built, the water, a tree. (Bit sets of the kinds allowed, for the tests.)
const ALLOW_NONE := 0
const ALLOW_LANE := (1 << GROVE)
const ALLOW_PLANT := (1 << BANK) | (1 << OPEN) | (1 << GROVE)
const ALLOW_FURNITURE := (1 << OPEN) | (1 << GROVE) | (1 << BANK)

var x0 := 0.0
var z0 := 0.0
var w := 0
var h := 0
var img: Image


## Lays the map over the ground from `lo` to `hi` (world x and z), all of it VOID.
func setup(lo: Vector2, hi: Vector2, margin: float = 20.0) -> void:
	x0 = lo.x - margin
	z0 = lo.y - margin
	w = int((hi.x - lo.x + 2.0 * margin) / RES) + 1
	h = int((hi.y - lo.y + 2.0 * margin) / RES) + 1
	img = Image.create_empty(w, h, false, Image.FORMAT_L8)
	img.fill(_col(VOID))


static func _col(kind: int) -> Color:
	var v := (float(kind) + 0.5) / 255.0  # half a step up: the byte is truncated, not rounded
	return Color(v, v, v)


func cell(x: float, z: float) -> Vector2i:
	return Vector2i(int(floor((x - x0) / RES)), int(floor((z - z0) / RES)))


## What stands at a point.
func kind_at(p: Vector3) -> int:
	var c := cell(p.x, p.z)
	if c.x < 0 or c.y < 0 or c.x >= w or c.y >= h:
		return VOID
	return img.get_pixel(c.x, c.y).r8


# ---------- painting ----------

## The spans of cells, row by row, inside a convex polygon (its corners in order):
## [[row, first column, last column], ...], clipped to the map.
func _spans(corners: PackedVector2Array) -> Array:
	var zmin := INF
	var zmax := -INF
	for q: Vector2 in corners:
		zmin = minf(zmin, q.y)
		zmax = maxf(zmax, q.y)
	var r0 := maxi(0, int(floor((zmin - z0) / RES)))
	var r1 := mini(h - 1, int(floor((zmax - z0) / RES)))
	var out: Array = []
	var n := corners.size()
	for row in range(r0, r1 + 1):
		var zc := z0 + (row + 0.5) * RES
		var xa := INF
		var xb := -INF
		for i in n:
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % n]
			if (a.y <= zc) == (b.y <= zc):
				continue
			var x := a.x + (b.x - a.x) * (zc - a.y) / (b.y - a.y)
			xa = minf(xa, x)
			xb = maxf(xb, x)
		if xa > xb:
			continue
		var c0 := maxi(0, int(ceil((xa - x0) / RES - 0.5)))
		var c1 := mini(w - 1, int(floor((xb - x0) / RES - 0.5)))
		if c1 >= c0:
			out.append([row, c0, c1])
	return out


static func _box_corners(c: Vector3, b: Basis, bw: float, bd: float, grow: float) -> PackedVector2Array:
	var hx := bw / 2.0 + grow
	var hz := bd / 2.0 + grow
	var out := PackedVector2Array()
	for s: Vector2 in [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]:
		var q := c + b * Vector3(s.x, 0, s.y)
		out.append(Vector2(q.x, q.z))
	return out


static func _band_corners(a: Vector3, b: Vector3, half: float) -> PackedVector2Array:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var length := d.length()
	var dir := d / length if length > 0.001 else Vector2(1, 0)
	var n := Vector2(-dir.y, dir.x) * half
	var e := dir * half  # the band reaches half a width past each end, so the stretches of a line join
	var p0 := Vector2(a.x, a.z) - e
	var p1 := Vector2(b.x, b.z) + e
	return PackedVector2Array([p0 + n, p1 + n, p1 - n, p0 - n])


func _fill(spans: Array, kind: int) -> void:
	var col := _col(kind)
	for s: Array in spans:
		img.fill_rect(Rect2i(s[1], s[0], s[2] - s[1] + 1, 1), col)


## A box on the ground (`bw` across, `bd` deep, turned by `b`), grown by `grow` all round.
func paint_box(c: Vector3, b: Basis, bw: float, bd: float, kind: int, grow: float = 0.0) -> void:
	_fill(_spans(_box_corners(c, b, bw, bd, grow)), kind)


## A stretch from `a` to `b`, `half` wide either side of it.
func paint_band(a: Vector3, b: Vector3, half: float, kind: int) -> void:
	_fill(_spans(_band_corners(a, b, half)), kind)


## A line of points, `half` wide either side.
func paint_line(pts: Array, half: float, kind: int) -> void:
	for i in pts.size() - 1:
		paint_band(pts[i], pts[i + 1], half, kind)


## A disc.
func paint_disc(c: Vector3, r: float, kind: int) -> void:
	var col := _col(kind)
	var r0 := maxi(0, int(floor((c.z - r - z0) / RES)))
	var r1 := mini(h - 1, int(floor((c.z + r - z0) / RES)))
	for row in range(r0, r1 + 1):
		var zc := z0 + (row + 0.5) * RES
		var dz := zc - c.z
		if absf(dz) > r:
			continue
		var half := sqrt(r * r - dz * dz)
		var c0 := maxi(0, int(ceil((c.x - half - x0) / RES - 0.5)))
		var c1 := mini(w - 1, int(floor((c.x + half - x0) / RES - 0.5)))
		if c1 >= c0:
			img.fill_rect(Rect2i(c0, row, c1 - c0 + 1, 1), col)


## A polygon (any shape, its points in order round it), filled even-odd.
func paint_poly(pts: Array, kind: int) -> void:
	var col := _col(kind)
	var zmin := INF
	var zmax := -INF
	for q: Vector3 in pts:
		zmin = minf(zmin, q.z)
		zmax = maxf(zmax, q.z)
	var r0 := maxi(0, int(floor((zmin - z0) / RES)))
	var r1 := mini(h - 1, int(floor((zmax - z0) / RES)))
	var n := pts.size()
	for row in range(r0, r1 + 1):
		var zc := z0 + (row + 0.5) * RES
		var xs: Array = []
		for i in n:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[(i + 1) % n]
			if (a.z <= zc) == (b.z <= zc):
				continue
			xs.append(a.x + (b.x - a.x) * (zc - a.z) / (b.z - a.z))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			var c0 := maxi(0, int(ceil((float(xs[k]) - x0) / RES - 0.5)))
			var c1 := mini(w - 1, int(floor((float(xs[k + 1]) - x0) / RES - 0.5)))
			if c1 >= c0:
				img.fill_rect(Rect2i(c0, row, c1 - c0 + 1, 1), col)


# ---------- reading ----------

## Whether every cell of the spans is free, or of a kind in `allow` (a bit set).
func _clear(spans: Array, allow: int) -> bool:
	if spans.is_empty():
		return true
	var r0: int = spans[0][0]
	var r1: int = spans[-1][0]
	var c0 := w
	var c1 := 0
	for s: Array in spans:
		c0 = mini(c0, s[1])
		c1 = maxi(c1, s[2])
	var rect := Rect2i(c0, r0, c1 - c0 + 1, r1 - r0 + 1)
	var data := img.get_region(rect).get_data()
	if data.count(0) == data.size():
		return true  # the whole rectangle round it is free
	var stride := rect.size.x
	for s: Array in spans:
		var off: int = (int(s[0]) - r0) * stride + (int(s[1]) - c0)
		var seg := data.slice(off, off + int(s[2]) - int(s[1]) + 1)
		if seg.count(0) == seg.size():
			continue
		if allow == 0:
			return false
		for v in seg:
			if v != 0 and (v == VOID or (allow & (1 << v)) == 0):
				return false
	return true


## The kinds standing in the spans, as a bit set (VOID as bit 31).
func _kinds(spans: Array) -> int:
	if spans.is_empty():
		return 0
	var r0: int = spans[0][0]
	var r1: int = spans[-1][0]
	var c0 := w
	var c1 := 0
	for s: Array in spans:
		c0 = mini(c0, s[1])
		c1 = maxi(c1, s[2])
	var rect := Rect2i(c0, r0, c1 - c0 + 1, r1 - r0 + 1)
	var data := img.get_region(rect).get_data()
	var stride := rect.size.x
	var mask := 0
	for s: Array in spans:
		var off: int = (int(s[0]) - r0) * stride + (int(s[1]) - c0)
		for k in range(off, off + int(s[2]) - int(s[1]) + 1):
			var v := data[k]
			if v == VOID:
				mask |= 1 << 31
			elif v != 0:
				mask |= 1 << v
	return mask


func box_free(c: Vector3, b: Basis, bw: float, bd: float, grow: float = 0.0, allow: int = 0) -> bool:
	return _clear(_spans(_box_corners(c, b, bw, bd, grow)), allow)


func band_free(a: Vector3, b: Vector3, half: float, allow: int = 0) -> bool:
	return _clear(_spans(_band_corners(a, b, half)), allow)


func band_kinds(a: Vector3, b: Vector3, half: float) -> int:
	return _kinds(_spans(_band_corners(a, b, half)))


func box_kinds(c: Vector3, b: Basis, bw: float, bd: float) -> int:
	return _kinds(_spans(_box_corners(c, b, bw, bd, 0.0)))


func disc_free(c: Vector3, r: float, allow: int = 0) -> bool:
	var corners := PackedVector2Array()
	for k in 8:  # an octagon round the disc
		var a := TAU * k / 8.0
		corners.append(Vector2(c.x + cos(a) * r * 1.08, c.z + sin(a) * r * 1.08))
	return _clear(_spans(corners), allow)


## How many cells of each kind lie in a box: {kind: cells}. For the audit.
func box_count(c: Vector3, b: Basis, bw: float, bd: float) -> Dictionary:
	var out := {}
	var spans := _spans(_box_corners(c, b, bw, bd, 0.0))
	if spans.is_empty():
		return out
	var r0: int = spans[0][0]
	var r1: int = spans[-1][0]
	var c0 := w
	var c1 := 0
	for s: Array in spans:
		c0 = mini(c0, s[1])
		c1 = maxi(c1, s[2])
	var rect := Rect2i(c0, r0, c1 - c0 + 1, r1 - r0 + 1)
	var data := img.get_region(rect).get_data()
	var stride := rect.size.x
	for s: Array in spans:
		var off: int = (int(s[0]) - r0) * stride + (int(s[1]) - c0)
		for k in range(off, off + int(s[2]) - int(s[1]) + 1):
			var v := data[k]
			out[v] = int(out.get(v, 0)) + 1
	return out


## Saves the map as it is, one grey level a kind (tools/dev_maps.py colours it).
func dump(path: String) -> void:
	img.save_png(path)
