#!/usr/bin/env bash
# Copy this app to the VPS next to coffee-pulse.by / metehi.by and start it.
# Usage: ./deploy.sh root@VPS_IP
set -euo pipefail

REMOTE="${1:-root@87.232.65.174}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$HERE/.env" ]]; then
  echo "Create $HERE/.env first (from env.example)." >&2
  exit 1
fi
if [[ ! -f "$ROOT/config/master.key" ]]; then
  echo "Missing $ROOT/config/master.key" >&2
  exit 1
fi

ssh -o StrictHostKeyChecking=accept-new "$REMOTE" 'mkdir -p /opt/polaris /opt/polaris/storage && chown -R 1000:1000 /opt/polaris/storage'
rsync -az --delete \
  --exclude .git --exclude tmp --exclude log --exclude storage \
  --exclude node_modules --exclude .kamal \
  "$ROOT/" "$REMOTE:/opt/polaris/"
scp "$HERE/.env" "$REMOTE:/opt/polaris/deploy/hoster/.env"

ssh "$REMOTE" 'bash -s' <<'REMOTE'
set -euo pipefail
cd /opt/polaris/deploy/hoster
docker compose up -d --build
for i in $(seq 1 40); do
  if docker compose exec -T web curl -fsS -H "Host: 87.232.65.174" http://127.0.0.1/up >/dev/null; then
    break
  fi
  sleep 3
done
docker compose exec -T web bin/rails db:seed
docker compose ps
docker system df
REMOTE
echo "Up. Open http://87.232.65.174 (until the domain is pointed here)."
