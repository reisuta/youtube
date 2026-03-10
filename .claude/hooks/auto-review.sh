#!/bin/bash
# ~/.claude/hooks/auto-review.sh

# stdin からファイルパスを取得
FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

ERRORS=""

# ESLint チェック（TS/JS）
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    RESULT=$(npx eslint "$FILE_PATH" 2>&1 || true)
    if echo "$RESULT" | grep -qE "error"; then
      ERRORS="${ERRORS}\n[ESLint]\n${RESULT}"
    fi
    ;;
esac

# Python の場合
case "$FILE_PATH" in
  *.py)
    RESULT=$(ruff check "$FILE_PATH" 2>&1 || true)
    if [ -n "$RESULT" ]; then
      ERRORS="${ERRORS}\n[Ruff]\n${RESULT}"
    fi
    ;;
esac

if [ -n "$ERRORS" ]; then
  printf "以下の問題が検出されました。修正してください:%b" "$ERRORS" >&2
  exit 2
fi

exit 0
