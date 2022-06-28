#
#   Stop all Dsb services, all containers of the single service
#   or single container of the scaled service
#

dsblib_check_compose_version
dsb_set_box

declare -r MYSERVICENAME="$1"
declare -r MYTIMEOUT="${DSB_SHUTDOWN_TIMEOUT:-$DSBLIB_SHUTDOWN_TIMEOUT}"

if [ -n "$MYSERVICENAME" ]; then
    dsblib_parse_service_arg "$MYSERVICENAME"
    dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"

    if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
        dsb_get_container_id "${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX}" --anystatus
        if   [ -z "$DSB_CONTAINER_ID" ]; then
            dsblib_error_exit "Container ${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX} not found"
        elif [ "$DSB_CONTAINER_STATUS" = "$DSBLIB_STATUS_EXITED" ]; then
            dsblib_yellow_message "Container $DSBLIB_SERVICE_NAME:$DSBLIB_SERVICE_INDEX ($DSB_CONTAINER_ID) is already exited"
        fi

        echo -e "Stopping container $DSBLIB_SERVICE_NAME:$DSBLIB_SERVICE_INDEX ($DSB_CONTAINER_ID) ... "
        dsblib_message "docker container stop -t $MYTIMEOUT $DSB_CONTAINER_ID"
        if ! docker container stop -t "$MYTIMEOUT" "$DSB_CONTAINER_ID" ; then
            dsblib_error_exit "FAILURE"
        fi
        dsblib_green_message "done"
        dsblib_exit
    fi

    echo -e "Stopping service $DSBLIB_SERVICE_NAME ..."
    if ! dsb_docker_compose --dsblib-echo stop -t "$MYTIMEOUT" "$DSBLIB_SERVICE_NAME" ; then
        dsblib_error_exit
    fi
    dsblib_exit
fi

echo -e "Stopping dsb ..."
if ! dsb_docker_compose --dsblib-echo stop -t "$MYTIMEOUT" ; then
    dsblib_error_exit
fi

dsblib_exit