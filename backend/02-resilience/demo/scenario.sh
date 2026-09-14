#!/usr/bin/env bash
# ENTRYPOINT: 上流 API を起動してから bash を開く
set -e
node /srv/upstream.js > /tmp/upstream.log 2>&1 &
sleep 0.5
cd /srv
exec bash "$@"
