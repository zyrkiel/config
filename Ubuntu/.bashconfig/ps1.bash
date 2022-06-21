#! /bin/bash

# Common colors
RESET_COLOR=$(echo -e "\e[0m")
BLACK=$(echo -e "\e[0;30m")
DARK_GRAY=$(echo -e "\e[1;30m")
RED=$(echo -e "\e[0;31m")
LGHT_RED=$(echo -e "\e[1;31m")
GREEN=$(echo -e "\e[0;32m")
LGHT_GREEN=$(echo -e "\e[1;32m")
BROWN=$(echo -e "\e[0;33m")
YELLOW=$(echo -e "\e[1;33m")
BLUE=$(echo -e "\e[0;34m")
LGHT_BLUE=$(echo -e "\e[1;34m")
PURPLE=$(echo -e "\e[0;35m")
LGHT_PURPLE=$(echo -e "\e[1;35m")
CYAN=$(echo -e "\e[0;36m")
LGHT_CYAN=$(echo -e "\e[1;36m")
LGHT_GRAY=$(echo -e "\e[0;37m")
WHITE=$(echo -e "\e[1;37m")

# Detect chroot
if [ "x${debian_chroot}" != "x" ]; then
    displayed_host="${debian_chroot}"
elif [ "x${SCHROOT_SESSION_ID}" != "x" ]; then
    displayed_host="${SCHROOT_SESSION_ID}"
else
    displayed_host="\h"
fi

# root prompt :
#   "\nh:m [ ${USER}@${hostname} | ret = ${LAST_RETURN} > ${PATH}\n# "
# chroot prompt :
#   "\nh:m [ ${USER}@${chrootname} | ret = ${LAST_RETURN} > ${PATH}\n$ "
# default prompt :
#   "\nh:m [ ${USER}@${hostname} | ret = ${LAST_RETURN} > ${PATH}\n$ "
if [ "$USER" = "root" ]; then
    PS1="${LGHT_RED}\A${RESET_COLOR}-${LGHT_RED}\u${RESET_COLOR}@${YELLOW}"
    PS1="${PS1}${displayed_host}${RESET_COLOR}"
    PS1="${PS1}${RESET_COLOR}:${LGHT_BLUE}\W${RESET_COLOR}"'`custom_git_ps1`'"\n$ "
else
    PS1="${LGHT_RED}\A${RESET_COLOR}-${GREEN}\u${RESET_COLOR}@${YELLOW}"
    PS1="${PS1}${displayed_host}${RESET_COLOR}"
    PS1="${PS1}${RESET_COLOR}:${LGHT_BLUE}\W${RESET_COLOR}"'`custom_git_ps1`'"\n$ "
fi
