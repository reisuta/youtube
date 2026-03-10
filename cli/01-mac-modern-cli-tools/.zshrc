export EDITOR=nvim

eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"
eval "$(mise activate zsh)"

# 任意
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias cat='bat'
