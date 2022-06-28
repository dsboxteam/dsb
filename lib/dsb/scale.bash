#
#  Scale Compose service
#

declare -r MYSERVICENAME="$1"
declare -r MYTIMEOUT="${DSB_SHUTDOWN_TIMEOUT:-$DSBLIB_SHUTDOWN_TIMEOUT}"

dsblib_check_compose_version

if [ -z "$1" -o -z "$2" ]; then
    dsblib_yellow_message "Usage: $DSBLIB_BINCMD $DSBLIB_DSBARG SERVICE_NAME REPLICAS"
    dsblib_error_exit
fi

dsblib_parse_service_arg "$1"
if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
    dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Wrong service name: $MYSERVICENAME"
fi

dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"
dsblib_get_service_replicas "-" "--skip-orphans"

# Note: docker-compose has some problems with --scale and stopped containers. So, start containes...
if [ "${#DSBLIB_REPLICAS[@]}" != 0 ] && ! dsb_docker_compose start "${!DSBLIB_REPLICAS[@]}" ; then
    dsblib_error_exit
fi

DSBLIB_REPLICAS["$DSBLIB_SERVICE_NAME"]="$2"
dsblib_get_scale_options  # fill DSBLIB_ARRAY_RESULT array

if ! dsb_docker_compose --dsblib-echo  up -t $MYTIMEOUT --detach --remove-orphans "${DSBLIB_ARRAY_RESULT[@]}" "$DSBLIB_SERVICE_NAME" ; then
    dsblib_error_exit
fi

dsblib_exit