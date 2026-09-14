#!/usr/bin/env bash
# 動画の実演を再現するための使い捨てコンテナを起動する。
#   bash demo/setup.sh build   イメージ resilience-demo を作る（初回のみ）
#   bash demo/setup.sh run     コンテナを起動して bash に入る（上流 API :4000）
# ホストのファイルには触れない。コンテナは終了時に消える。
set -euo pipefail
cd "$(dirname "$0")"
IMG=resilience-demo
case "${1:-run}" in
  build) docker build -q -t "$IMG" . >/dev/null ;;
  run)
    docker image inspect "$IMG" >/dev/null 2>&1 || docker build -q -t "$IMG" . >/dev/null
    exec docker run -it --rm --hostname demo --ulimit nofile=1024:1024 "$IMG"
    ;;
  *) echo "usage: $0 build | run" >&2; exit 1 ;;
esac
