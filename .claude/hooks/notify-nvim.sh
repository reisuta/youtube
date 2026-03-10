#!/bin/bash
# ~/.claude/hooks/notify-nvim.sh
NVIM_SOCKET=$(ls /tmp/nvim*.sock 2>/dev/null | head -1)

if [ -n "$NVIM_SOCKET" ]; then
  nvim --server "$NVIM_SOCKET" \
    --remote-expr 'luaeval("vim.notify(\"Claude: 処理完了\", vim.log.levels.INFO)")' \
    2>/dev/null || true
fi
