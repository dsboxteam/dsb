#!/usr/bin/env sh
#
#   Usage: sh /dsbutils/initd.sh  <init_scripts_directory>

MYINITDIR="$1"

if   [ -z "$MYINITDIR" ]; then
    echo "$0: Directory parameter not defined" 1>&2
    exit 100
elif [ ! -d "$MYINITDIR" ]; then
    echo "$0: Directory '$MYINITDIR' not found" 1>&2
    exit 100
fi

cd "$MYINITDIR"
if [ "$PWD" != "$MYINITDIR" ]; then
    echo "$0: Directory '$MYINITDIR' not available" 1>&2
    exit 100
fi

if hash sort 2>/dev/null ; then
    MYLIST="$( ls -1 | sort )"
else
    MYLIST="$( ls -1 )"
fi

MYEXITRC=0
for MYFILE in $MYLIST ; do
    MYFILE="$MYINITDIR/$MYFILE"
    if [ -f "$MYFILE" ] && [ "${MYFILE%\.sh}" != "$MYFILE" -o "${MYFILE%\.bash}" != "$MYFILE" ]; then
        MYRC=1
        if [ -x "$MYFILE" ]; then
            "$MYFILE"
            MYRC="$?"
        elif [ "${MYFILE%\.sh}" != "$MYFILE" ]; then
            sh "$MYFILE"
            MYRC="$?"
        elif hash bash 2>/dev/null ; then
            bash "$MYFILE"
            MYRC="$?"
        else 
            MYEXITRC=20
            echo "$0: $MYFILE: 'bash' not found" 1>&2            
            continue
        fi
        if [ "$MYRC" != 0 ]; then
            echo "$0: $MYFILE FAILURE, RC=$MYRC" 1>&2
            MYEXITRC=10
        fi
    fi
done

if [ "$MYEXITRC" != 0 ]; then
    echo "$0: SOME INIT SCRIPTS FAILED" 1>&2
fi
exit "$MYEXITRC"