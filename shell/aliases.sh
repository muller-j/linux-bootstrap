# Shared aliases for Bash and Zsh.
unset LS_COLORS EZA_COLORS

alias ls='eza --icons=always'
alias ll='eza -lah --icons=always'
alias tree='eza --tree --icons=always --group-directories-first'
alias cat='batcat'
alias fd='fdfind'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
alias tm='tmux new -s main'

if [ -n "${BASH_VERSION:-}" ]; then
        alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
fi
