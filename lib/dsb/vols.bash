#
#   List Compose Volume names and corresponding Docker Volume names
#

declare -r MYQUIET="$1"
declare -a MYDOCKERVOLUMES=()

if [ "$#" -gt 0 ] && [ "$#" -gt 1 -o "$MYQUIET" != '--quiet' ]; then
    dsb_yellow_message "Usage: $DSBLIB_DSBCMD [ --quiet ]"
    dsb_error_exit
fi

dsb_set_box
dsblib_check_compose_version

dsb_exec mapfile -t MYDOCKERVOLUMES < <( docker volume ls --filter "label=com.docker.compose.project=${DSBLIB_LOWER_PROJECT}" --format '{{.Name}}' )
if [ -n "$MYQUIET" ]; then
    if [ "${#MYDOCKERVOLUMES[@]}" != 0 ]; then
        docker volume inspect "${MYDOCKERVOLUMES[@]}" --format '{{ $x := index .Labels "com.docker.compose.volume" }}{{if ne $x ""}}{{ printf "%s" $x}}{{end}}'
    fi
else
    dsb_message "COMPOSE VOLUME            DOCKER VOLUME"
    if [ "${#MYDOCKERVOLUMES[@]}" != 0 ]; then
        docker volume inspect "${MYDOCKERVOLUMES[@]}" \
            --format '{{ $x := index .Labels "com.docker.compose.volume" }}{{if ne $x ""}}{{ printf "%-26s" $x}}{{.Name}}{{end}}'
    fi
fi

dsblib_exit