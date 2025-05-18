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
center_text "${BOLD}${CYAN}━━━ 【モダンエディタに負けない】作業効率爆上げ！Vim/Neovimの必須基本知識 ━━━${RESET}"
echo

center_text "$(highlight_if_match 0 "0. はじめに-Vimを学ぶ意義")"
center_text "$(highlight_if_match 1 "1. Vimとは何か？")"
center_text "$(highlight_if_match 2 "2. Vim/Neovimのインストール")"
center_text "$(highlight_if_match 3 "3. Vimの基本操作：モードの理解")"
center_text "$(highlight_if_match 4 "4. 基本的なファイル操作")"
center_text "$(highlight_if_match 5 "5. カーソル移動の基本")"
center_text "$(highlight_if_match 6 "6. テキスト編集の基本")"
center_text "$(highlight_if_match 7 "7. よく使うVimコマンド一覧")"
center_text "$(highlight_if_match 8 "8. 今すぐ使える実践的なVimテクニック")"
echo
