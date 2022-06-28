#
#   Run shell (bash or sh) or some command in the container with root permissions
#

declare -r MYSERVICENAME="$1"
shift

if [ -z "$MYSERVICENAME" ]; then
    dsblib_yellow_message "Usage: $DSBLIB_BINCMD $DSBLIB_DSBARG <service_name> [ <command> [ ...<parameters> ] ]"
    dsblib_error_exit
fi

declare MYSPACES='^ *$'
if [ "$#" != 0 ] && [[ "$1" =~ $MYSPACES ]]; then
    dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: empty command name specified"
fi

declare MYINLINESCRIPT=
IFS= read -r -d '' MYINLINESCRIPT <<'ENDOFSCRIPT'
if [ -z "$HOME" ] && [ -d /root ]; then
    export HOME="/root"
fi
case "$TERM" in
    xterm-color | *-256color )
        #if [ -n "$BASH" ]; then
        #    export PS1='\033[36m'"$MYSERVICE"':\w\033[31m#\033[m '
        #else
            export PS1='$( echo "\033[36m'"$MYSERVICE"':$PWD\033[31m#\033[m" ) '
        #fi
        ;;
    *)
        #if [ -n "$BASH" ]; then
        #    export PS1="$MYSERVICE"':\w# '
        #else
            export PS1="$MYSERVICE"':$PWD# '
        #fi
        ;;
esac
if  [ "$#" = 0 ]; then
    if [ -n "$BASH" ]; then
        exec "$BASH" --norc
    fi
    exec sh
elif [ "$#" = 1 -a "$1" != "-l" ]; then
    exec "${BASH:-sh}" -c "$*"
elif ! hash "$1" 2>/dev/null ; then
    echo "Command '$1' not found in the container" 1>&2
    exit 127
fi
exec "${BASH:-sh}" -c '"$@"' "${BASH:-sh}" "$@"
ENDOFSCRIPT

dsb_get_container_id "$MYSERVICENAME"
declare MYPSPREFIX="${DSBLIB_SERVICE_NAME}${DSBLIB_SERVICE_INDEX:+:$DSBLIB_SERVICE_INDEX}"

dsblib_run_command   "$MYSERVICENAME" "0:0" - -l -c "dsbnop:MYSERVICE=${MYPSPREFIX@Q} ; ${MYINLINESCRIPT}" "dsbnop:$DSBLIB_BINCMD" "$@"
# Note: 'dsbnop:' prefix disables file mapping in the parameter

dsblib_exit "$?"