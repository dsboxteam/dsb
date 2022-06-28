#
#   Print Docker volume names
#

dsblib_check_compose_version
dsb_set_box

declare -r MYVOL="$1"
if [ -n "$MYVOL" ]; then
    if dsblib_get_docker_volume "$MYVOL" ; then
        echo "$DSBLIB_RESULT"
        dsblib_exit
    fi
    dsblib_yellow_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: Docker Compose named volume '$MYVOL' not found"
    dsblib_error_exit
fi

declare -a MYVOLUMES=()
dsblib_exec mapfile -t MYVOLUMES < <( docker volume ls --filter "label=com.docker.compose.project=${DSBLIB_LOWER_PROJECT}" --format '{{.Name}}' )

echo "COMPOSE VOLUME            DOCKER VOLUME"
if [ "${#MYVOLUMES[@]}" != 0 ]; then
    docker volume inspect "${MYVOLUMES[@]}" \
        --format '{{ $x := index .Labels "com.docker.compose.volume" }}{{if ne $x ""}}{{ printf "%-26s" $x}}{{.Name}}{{end}}'
fi