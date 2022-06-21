#! /bin/bash

# Define a bunch of alias
alias ls="ls -h -F --color=auto --show-control-chars"
alias la="ls -a"
alias ll="ls -lah"
alias lla="ls -lah"
alias grep="grep -nEI --color"

# printf '\033[3J' tels PuTTY to clear the scrollbar as well
alias pclear="clear && printf '\033[3J'"

# Common mistake
alias cd..="cd .."

# Secure operations
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias chmod="chmod --changes --preserve-root"

alias news="slrn"
alias md5="md5sum"

# Default to terminal version of emacs
alias emacs="emacs -nw"

# Work-around to make alias works with sudo
alias sudo='sudo '
