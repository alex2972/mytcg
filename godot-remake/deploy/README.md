# Deploying the game server

The server is the same Godot project started headless with `res://server/server_main.tscn`.
It stores everything under its data folder: `accounts/` (profiles, collections, decks, purchases),
`matches/` (one JSON line per duel), `logs/` (server.log, audit.log), `backups/` (daily, newest 7) and `config.json`
(written with defaults on first start; edit and restart to tune timers, ratings, rewards and limits).

## Option A: Docker + Caddy (recommended)
1. Install Docker with the compose plugin on a Linux machine with a public IP.
2. Point a DNS name at it and write that name in `deploy/Caddyfile`.
3. From the project root: `docker compose -f deploy/docker-compose.yml up -d --build`
4. Players use the server address `wss://<your name>` in the game's Online screen.
Data lives in the `game-data` volume; back it up with `docker run --rm -v deploy_game-data:/d -v $PWD:/b debian tar czf /b/game-data.tgz -C /d .`

## Option B: run Godot directly
```
godot --headless --path . res://server/server_main.tscn -- --port 9080 --data /srv/joey-data
```
For wss:// without a proxy add `--tls-cert fullchain.pem --tls-key privkey.pem` (PEM files, e.g. from Let's Encrypt).
Plain `ws://` is fine on a LAN; browsers on https pages need `wss://`.

## Options
- `--port` (default 9080), `--data` (default user://server_dev), `--dev` (enables `dev_start_bot_duel`; keep it off in production),
  `--tls-cert` / `--tls-key`.
- Stop with Ctrl+C / `docker compose stop`: running duels end as a no-contest (no rating change), queues are cancelled.

## Checks
- `server_status` request (uptime, peers, rooms, queues, accounts) is answered to any client after hello.
- Metrics are logged every 60 s; logins, purchases and ranked results go to `logs/audit.log`.
- Clients with different card/rules data are refused at hello (`outdated_client`): deploy the same data to server and clients.

Not verified in this environment: building the image and running Docker (no Docker here). The headless server itself is
tested by `tests/online/*` and `tools/online/soak.gd`.
