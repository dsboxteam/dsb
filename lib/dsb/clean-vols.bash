#
#  Remove all files on the named Compose volume (but not volume itself)
#

declare -r MYVOLUME="$1"
declare -r MYTIMEOUT="${DSB_SHUTDOWN_TIMEOUT:-$DSBLIB_SHUTDOWN_TIMEOUT}"

dsblib_check_compose_version

dsb_set_box

if [ -z "$MYVOLUME" ]; then
    dsblib_yellow_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: Compose volume name not specified"
    dsblib_yellow_message "\nUsage: $DSBLIB_DSBCMD COMPOSE_VOLUME\n"
    dsblib_error_exit
fi

if ! dsblib_get_docker_volume "$MYVOLUME" ; then
    if dsblib_stdout_includes "$MYVOLUME" dsb_docker_compose config --volumes ; then
        dsblib_yellow_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: Compose volume '$MYVOLUME' does not exist"
        dsblib_exit
    fi
    dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Compose volume '$MYVOLUME' is not defined in the project"
fi

declare -r MYDOCKERVOL="$DSBLIB_RESULT"
declare -a MYCONTAINERS=()
if dsblib_get_volume_containers "$MYDOCKERVOL" ; then
    MYCONTAINERS=( "${DSBLIB_ARRAY_RESULT[@]}"  )
fi

declare -l MYREPLY=
dsblib_n_yellow_message "\nGoing to clean Docker volume '$MYDOCKERVOL'\nAre you sure? [yN] "
read MYREPLY
if [ "$MYREPLY" != "y" ]; then
    dsblib_yellow_message "CANCELLED"
    dsblib_error_exit
fi

if [ "${#MYCONTAINERS[@]}" != 0 ]; then
    echo -e -n "Stopping "${#MYCONTAINERS[@]}" container(s) ... "
    if ! docker container stop -t "$MYTIMEOUT" "${MYCONTAINERS[@]}" >/dev/null ; then
        dsblib_error_exit "FAILURE"
    fi
    dsblib_green_message "done"
fi

echo -e -n "Cleaning Docker volume '$MYDOCKERVOL' ... "
dsblib_select_busybox_image
if docker run --rm -it -v "$MYDOCKERVOL:/var/www" "$DSBLIB_BUSYBOX_IMAGE" sh -c 'rm -rf /var/www/*' ; then
    dsblib_green_message "done"
else
    dsblib_error_exit "Cannot clean docker volume '$myname'"
fi

if [ "${#MYCONTAINERS[@]}" != 0 ]; then
    echo -e -n "Starting "${#MYCONTAINERS[@]}" container(s) ... "
    if ! docker container start "${MYCONTAINERS[@]}" >/dev/null ; then
        dsblib_error_exit "FAILURE"
    fi
    dsblib_green_message "done"
fi

dsblib_exit