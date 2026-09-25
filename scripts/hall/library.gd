extends RefCounted
## A book split into short passages (built by tools/build_corpus.py), with a small
## keyword search (BM25) that finds the passages matching a question.

const DIR := "res://content/books"
const K1 := 1.4
const B := 0.75
const STOP := ["the", "and", "that", "this", "with", "what", "which", "from", "have", "for", "are", "was",
	"but", "not", "you", "your", "they", "their", "them", "there", "then", "than", "into", "also", "such",
	"its", "his", "her", "him", "our", "who", "whom", "why", "how", "when", "where", "can", "could",
	"would", "should", "will", "does", "did", "doe", "been", "being", "were", "any", "all", "some", "one",
	"about", "tell", "say", "said", "mean", "means", "thing", "things", "book", "is", "a", "an", "of",
	"to", "in", "it", "as", "be", "by", "or", "on", "at", "so", "if", "no", "me", "my", "we", "do",
	"hello", "there", "please", "wouldn", "didn", "don", "isn", "answer"]

var work := ""
var title := ""
var translation := ""
var chunks: Array = []
var _counts: Array = []  # per passage: word -> count
var _lengths: Array = []
var _df := {}
var _avg := 1.0


static func load_book(work_id: String) -> RefCounted:
	var path := "%s/%s.json" % [DIR, work_id]
	if not FileAccess.file_exists(path):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		push_error("Bad book file %s" % path)
		return null
	var book: RefCounted = load("res://scripts/hall/library.gd").new()
	book.work = work_id
	book.title = data["title"]
	book.translation = data.get("translation", "")
	book.chunks = data["chunks"]
	book._index()
	return book


static func words(text: String) -> Array:
	var out: Array = []
	for m in RegEx.create_from_string("[a-z]+").search_all(text.to_lower()):
		var w := m.get_string()
		if w.length() < 3 or w in STOP:
			continue
		if w.length() > 4 and w.ends_with("s") and not w.ends_with("ss"):
			w = w.left(w.length() - 1)  # a crude plural fold: accidents -> accident
		out.append(w)
	return out


func _index() -> void:
	var total := 0
	for c in chunks:
		var counts := {}
		var ws := words(c["text"])
		for w in ws:
			counts[w] = counts.get(w, 0) + 1
		for w in counts:
			_df[w] = _df.get(w, 0) + 1
		_counts.append(counts)
		_lengths.append(ws.size())
		total += ws.size()
	_avg = maxf(1.0, float(total) / maxi(1, chunks.size()))


## The k passages that best match the question; the opening passages if nothing matches.
func search(question: String, k: int) -> Array:
	var q := words(question)
	var scored: Array = []
	var n := chunks.size()
	for i in n:
		var s := 0.0
		for w in q:
			var tf: int = _counts[i].get(w, 0)
			if tf == 0:
				continue
			var idf := log(1.0 + (n - _df[w] + 0.5) / (_df[w] + 0.5))
			s += idf * tf * (K1 + 1.0) / (tf + K1 * (1.0 - B + B * _lengths[i] / _avg))
		scored.append([s, i])
	scored.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array = []
	if scored.is_empty() or scored[0][0] <= 0.0:
		for i in mini(k, n):
			out.append(chunks[i])
		return out
	for pair in scored.slice(0, k):
		out.append(chunks[pair[1]])
	return out


func random_passage() -> Dictionary:
	return chunks[randi() % chunks.size()]
