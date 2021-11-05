#! /bin/bash

# Directory miss-spelling correction
if [ "x`shopt cdspell | cut -f 2`" == "xoff" ]; then
    shopt -s cdspell;
fi

# Directory miss-spelling correction
if [ "x`shopt histappend | cut -f 2`" == "xoff" ]; then
    shopt -s histappend;
fi
