#
#   Stop Dsb services / containers
#

declare MYFAILURE=
declare MYSERVICEARG=

dsb_set_box
dsblib_check_compose_version
dsblib_check_shutdown_timeout
dsblib_check_uid_gid '-' || :

function dsblib__stop_service()
{
    if ! dsb_validate_service_arg "$1" --message ; then
        MYFAILURE=1
        return
    fi
    local -r myService="$DSB_OUT_SERVICE_NAME"

    if [ -n "$DSB_OUT_SERVICE_INDEX" ]; then
        local -r myContainer="${DSB_OUT_SERVICE_NAME}${DSBLIB_CHAR_INDEX}${DSB_OUT_SERVICE_INDEX}"
        dsb_get_container_id "$myContainer" --anystatus
        if   [ -z "$DSB_OUT_CONTAINER_ID" ]; then
            dsb_red_message "Container $myContainer not found"
            MYFAILURE=1
        elif [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_EXITED" ]; then
            dsb_green_message "Container $myContainer ($DSB_OUT_CONTAINER_ID) is already exited"
        else
            echo -e "Stopping container $myContainer ($DSB_OUT_CONTAINER_ID) ... "
            dsb_message "docker container stop -t $DSB_SHUTDOWN_TIMEOUT $DSB_OUT_CONTAINER_ID"
            if docker container stop -t "$DSB_SHUTDOWN_TIMEOUT" "$DSB_OUT_CONTAINER_ID" ; then
                dsb_green_message "done"
            else
                dsb_red_message "FAILURE"
                MYFAILURE=1
            fi            
        fi
    else
        echo -e "Stopping service $myService ..."
        if ! dsb_docker_compose --dsblib-echo stop -t "$DSB_SHUTDOWN_TIMEOUT" "$myService" ; then
            MYFAILURE=1
        fi
    fi
}

if [ "$#" = 0 ]; then
    echo -e "Stopping Dsb ..."
    if ! dsb_docker_compose --dsblib-echo stop -t "$DSB_SHUTDOWN_TIMEOUT" ; then
        dsb_error_exit
    fi
    dsblib_exit
fi

echo
for MYSERVICEARG in "$@" ; do
    dsblib__stop_service "$MYSERVICEARG"
    echo
done

if [ "$MYFAILURE" = 1 ]; then
    dsb_error_exit
fi
dsblib_exit