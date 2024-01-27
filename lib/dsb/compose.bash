#
#  Run Docker Compose subcommand
#

dsb_set_box
if [ "$#" = 0 ]; then
    dsb_docker_compose --dsblib-echo "$@"
    dsblib_exit "$?"
fi

declare -r MYSUBCOMMAND="$1"
shift
declare -a MYOPTIONS=( "$@" )

case "$MYSUBCOMMAND" in
    create | exec | run | up )
        dsblib_check_uid_gid      # cancel if conflict
        ;;
    down | kill | pause | restart | rm | start | stop | unpause )
        dsblib_check_uid_gid '-'  # ignore conflict in root mode
        ;;
esac

if [ "$MYSUBCOMMAND" = "run" ]; then
    MYOPTIONS=( --entrypoint "sh -c '\"\$0\" \"\$@\"'" "${MYOPTIONS[@]}" )
fi

dsb_docker_compose "$MYSUBCOMMAND" "${MYOPTIONS[@]}"
dsblib_exit "$?"