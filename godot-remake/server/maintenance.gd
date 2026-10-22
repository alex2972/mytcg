class_name ServerMaintenance
extends RefCounted
## Startup checks and backups of the server data.
##   - at startup every account file is validated; damaged files are moved aside (".corrupt-<time>") and the
##     account index is rebuilt from the folders if accounts are missing from it;
##   - once per day (UTC, at startup and while running) <data>/accounts is copied to <data>/backups/<date>/,
##     keeping the newest `backup_keep` copies.

var server: GameServer
var store: AccountStore
var last_backup_day := ""
var report := {}

func _init(game_server: GameServer, account_store: AccountStore) -> void:
	server = game_server
	store = account_store
	report = store.validate()
	if not (report["quarantined"] as Array).is_empty() or int(report["reindexed"]) > 0:
		server.log_line("WARN", "account check: %d accounts, moved aside %s, re-indexed %d" % [report["accounts"], str(report["quarantined"]), report["reindexed"]])
	else:
		server.log_line("INFO", "account check: %d accounts OK" % int(report["accounts"]))
	backup_if_due(server.now())

func status() -> Dictionary:
	return {"last_backup": last_backup_day}

func tick(t: float) -> void:
	backup_if_due(t)

func backup_if_due(t: float) -> void:
	var day := Time.get_date_string_from_unix_time(int(t))
	if day == last_backup_day:
		return
	last_backup_day = day
	var target := server.data_dir + "/backups/" + day
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target)):
		return
	var copied := copy_tree(server.data_dir + "/accounts", target + "/accounts")
	server.log_line("INFO", "backup %s: %d files" % [day, copied])
	prune(int(server.config["backup_keep"]))

## Copies a folder recursively; returns the number of files copied.
static func copy_tree(from: String, to: String) -> int:
	var src := ProjectSettings.globalize_path(from)
	var dst := ProjectSettings.globalize_path(to)
	DirAccess.make_dir_recursive_absolute(dst)
	var n := 0
	for f in DirAccess.get_files_at(src):
		if f.ends_with(".tmp"):
			continue
		if DirAccess.copy_absolute(src + "/" + f, dst + "/" + f) == OK:
			n += 1
	for d in DirAccess.get_directories_at(src):
		n += copy_tree(from + "/" + d, to + "/" + d)
	return n

func prune(keep: int) -> void:
	var root := ProjectSettings.globalize_path(server.data_dir + "/backups")
	var days := DirAccess.get_directories_at(root)
	days.sort()
	while days.size() > keep:
		remove_tree(server.data_dir + "/backups/" + days[0])
		days.remove_at(0)

static func remove_tree(dir: String) -> void:
	var path := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		remove_tree(dir + "/" + sub)
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + "/" + f)
	DirAccess.remove_absolute(path)
