#!/usr/bin/env sh
#
#   Usage: sh /dsbutils/exec.sh <UID:GID> ( <TERM value> | - ) ( <umask> | - ) ( <workdir> | - ) ( <cmd> | - ) [ ...<cmd_args>]

if [ "$#" -lt 4 ]; then
    echo "@$DSB_SERVICE: $0: wrong args: ${@}" 1>&2
    exit 1
fi

MYDSBCWD=
MYUSER=
MYUMASK=

if [ "$1" = "-" -o "$1" != "" ]; then
    MYUSER="$( id -u )"
else
    MYUSER="${1%%:*}"
fi
shift

if [ "$1" != "-" -a "$1" != "" ]; then
    export TERM="$1"
fi
shift

if [ "$1" != "-" -a "$1" != "" ]; then
    MYUMASK="$1"
fi
shift

if [ "$1" != "-" -a "$1" != "" ] && [ -d "$1" ]; then
    MYDSBCWD="$1"
fi
shift

# Set default current directory
if [ -z "$MYDSBCWD" ]; then
    if [ -n "$HOME" -a "$HOME" != "/" ] && [ -d "$HOME" ]; then
        MYDSBCWD="$HOME"
    elif [ "$( id -un 2>/dev/null )" != "dsbuser" ]; then
        echo "Container has no passwd entry for 'dsbuser' account" 1>&2
        exit 1
    else
        echo "Could not set current working directory in the container!" 1>&2
        exit 1
    fi
fi

# Set umask
if [ "$MYUSER" = "0" -o "$MYUSER" = "root" ]; then
    if [ -n "$DSB_UMASK_ROOT" ]; then
        MYUMASK="$DSB_UMASK_ROOT"
    fi
else
    if [ -n "$DSB_UMASK_SH" ]; then
        MYUMASK="$DSB_UMASK_SH"
    fi
fi

MYINLINEBASH='MYUMASK="'"$MYUMASK"'"
if [ -n "$HOME" ] && [ -d "$HOME" ]; then
    pushd $PWD > /dev/null
    cd "$HOME" 1>&2
    if [ -f "/etc/profile" ]; then
        . "/etc/profile" 1>&2
    fi

    if [ -f "$HOME/.bash_profile" ]; then
        . "$HOME/.bash_profile" 1>&2
    elif [ -r "$HOME/.bash_login" ]; then
        . "$HOME/.bash_login" 1>&2
    elif [ -r "$HOME/.profile" ]; then
        . "$HOME/.profile" 1>&2
    fi

    popd > /dev/null
elif [ -f "/etc/profile" ]; then
    . "/etc/profile" 1>&2
fi
if [ -n "$MYUMASK" ]; then umask "$MYUMASK" ; fi
exec bash --noprofile --norc "$@"
'

if [ "$1" = "-" -o "$1" = "" ]; then
    shift
    MYSHELL="sh"
    if hash bash 2>/dev/null ; then
       MYSHELL="bash"
    fi

    if [ "$1" = "-l" ]; then
        # Redirect STDOUT to STDERR in /etc/profile, ~/.profile, ~/.bash_profile, ~/ .bash_login
        shift
        if [ "$MYSHELL" = "sh" ]; then
            if [ -n "$HOME" ] && [ -d "$HOME" ]; then
                cd "$HOME" 1>&2
            fi
            if [ -f "/etc/profile" ]; then
                . "/etc/profile" 1>&2
            fi
            if [ -f "$HOME/.profile" ]; then
                . "$HOME/.profile" 1>&2
            fi
            set -- sh "$@"
        else # bash
            set -- bash -c "$MYINLINEBASH" bash "$@"
        fi
    else
        set -- "$MYSHELL" "$@"
    fi
elif ! hash "$1" 2>/dev/null ; then
    echo "Command '${1}' not found in the container" 1>&2
    exit 127
fi

if [ -n "$MYUMASK" ]; then umask "$MYUMASK" ; fi

cd "$MYDSBCWD" 1>&2
exec "$@"