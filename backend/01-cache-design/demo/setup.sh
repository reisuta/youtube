#!/usr/bin/env bash
# 動画の実演を再現するための使い捨てコンテナを起動する。
#   bash demo/setup.sh build   イメージ cache-demo を作る（初回のみ）
#   bash demo/setup.sh run     コンテナを起動して bash に入る（app :3000、nginx :8080、redis）
# ホストのファイルには触れない。コンテナは終了時に消える。
# 必要なもの: docker
set -euo pipefail
cd "$(dirname "$0")"
IMG=cache-demo
case "${1:-run}" in
  build) docker build -q -t "$IMG" . >/dev/null ;;
  run)
    docker image inspect "$IMG" >/dev/null 2>&1 || docker build -q -t "$IMG" . >/dev/null
    exec docker run -it --rm --hostname demo "$IMG"
    ;;
  *) echo "usage: $0 build | run" >&2; exit 1 ;;
esac
