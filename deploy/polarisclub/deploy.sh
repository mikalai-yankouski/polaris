#!/usr/bin/env bash
# Deploy Polaris to its own Hoster.by cloud server (polarisclub.by).
# Usage: ./deploy.sh root@NEW_SERVER_IP
set -euo pipefail

REMOTE="${1:-root@NEW_SERVER_IP}"
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
scp "$HERE/.env" "$REMOTE:/opt/polaris/deploy/polarisclub/.env"

ssh "$REMOTE" 'bash -s' <<'REMOTE'
set -euo pipefail
cd /opt/polaris/deploy/polarisclub
docker compose up -d --build
for i in $(seq 1 40); do
  if docker compose exec -T web curl -fsS -H "Host: polarisclub.by" http://127.0.0.1/up >/dev/null; then
    break
  fi
  sleep 3
done
docker compose ps
docker system df
REMOTE
echo "Up. https://polarisclub.by"
