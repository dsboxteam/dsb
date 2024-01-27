
# Note: This file is not read by bash, if ~/.bash_profile or ~/.bash_login exists.

if [ -n "$BASH_VERSION" ]; then  # if running bash ...
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	    . "$HOME/.bashrc"
    fi
fi

DSB_TEMP="$DSB_SERVICE"
if [ -z "$DSB_TEMP" ]; then
    DSB_TEMP="[dsb]"
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color | *-256color )
        export PS1='$( echo "\033[36m'"$DSB_TEMP"':$PWD\033[m\$" ) '
        ;;
    *)
        export PS1="$DSB_TEMP"':$PWD\$ '
        ;;
esac

# set PATH to include the user's bin directories if they exist

if [ -d "$HOME/.npm_global/bin" ] ; then
    PATH="$HOME/.npm_global/bin:$PATH"
fi

if [ -d "$HOME/.composer/vendor/bin" ] ; then
    PATH="$HOME/.composer/vendor/bin:$PATH"
fi

export PATH="$HOME/.local/bin:$PATH"

unset DSB_TEMP