extends SceneTree
## Phase 2: register / login / token / logout, names and passwords, one session per account, persistence.
var fails := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var audio := root.get_node_or_null("Audio")
	if audio != null:
		audio.queue_free()
	var h := OnlineHarness.new()
	check(h.start(self, "auth"), "server listens")
	var a: OnlineClient = await h.client("a")
	# Before login: account requests refused.
	var anon: Dictionary = await a.request("account_summary")
	check(anon.get("error", "") == "not_authenticated", "account requests need a login")
	# Names
	for bad in ["ab", "x".repeat(17), " Joey", "Joey ", "Jo!ey", "admin", "a  b", ""]:
		var r: Dictionary = await a.request("register", {"name": bad, "password": ""})
		check(r.get("error", "") == "bad_name", "name '%s' is refused" % bad)
	var r_type: Dictionary = await a.request("register", {"name": 42, "password": ""})
	check(r_type.get("error", "") == "bad_name", "a non-string name is refused")
	var r_pw: Dictionary = await a.request("register", {"name": "Longpass", "password": "x".repeat(65)})
	check(r_pw.get("error", "") == "bad_password", "an over-long password is refused")
	# Register with an empty password, then the starter state.
	var reg: Dictionary = await a.request("register", {"name": "Joey", "password": ""})
	check(reg.get("ok", false) and str(reg.get("token", "")).length() == 64, "register with an empty password logs in and returns a token")
	var acc: Dictionary = reg.get("account", {})
	check(acc.get("name", "") == "Joey" and int(acc.get("dp", 0)) == 2450 and int(acc.get("rating", 0)) == 1500, "a new account has starting DP and rating 1500")
	var dup: Dictionary = await a.request("register", {"name": "joey", "password": ""})
	check(dup.get("error", "") == "name_taken", "names are unique ignoring case")
	var summary: Dictionary = await a.request("account_summary")
	check(summary.get("ok", false) and summary["account"]["name"] == "Joey", "account_summary works after login")
	var out: Dictionary = await a.request("logout")
	check(out.get("ok", false), "logout")
	var after: Dictionary = await a.request("account_summary")
	check(after.get("error", "") == "not_authenticated", "logged out sessions are anonymous")
	var back: Dictionary = await a.request("login", {"name": "JOEY", "password": ""})
	check(back.get("ok", false) and back["account"]["id"] == acc["id"], "login is case-insensitive on the name")
	# Password accounts
	var b: OnlineClient = await h.client("b")
	var reg2: Dictionary = await b.request("register", {"name": "Kaiba", "password": "blue eyes"})
	check(reg2.get("ok", false), "register with a password")
	var stored: Dictionary = h.server.services["auth"].store.profile(reg2["account"]["id"])
	check(stored.get("pw") is Dictionary and not JSON.stringify(stored).contains("blue eyes"), "the password is stored hashed, never in clear")
	await b.request("logout")
	var wrong: Dictionary = await b.request("login", {"name": "Kaiba", "password": "red eyes"})
	check(wrong.get("error", "") == "bad_credentials", "a wrong password is refused")
	var too_soon: Dictionary = await b.request("login", {"name": "Kaiba", "password": "blue eyes"})
	check(too_soon.get("error", "") == "rate_limited", "after a failure the next attempt must wait")
	h.server.clock_offset += 5.0
	var right: Dictionary = await b.request("login", {"name": "Kaiba", "password": "blue eyes"})
	check(right.get("ok", false), "the right password works after the delay")
	var empty: Dictionary = await b.request("login", {"name": "Kaiba", "password": ""})
	check(not empty.get("ok", false), "an account with a password cannot log in without it")
	var nobody: Dictionary = await b.request("login", {"name": "Nobody", "password": ""})
	check(nobody.get("error", "") == "bad_credentials", "unknown accounts are bad credentials")
	# One session per account: a second login kicks the first.
	var c: OnlineClient = await h.client("c")
	var second: Dictionary = await c.request("login", {"name": "Joey", "password": ""})
	check(second.get("ok", false), "second login of the same account succeeds")
	check(await h.wait_until(func(): return a.state == "offline", 3.0), "the first session of that account is kicked")
	# Token login (single use)
	var token: String = second["token"]
	var d: OnlineClient = await h.client("d")
	var tk: Dictionary = await d.request("login_token", {"token": token})
	check(tk.get("ok", false) and tk["account"]["name"] == "Joey" and tk["token"] != token, "token login works and returns a fresh token")
	var reuse: Dictionary = await d.request("login_token", {"token": token})
	check(reuse.get("error", "") == "bad_credentials", "a token cannot be used twice")
	# Persistence: a new server process on the same data folder knows the accounts.
	var dir := h.data_dir
	h.server.stop()
	h.server.queue_free()
	await process_frame
	var s2 := GameServer.new()
	s2.name = "Server_auth_restart"
	root.add_child(s2)
	s2.setup(dir, {"pbkdf2_iterations": 200})
	h.port = OnlineHarness.free_port()
	h.url = "ws://127.0.0.1:%d" % h.port
	s2.listen(h.port)
	h.server = s2
	var e: OnlineClient = await h.client("e")
	var again: Dictionary = await e.request("login", {"name": "Kaiba", "password": "blue eyes"})
	check(again.get("ok", false) and int(again["account"]["dp"]) == 2450, "accounts survive a server restart")
	# Client Session flow (throwaway local root and settings file).
	var session := root.get_node("Session")
	session.use_root("user://test_online_auth_local")
	session.online_cfg_path = "user://test_online_auth_local/online.cfg"
	var go: Dictionary = await session.go_online(h.url, "Yugi", "", true)
	check(go.get("ok", false) and session.is_online() and session.display_name() == "Yugi", "Session registers and goes online")
	check(session.backend is RemoteShopBackend, "online mode uses the remote backend")
	var saved: Dictionary = session.last_online_settings()
	check(saved.get("name", "") == "Yugi" and str(saved.get("token", "")) != "", "the token is remembered for the next start")
	session.online.close()
	await process_frame
	var resumed: Dictionary = await session.resume_online()
	check(resumed.get("ok", false) and session.display_name() == "Yugi", "the saved token logs back in after a disconnect")
	await session.logout()
	check(not session.is_online() and session.backend is LocalShopBackend and str(session.last_online_settings().get("token", "x")) == "", "logout returns to offline and forgets the token")
	await h.stop()
	OnlineHarness.wipe("user://test_online_auth_local")
	print("online auth tests: ", "OK" if fails == 0 else "%d FAILED" % fails)
	quit(1 if fails else 0)
