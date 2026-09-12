#!/usr/bin/env bash
# ENTRYPOINT: redis、nginx、app を起動してから bash を開く。
set -e
redis-server --daemonize yes --loglevel warning >/dev/null
nginx
node /srv/app.js > /tmp/app.log 2>&1 &
sleep 0.5
cd /srv
exec bash "$@"
