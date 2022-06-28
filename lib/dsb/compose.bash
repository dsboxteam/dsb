#
#  Run docker-compose subcommand
#

if ! dsb_set_box --check ; then
    dsb_set_single_box
fi

if [ "$#" = 0 ]; then
    dsb_docker_compose --dsblib-echo "$@"
    dsblib_exit "$?"
fi

declare -r MYSUBCOMMAND="$1"
shift
declare -a MYOPTIONS=( "$@" )

if [ "$MYSUBCOMMAND" = "run" ]; then
    MYOPTIONS=( --entrypoint "sh -c '\"\$0\" \"\$@\"'" "${MYOPTIONS[@]}" )
fi

dsb_docker_compose --dsblib-echo "$MYSUBCOMMAND" "${MYOPTIONS[@]}"
dsblib_exit "$?"