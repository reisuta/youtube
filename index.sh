#!/bin/bash
highlight=${1:-0}
term_width=$(tput cols)
center_text() {
  local text="$1"
  local text_length=${#text}
  local text_without_color=$(echo -e "$text" | sed -r "s/\x1b\[([0-9]{1,2}(;[0-9]{1,2})?)?[mgk]//g" | sed -r "s/\x1b\[(38|48);5;[0-9]+m//g")
  local actual_length=${#text_without_color}
  local padding=$(( (term_width - actual_length) / 2 ))
  echo -e "$(printf "%${padding}s" "")$text"
}
bold="\033[1m"
cyan="\033[1;36m"
dark_red="\033[38;5;160m"
bright_white_bg="\033[48;5;231m"
gray="\033[2;37m"
reset="\033[0m"
highlight_if_match() {
  local index=$1
  local text=$2
  if [ "$index" == "$highlight" ]; then
    echo "${bold}${bright_white_bg}${dark_red}${text}${reset}"
  else
    echo "${bold}${gray}${text}${reset}"
  fi
}
echo
center_text "${bold}${cyan}━━━ 【作業効率爆上げ】vim設定ファイル(.vimrc)の作り方 ━━━${reset}"
center_text "${bold}${cyan} -set/map/leader/autocmdを解説- ${reset}"
echo
center_text "$(highlight_if_match 0 "1.「自分だけのvimを作る理由」〜カスタマイズでvimの力を引き出す〜")"
center_text "$(highlight_if_match 1 "2. 設定ファイルの作成")"
center_text "$(highlight_if_match 2 "3. setコマンドと設定しておきたいオプションについて")"
center_text "$(highlight_if_match 3 "4. キーボードショートカットを無限に増やすleaderキー活用法〜")"
center_text "$(highlight_if_match 4 "5.【map/noremap】〜マッピングでキー操作を自在にカスタマイズ〜")"
center_text "$(highlight_if_match 5 "6.「ユーザー定義コマンドで作業を自動化」〜頻繁な操作をコマンド一発で〜")"
center_text "$(highlight_if_match 6 "7.【autocmd】〜ファイルに応じて自動で最適な環境に切り替わる仕組み〜")"
center_text "$(highlight_if_match 7 "8. .vimrcのテンプレート 〜 設定ファイル例")"
center_text "$(highlight_if_match 8 "9. 終わりに")"
echo
