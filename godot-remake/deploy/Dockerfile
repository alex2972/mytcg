# Dedicated game server (headless Godot running the project's server scene).
# Build from the project root:  docker build -f deploy/Dockerfile -t joey-server .
FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7.1-stable
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 \
 && curl -fsSL -o /tmp/godot.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip" \
 && unzip /tmp/godot.zip -d /opt \
 && mv /opt/Godot_v${GODOT_VERSION}_linux.x86_64 /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm -rf /tmp/godot.zip /var/lib/apt/lists/*

# The server only needs code and data, not art or audio.
WORKDIR /game
COPY project.godot icon.svg ./
COPY autoload ./autoload
COPY core ./core
COPY server ./server
COPY shared ./shared
COPY client ./client
COPY ui ./ui
COPY data ./data

# Import once so class_name scripts are registered.
RUN godot --headless --path /game --import || true

RUN useradd --system --home /data game && mkdir -p /data && chown game /data
USER game
VOLUME /data
EXPOSE 9080
CMD ["godot", "--headless", "--path", "/game", "res://server/server_main.tscn", "--", "--port", "9080", "--data", "/data"]
