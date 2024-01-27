#!/usr/bin/env sh
#
#   Run or emulate command 'gosu'
#
#   Usage: sh /dsbutils/dsbgosu.sh <account> <command> [ ...<args> ]
#            or as the last entrypoint command
#          exec sh /dsbutils/dsbgosu.sh <account> <command> [ ...<args> ]

MYBINDSBGOSU="/bin/dsbgosu.sh"

if [ "$1" = "-c" ]; then
    if [ -n "$2" -a "$2" != " " ]; then
        eval "$2"
        exit "$?" # just in case
    fi
    echo "$0: Wrong parameters: $@" 1>&2
    exit 100
fi

if hash id 2>/dev/null && [ "$( id -u )" != 0 ]; then
    echo "$0 $@ - Must be run as root only!" 1>&2
    exit 100
fi

if [ -z "$1" -o -z "$2" ]; then
    echo "$0: Wrong parameters: $@" 1>&2
    exit 100
fi

if hash gosu 2>/dev/null ; then
    exec gosu "$@"    
fi

########## Preparing to call 'su' ...

# Update ENV_SUPATH and ENV_PATH in /etc/login.defs
#
# See: https://manpages.debian.org/stretch/login/su.1.en.html
#      https://manpages.debian.org/stretch/login/login.defs.5.en.html
if [ -f /etc/login.defs ] && hash sed 2>/dev/null ; then
    sed -i -r '/^\s*ENV_SUPATH\s/d' /etc/login.defs
    sed -i -r '/^\s*ENV_PATH\s/d'   /etc/login.defs
fi
echo "ENV_SUPATH  $PATH" >> /etc/login.defs
echo "ENV_PATH    $PATH" >> /etc/login.defs


if ! hash su 2>/dev/null ; then
    echo "$0: 'gosu' and 'su' commands not found" 1>&2
    exit 100
fi

if [ ! -f /etc/passwd ]; then
    echo "$0: File '/etc/passwd' not found" 1>&2
    exit 100
fi

MYUSER="$1"
shift

MYCOMMAND=
if [ -n "$PWD" ]; then
    MYCOMMAND="cd '${PWD}';"
fi
MYCOMMAND="${MYCOMMAND} exec "
for arg in "$@"; do
    MYCOMMAND="${MYCOMMAND} '${arg}'"
done

if [ ! -x "$MYBINDSBGOSU" ]; then
    if hash cat 2>/dev/null ; then
        # essential for busybox image...
        if   [ -x /bin/sh ]; then
            echo '#!/bin/sh'     > "$MYBINDSBGOSU"
        elif [ -x /usr/bin/sh ]; then
            echo '#!/usr/bin/sh' > "$MYBINDSBGOSU"
        fi
        cat /dsbutils/dsbgosu.sh >> "$MYBINDSBGOSU"
    elif hash cp 2>/dev/null ; then
        cp /dsbutils/dsbgosu.sh "$MYBINDSBGOSU"
    else
        echo "$0: 'cat' and 'cp' commands not found" 1>&2
        exit 100
    fi
    chown root:root    "$MYBINDSBGOSU"
    chmod a+rx,go-w    "$MYBINDSBGOSU"
    if [ ! -x "$MYBINDSBGOSU" ]; then
        echo "$0: Could not install $MYBINDSBGOSU" 1>&2
        exit 100
    fi
fi

MYNAME="${MYUSER%:*}"
MYGROUP="${MYUSER#*:}"
if [ "$MYGROUP" = "$MYUSER" ]; then
    MYGROUP=
fi

if ! hash cut 2>/dev/null ; then
    echo "WARNING: $0: Command 'cut' not found. Cannot validate user name." 1>&2
    exec su -s "$MYBINDSBGOSU" "$MYNAME" -c "$MYCOMMAND"
    exit 100 # just in case
fi

# Parse /etc/passwd
MYGID=
for mystr in $( cut -d: -f1,3,4,6,7 < /etc/passwd ) ; do
    myTmpName="${mystr%%:*}"  ; mystr="${mystr#*:}"
    myTmpUID="${mystr%%:*}"   ; mystr="${mystr#*:}"
    myTmpGID="${mystr%%:*}"
    if [ "$MYNAME" = "$myTmpName" -o "$MYNAME" = "$myTmpUID" ]; then
        MYNAME="$myTmpName"
        MYGID=myTmpGID
        break
    fi
done

if [ -z "$MYGID" ]; then
    echo "$0: User '$MYUSER' not found in /etc/passwd" 1>&2
    exit 100
fi

# Parse /etc/group
if [ -n "$MYGROUP" -a "$MYGROUP" != "$MYGID" ] && [ -f /etc/group ]; then
    for mystr in $( cut -d: -f1,3 < /etc/group ) ; do
        myTmpName="${mystr%%:*}"
        myTmpGID="${mystr##*:}"
        if [ "$myTmpGID" = "$MYGID" ]; then
            if [ "$MYGROUP" != "$myTmpName" ]; then
                echo "$0: Group '$MYGROUP' (GID=$MYGID) is not primary group for the user '$MYNAME'." 1>&2
                exit 100
            fi
            break;
        fi
    done
fi

exec su -s "$MYBINDSBGOSU" "$MYNAME" -c "$MYCOMMAND"