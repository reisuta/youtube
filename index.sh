#!/bin/bash

# 端末の幅を取得
TERM_WIDTH=$(tput cols)

# 中央揃えの関数
center_text() {
  local text="$1"
  local text_length=${#text}
  local text_without_color=$(echo -e "$text" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")
  local actual_length=${#text_without_color}
  local padding=$(( (TERM_WIDTH - actual_length) / 2 ))
  echo -e "$(printf "%${padding}s" "")$text"
}

BOLD="\033[1m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RESET="\033[0m"

# 各セクション
echo
center_text "${BOLD}${CYAN}curl で叩ける便利サイト10選${RESET}"
# center_text "${BOLD}${CYAN}イントロダクション${RESET}"
center_text "- ${YELLOW}curl とは${RESET}"
center_text "- ${YELLOW}curl の基本的な使い方とオプション${RESET}"
echo
# center_text "${BOLD}${CYAN}便利サイト10選${RESET}"
echo
center_text "${GREEN}1. wttr.in${RESET} - 天気予報"
center_text "${GREEN}2. httpbin.org${RESET} - HTTPリクエストのテスト"
center_text "${GREEN}3. ifconfig.io${RESET} - グローバルIPアドレス確認"
center_text "${GREEN}4. cheat.sh${RESET} - コマンドのチートシート"
center_text "${GREEN}5. qrenco.de${RESET} - QRコード生成"
center_text "${GREEN}6. rate.sx${RESET} - 暗号通貨のレート確認"
center_text "${GREEN}7. passwordrandom.comとopensslコマンド${RESET} - パスワード生成"
center_text "${GREEN}8. official-joke-api${RESET} - ジョークAPI"
center_text "${GREEN}9. hastebin.comとGitHub Gist${RESET} - テキスト共有サービス"
center_text "${GREEN}10. networkcalc.comとbcコマンド${RESET} - 数値変換"
echo
