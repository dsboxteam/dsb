#
#   Fetch the logs of the service or single container
#

declare -r MYSERVICENAME="$1"

if [ -z "$MYSERVICENAME" ]; then
    dsblib_yellow_message "Usage: $DSBLIB_DSBCMD SERVICE_NAME"
    dsblib_error_exit
fi

dsblib_check_compose_version

dsblib_parse_service_arg "$MYSERVICENAME"
dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"

if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
    declare -r MYCONTAINER="${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX}"
    dsb_get_container_id "$MYCONTAINER" --anystatus
    if [ -z "$DSB_CONTAINER_ID" ]; then
        dsblib_error_exit "Service '$DSBLIB_SERVICE_NAME': container '$MYCONTAINER' not found"
    fi
    dsblib_message "docker logs $DSB_CONTAINER_ID ..."
    if ! docker logs "$DSB_CONTAINER_ID" ; then
        dsblib_error_exit
    fi
    dsblib_exit
fi

if ! dsb_docker_compose --dsblib-echo logs "$DSBLIB_SERVICE_NAME" ; then
    dsblib_error_exit
fi

dsblib_exit