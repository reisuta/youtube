#!/bin/bash

HIGHLIGHT=${1:-0}

TERM_WIDTH=$(tput cols)

center_text() {
  local text="$1"
  local text_length=${#text}
  local text_without_color=$(echo -e "$text" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | sed -r "s/\x1B\[(38|48);5;[0-9]+m//g")
  local actual_length=${#text_without_color}
  local padding=$(( (TERM_WIDTH - actual_length) / 2 ))
  echo -e "$(printf "%${padding}s" "")$text"
}

BOLD="\033[1m"
CYAN="\033[1;36m"
DARK_RED="\033[38;5;160m"
BRIGHT_WHITE_BG="\033[48;5;231m"
GRAY="\033[2;37m"
RESET="\033[0m"

highlight_if_match() {
  local index=$1
  local text=$2

  if [ "$index" == "$HIGHLIGHT" ]; then
    echo "${BOLD}${BRIGHT_WHITE_BG}${DARK_RED}${text}${RESET}"
  else
    echo "${BOLD}${GRAY}${text}${RESET}"
  fi
}

echo
center_text "${BOLD}${CYAN}━━━ curl で叩ける便利サイト10選 ━━━${RESET}"
echo

center_text "- $(highlight_if_match 0 "curl とは")"
center_text "- $(highlight_if_match 1 "curl の基本的な使い方とオプション")"
echo

echo
center_text "$(highlight_if_match 2 "1. wttr.in - 天気予報")"
center_text "$(highlight_if_match 3 "2. httpbin.org - HTTPリクエストのテスト")"
center_text "$(highlight_if_match 4 "3. ifconfig.io - グローバルIPアドレス確認")"
center_text "$(highlight_if_match 5 "4. cheat.sh - コマンドのチートシート")"
center_text "$(highlight_if_match 6 "5. qrenco.de - QRコード生成")"
center_text "$(highlight_if_match 7 "6. rate.sx - 暗号通貨のレート確認")"
center_text "$(highlight_if_match 8 "7. passwordrandom.comとopensslコマンド - パスワード生成")"
center_text "$(highlight_if_match 9 "8. official-joke-api - ジョークAPI")"
center_text "$(highlight_if_match 10 "9. hastebin.comとGitHub Gist - テキスト共有サービス")"
center_text "$(highlight_if_match 11 "10. networkcalc.comとbcコマンド - 数値変換")"
echo
