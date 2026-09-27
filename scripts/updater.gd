extends Node
## Keeps the exported game in step with GitHub (autoload "Updater").
## On start: if user://update.pck holds a newer build than the one inside the exe, it is loaded
## over the game's files, before the first scene. Then, in the background, it asks GitHub for
## the latest release (built by .github/workflows/build.yml on every push to main) and, if it is
## newer, downloads its GreatWorks.pck; the new version starts on the next launch.
## The repository is private, so this needs a read-only GitHub token in user://secrets.cfg:
##   [github]
##   token="github_pat_..."
## Without one (or offline, or run from the editor) the game just runs the version it has.

const Version := preload("res://scripts/version.gd")
const REPO := "goonspeakstudios-a11y/great-works-game"
const API := "https://api.github.com/repos/%s" % REPO
const PACK := "user://update.pck"
const PACK_BUILD := "user://update.build"
const PART := "user://update.pck.part"
const ASSET := "GreatWorks.pck"

var status := ""  # shown under the version in the pause menu
var running_build := 0

var _http: HTTPRequest
var _token := ""
var _latest := 0


func _enter_tree() -> void:
	running_build = Version.build()
	if not OS.has_feature("template"):
		return
	var saved := _saved_build()
	if saved > running_build and ProjectSettings.load_resource_pack(PACK, true):
		running_build = saved
		print("updater: running downloaded build %d" % saved)


func _ready() -> void:
	if not OS.has_feature("template"):
		return
	_token = _read_token()
	if _token == "":
		status = "Updates off: no GitHub token"
		return
	_http = HTTPRequest.new()
	_http.max_redirects = 0  # the asset redirects to storage that must not get the token
	_http.timeout = 30.0
	add_child(_http)
	_check()


func _saved_build() -> int:
	if not FileAccess.file_exists(PACK):
		return 0
	var f := FileAccess.open(PACK_BUILD, FileAccess.READ)
	return int(f.get_as_text().strip_edges()) if f else 0


func _read_token() -> String:
	var cfg := ConfigFile.new()
	if cfg.load("user://secrets.cfg") != OK:
		return ""
	return str(cfg.get_value("github", "token", "")).strip_edges()


func _headers(accept: String) -> PackedStringArray:
	return PackedStringArray(["Authorization: Bearer " + _token, "Accept: " + accept,
		"User-Agent: great-works-updater", "X-GitHub-Api-Version: 2022-11-28"])


## Waits for one request; returns [result, code, headers, body].
func _fetch(url: String, headers: PackedStringArray, to_file := "") -> Array:
	_http.download_file = to_file
	if _http.request(url, headers) != OK:
		return [HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray()]
	return await _http.request_completed


func _check() -> void:
	status = "Checking for updates..."
	var r: Array = await _fetch(API + "/releases/latest", _headers("application/vnd.github+json"))
	if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
		status = "Update check failed (%s)" % ("offline" if r[0] != HTTPRequest.RESULT_SUCCESS else "HTTP %d" % r[1])
		push_warning("updater: " + status)
		return
	var release = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	if typeof(release) != TYPE_DICTIONARY:
		status = "Update check failed (bad reply)"
		return
	_latest = int(str(release.get("tag_name", "")).trim_prefix("build-"))
	if _latest <= running_build:
		status = "Up to date"
		return
	if _latest == _saved_build():
		status = "Build %d downloaded: restart to play it" % _latest
		return
	for a in release.get("assets", []):
		if a.get("name", "") == ASSET:
			await _download(int(a["id"]))
			return
	status = "Build %d has no %s yet" % [_latest, ASSET]


func _download(asset_id: int) -> void:
	status = "Downloading build %d..." % _latest
	var r: Array = await _fetch(API + "/releases/assets/%d" % asset_id, _headers("application/octet-stream"))
	var url := ""
	for h in r[2]:
		if h.to_lower().begins_with("location:"):
			url = h.substr(9).strip_edges()
	if url == "":
		status = "Download failed (HTTP %d)" % r[1]
		return
	_http.max_redirects = 4
	r = await _fetch(url, PackedStringArray(["User-Agent: great-works-updater"]), PART)
	_http.max_redirects = 0
	if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
		status = "Download failed (HTTP %d)" % r[1]
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PART))
		return
	var dir := DirAccess.open("user://")
	dir.remove("update.pck")
	if dir.rename("update.pck.part", "update.pck") != OK:
		status = "Download failed (could not save)"
		return
	var f := FileAccess.open(PACK_BUILD, FileAccess.WRITE)
	f.store_string(str(_latest))
	f.close()
	status = "Build %d downloaded: restart to play it" % _latest
	print("updater: " + status)
