#!/usr/bin/env bash
#
#  Restart Dsb services / containers
#

declare -r MYSERVICENAME="$1"
declare -r MYTIMEOUT="${DSB_SHUTDOWN_TIMEOUT:-$DSBLIB_SHUTDOWN_TIMEOUT}"

dsblib_check_compose_version
dsb_set_box

if [ -n "$MYSERVICENAME" ]; then

    dsblib_parse_service_arg "$MYSERVICENAME"
    dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"

    if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
        dsb_get_container_id "${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX}" --anystatus
        if   [ -z "$DSB_CONTAINER_ID" ]; then
            dsblib_error_exit "Container ${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX} not found - cannot restart it."
        fi
        echo -e "Restarting container $DSBLIB_SERVICE_NAME:$DSBLIB_SERVICE_INDEX ($DSB_CONTAINER_ID) ... "
        dsblib_message "docker restart -t $MYTIMEOUT $DSB_CONTAINER_ID"
        if ! docker container restart -t "$MYTIMEOUT" "$DSB_CONTAINER_ID" >/dev/null ; then
            dsblib_error_exit "FAILURE"
        fi
        dsblib_green_message "done"
        dsblib_exit
    fi

    dsblib_get_service_replicas "$DSBLIB_SERVICE_NAME"
    if [ "$DSBLIB_RESULT" = 0 ]; then
        dsblib_red_message "Service '$DSBLIB_SERVICE_NAME': No containers to restart"
        dsblib_error_exit
    elif [ "$DSBLIB_RESULT" = 1 ]; then
        echo -e "Restarting service $DSBLIB_SERVICE_NAME ..."
        if ! dsb_docker_compose --dsblib-echo stop -t "$MYTIMEOUT" "$DSBLIB_SERVICE_NAME" ; then
            dsblib_error_exit "FAILURE"
        fi
        dsblib_init_service "$DSBLIB_SERVICE_NAME"
        if ! dsb_docker_compose --dsblib-echo start "$DSBLIB_SERVICE_NAME" ; then
            dsblib_error_exit "FAILURE"
        fi
        dsblib_exit
    fi

    echo -e "Restarting service $DSBLIB_SERVICE_NAME ..."
    if ! dsb_docker_compose --dsblib-echo restart -t "$MYTIMEOUT" "$DSBLIB_SERVICE_NAME" ; then
        dsblib_error_exit "FAILURE"
    fi
    dsblib_exit
fi

dsblib_exec cd "$DSB_BOX"
echo -e "Restarting dsb ..."
if ! dsb_docker_compose --dsblib-echo restart -t "$MYTIMEOUT" ; then
    dsblib_error_exit
fi

dsblib_exit