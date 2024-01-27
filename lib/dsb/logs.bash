#
#   Fetch the logs of the containers
#

declare -r MYSERVICEARG="$1"

if [ "$#" -gt 1 ]; then
    dsb_yellow_message "Usage: $DSBLIB_DSBCMD [ SERVICE_NAME ]"
    dsb_error_exit
fi

dsblib_check_compose_version
if [ -n "$MYSERVICEARG" ]; then
    dsb_validate_service_arg "$MYSERVICEARG"
    declare -r MYSERVICENAME="$DSB_OUT_SERVICE_NAME"

    if [ -n "$DSB_OUT_SERVICE_INDEX" ]; then
        declare -r MYCONTAINER="${DSB_OUT_SERVICE_NAME}${DSBLIB_CHAR_INDEX}${DSB_OUT_SERVICE_INDEX}"
        dsb_get_container_id "$MYCONTAINER" --anystatus
        if [ -z "$DSB_OUT_CONTAINER_ID" ]; then
            dsb_error_exit "Container $MYCONTAINER not found"
        fi
        dsb_message "docker logs $DSB_OUT_CONTAINER_ID ..."
        if ! docker logs "$DSB_OUT_CONTAINER_ID" ; then
            dsb_error_exit
        fi
        dsblib_exit
    fi

    if ! dsb_docker_compose --dsblib-echo logs "$MYSERVICENAME" ; then
        dsb_error_exit
    fi
    dsblib_exit
fi

if ! dsb_docker_compose --dsblib-echo logs ; then
    dsb_error_exit
fi

dsblib_exit