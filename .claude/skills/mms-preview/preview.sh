#!/usr/bin/env bash
# Local preview of a site, with nothing left behind.
#
#   preview.sh start [repo]   serve the site, print the URL
#   preview.sh status [repo]  show what is running for this repo
#   preview.sh stop [repo]    stop it and remove everything it created
#   preview.sh stop --all     also remove the cached gems volume (next start is slow again)
#
# Jekyll sites (a _config.yml) run in Docker. The repo is mounted read-only and the build goes to
# a tmpfs, so the preview cannot change a file in the repo, and the container is removed on stop.
# Other folders are served as static files with python3 -m http.server.
set -euo pipefail

IMAGE="jekyll/jekyll:4"
GEMS_VOLUME="claude-preview-gems"
MAX_SECONDS=$((4 * 3600))   # a forgotten preview stops itself after this
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/claude-preview"

cmd="${1:-status}"; shift || true
all=false
if [ "${1:-}" = "--all" ]; then all=true; shift; fi
repo="$(cd "${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" && pwd)"
key="$(printf '%s' "$repo" | sha1sum | cut -c1-12)"
label="claude-preview.repo=$repo"
name="claude-preview-$key"
pidfile="$STATE_DIR/$key.pid"
mkdir -p "$STATE_DIR"

free_port() {  # first free TCP port at or above $1
  python3 - "$1" <<'EOF'
import socket, sys
p = int(sys.argv[1])
while True:
    with socket.socket() as s:
        try:
            s.bind(("127.0.0.1", p)); print(p); break
        except OSError:
            p += 1
EOF
}

wait_ready() {  # $1 url, $2 seconds
  local i
  for ((i = 0; i < $2; i += 2)); do
    if curl -fsS -o /dev/null "$1" 2>/dev/null; then return 0; fi
    if [ -n "${3:-}" ] && ! docker ps -q --filter "name=^$3$" | grep -q .; then return 1; fi
    sleep 2
  done
  return 1
}

running_port() {
  if docker ps -q --filter "label=$label" | grep -q .; then
    docker inspect "$name" --format '{{index .Config.Labels "claude-preview.port"}}'
  elif [ -f "$pidfile" ] && kill -0 "$(cut -d' ' -f1 "$pidfile")" 2>/dev/null; then
    cut -d' ' -f2 "$pidfile"
  fi
}

start() {
  local port
  port="$(running_port || true)"
  if [ -n "$port" ]; then echo "already running: http://127.0.0.1:$port/"; return 0; fi

  if [ -f "$repo/_config.yml" ]; then
    local lr
    port="$(free_port 4000)"
    lr="$(free_port 35729)"
    # Ruby 3.4 in the image no longer bundles these gems; add them to a copy of the Gemfile
    # so the repo's Gemfile and Gemfile.lock stay untouched.
    docker run -d --rm --name "$name" \
      --label "$label" --label "claude-preview.port=$port" \
      -p "127.0.0.1:$port:4000" -p "127.0.0.1:$lr:$lr" \
      -v "$repo:/srv/jekyll:ro" \
      -v "$GEMS_VOLUME:/usr/local/bundle" \
      --tmpfs /out --tmpfs /tmp/gf \
      --entrypoint sh "$IMAGE" -c "
        cp /srv/jekyll/Gemfile /tmp/gf/Gemfile &&
        printf '\ngem \"csv\"\ngem \"logger\"\ngem \"base64\"\ngem \"bigdecimal\"\n' >> /tmp/gf/Gemfile &&
        export BUNDLE_GEMFILE=/tmp/gf/Gemfile &&
        bundle install --quiet &&
        cd /srv/jekyll &&
        exec timeout $MAX_SECONDS bundle exec jekyll serve -s /srv/jekyll -d /out \
          --disable-disk-cache --host 0.0.0.0 --watch --force_polling \
          --livereload --livereload-port $lr --drafts --future" >/dev/null
    echo "starting Jekyll in container $name (first run installs gems, can take a few minutes)..."
    if ! wait_ready "http://127.0.0.1:$port/" 600 "$name"; then
      echo "Jekyll did not come up. Last log lines:" >&2
      docker logs --tail 30 "$name" 2>&1 >&2 || true
      docker rm -f "$name" >/dev/null 2>&1 || true
      exit 1
    fi
  else
    port="$(free_port 8000)"
    (cd "$repo" && exec setsid timeout "$MAX_SECONDS" python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1) &
    echo "$! $port" > "$pidfile"
    wait_ready "http://127.0.0.1:$port/" 20 || { echo "static server did not come up" >&2; exit 1; }
  fi
  echo "ready: http://127.0.0.1:$port/"
}

status() {
  local port
  port="$(running_port || true)"
  if [ -n "$port" ]; then echo "running: http://127.0.0.1:$port/"; else echo "not running for $repo"; fi
}

stop() {
  local port ids
  port="$(running_port || true)"
  ids="$(docker ps -aq --filter "label=$label")"
  if [ -n "$ids" ]; then docker rm -f $ids >/dev/null; echo "removed container(s): $ids" | tr '\n' ' '; echo; fi
  if [ -f "$pidfile" ]; then
    kill -- "-$(cut -d' ' -f1 "$pidfile")" 2>/dev/null || kill "$(cut -d' ' -f1 "$pidfile")" 2>/dev/null || true
    rm -f "$pidfile"; echo "stopped static server"
  fi
  if $all && docker volume inspect "$GEMS_VOLUME" >/dev/null 2>&1; then
    docker volume rm "$GEMS_VOLUME" >/dev/null && echo "removed volume $GEMS_VOLUME"
  fi
  # verify
  local left=0
  if docker ps -aq --filter "label=$label" | grep -q .; then echo "LEFT: container still present" >&2; left=1; fi
  if [ -n "$port" ] && curl -fsS -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null; then
    echo "LEFT: something still answers on port $port" >&2; left=1
  fi
  [ $left -eq 0 ] && echo "clean: nothing left running for $repo"
  return $left
}

case "$cmd" in
  start) start ;; status) status ;; stop) stop ;;
  *) echo "usage: $0 start|status|stop [--all] [repo]" >&2; exit 2 ;;
esac
