# Tenka shell flavour
command -v starship >/dev/null && eval "$(starship init bash)"
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -l --icons=auto --git --group-directories-first'
alias la='eza -la --icons=auto --group-directories-first'
alias ff='fastfetch'
[ -z "$TENKA_GREETED" ] && [ -n "$KITTY_PID" ] && export TENKA_GREETED=1 && fastfetch
