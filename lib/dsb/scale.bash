#
#  Scale Compose service
#

declare -r MYSERVICEARG="$1"
declare -r MYREPLICAS="$2"

if [ -z "$MYSERVICEARG" -o -z "$MYREPLICAS" ]; then
    dsb_yellow_message "Usage: $DSBLIB_BINCMD $DSBLIB_DSBARG SERVICE_NAME REPLICAS"
    dsb_error_exit
fi

dsblib_check_compose_version
dsblib_check_shutdown_timeout
dsblib_check_uid_gid

dsb_validate_service_arg "$MYSERVICEARG"
declare -r MYSERVICENAME="$DSB_OUT_SERVICE_NAME"

if [ -n "$DSB_OUT_SERVICE_INDEX" ]; then
    dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Wrong service arg: $MYSERVICEARG"
fi

if [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -lt 2 ]; then
    # Note: Docker Compose 1.X.X has different behavior with --scale option and has some problems with stopped containers. So, start containes...
    dsblib_get_service_replicas "-" "--skip-orphans"
    if [ "${#DSBLIB_REPLICAS[@]}" != 0 ] && ! dsb_docker_compose start "${!DSBLIB_REPLICAS[@]}" ; then
        dsb_error_exit
    fi
else
    DSBLIB_REPLICAS=()
fi

DSBLIB_REPLICAS["$MYSERVICENAME"]="$MYREPLICAS"
dsblib_get_scale_options  # fill DSBLIB_ARRAY_RESULT array

if ! dsb_docker_compose --dsblib-echo  up -t $DSB_SHUTDOWN_TIMEOUT --detach --remove-orphans "${DSBLIB_ARRAY_RESULT[@]}" "$MYSERVICENAME" ; then
    dsb_error_exit
fi

dsblib_exit