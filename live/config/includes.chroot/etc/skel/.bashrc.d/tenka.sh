# Tenka shell flavour
command -v starship >/dev/null && eval "$(starship init bash)"
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -l --icons=auto --git --group-directories-first'
alias la='eza -la --icons=auto --group-directories-first'
alias ff='fastfetch'
# in kitty the crest is drawn as an image (kitty graphics); elsewhere the ink-text crest
[ -n "$KITTY_PID" ] && alias ff='fastfetch -c ~/.config/fastfetch/kitty.jsonc'
# greet once per terminal window: kitty draws the crest as an image, any other terminal (Lite's) the ink-text crest
if [ -z "$TENKA_GREETED" ] && [ -t 1 ] && [ -n "$DISPLAY$WAYLAND_DISPLAY" ]; then
  export TENKA_GREETED=1
  if [ -n "$KITTY_PID" ]; then fastfetch -c ~/.config/fastfetch/kitty.jsonc; else fastfetch; fi
  read -r -s -t 0.25 -d '' _tenka_junk 2>/dev/null  # swallow late terminal replies so they never land in the prompt
fi
