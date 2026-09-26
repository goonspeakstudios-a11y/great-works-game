extends RefCounted
## The game's own lettering, cut by tools/make_font.py from hand-drawn glyphs: Lapidary
## (Roman inscription capitals) for names, titles and signs; Scribe (a small serif hand)
## for everything you read. Every word on screen wears one of the two; the engine's
## default face never shows.

const LAPIDARY: Font = preload("res://assets/fonts/lapidary.fnt")
const SCRIBE: Font = preload("res://assets/fonts/scribe.fnt")
const TITLE := 14  # Lapidary's cut size; text must ask for exactly this size to stay crisp
const BODY := 13   # Scribe's


## The theme for the interface root: the scribe's hand everywhere unless a label asks
## for capitals. RichTextLabel keeps its own bold and italic slots, which would fall
## back to the engine's face, so they are pointed at Scribe too.
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = SCRIBE
	t.default_font_size = BODY
	for item in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
		t.set_font(item, "RichTextLabel", SCRIBE)
		t.set_font_size(item + "_size", "RichTextLabel", BODY)
	return t


## Cuts a label in capitals.
static func capitals(l: Control) -> void:
	l.add_theme_font_override("font", LAPIDARY)
	l.add_theme_font_size_override("font_size", TITLE)


static func width(text: String, capitals_face: bool = false) -> float:
	var f := LAPIDARY if capitals_face else SCRIBE
	return f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE if capitals_face else BODY).x
