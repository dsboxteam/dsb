#
#   Run shell (bash or sh) or some command in the container with root permissions
#

declare -r MYSERVICEARG="$1"
shift

if [ -z "$MYSERVICEARG" ]; then
    dsb_yellow_message "Usage: $DSBLIB_BINCMD $DSBLIB_DSBARG <service_name> [ <command> [ ...<parameters> ] ]"
    dsb_error_exit
fi

declare MYSPACES='^ *$'
if [ "$#" != 0 ] && [[ "$1" =~ $MYSPACES ]]; then
    dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: empty command name specified"
fi

declare MYINLINESCRIPT=
IFS= read -r -d '' MYINLINESCRIPT <<'ENDOFSCRIPT'
if [ -n "$DSB_UID_GID" -a "$MYUIDGID" != "0:0" -a "$DSB_UID_GID" != "$MYUIDGID" ]; then
    echo "The container was launched from the different account ${DSB_UID_GID}!" 1>&2
    exit 126
fi
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

dsb_get_container_id "$MYSERVICEARG"
if [ "${MYSERVICEARG#*${DSBLIB_CHAR_INDEX}}" != "$MYSERVICEARG" -o "$DSB_OUT_CONTAINER_INDEX" != 1  ]; then
    declare -r MYPSPREFIX="${DSB_OUT_CONTAINER_SERVICE}${DSBLIB_CHAR_INDEX}${DSB_OUT_CONTAINER_INDEX}"
else
    declare -r MYPSPREFIX="${DSB_OUT_CONTAINER_SERVICE}"
fi

dsb_run_command "$MYSERVICEARG" "0:0" - -l -c "dsbnop:MYSERVICE=${MYPSPREFIX@Q} ; MYUIDGID=${DSB_UID_GID@Q} ; ${MYINLINESCRIPT}" "dsbnop:$DSBLIB_BINCMD" "$@"
# Note: the 'dsbnop:' prefix disables file path mapping in the parameter
# See also lib/utils/exec.sh when using '-' as a command name

dsblib_exit "$?"