#! /bin/bash

# Bash history configuration colors
MYBLUE=$(echo -e '\e[0;34m')
MYRESET_COLOR=$(echo -e '\e[00m')

# Don't put duplicated lines if previous one was the same
export HISTCONTROL=ignoredups:erasedups

# Upgrade command history max count (default 500)
HISTSIZE=1000

# Upgrade command history max lines (default 500, should be caped by HISTSIZE)
HISTFILESIZE=100000

# Make history display a bit more user-friendly
HISTTIMEFORMAT="${MYBLUE}[%d/%m/%Y %H:%M:%S]${MYRESET_COLOR} "
HISTIGNORE="history:pwd:whoami:exit:ls"

###############################
# Share history between terms #
###############################

# Append history entries instead or replacing it
shopt -s histappend
