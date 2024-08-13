#
#  Restart Dsb services / containers
#

declare    MYFAILURE=
declare    MYSERVICEARG=
declare    MYCONTAINER=
declare -a MYSERVICES=()
declare -a MYCONTAINERS=()
declare -a MYCONTAINERIDS=()

dsb_set_box
dsblib_check_compose_version
dsblib_check_shutdown_timeout
dsblib_check_uid_gid '-'

dsblib_set_services
if [ "${#DSBLIB_PROJECT_SERVICES[@]}" = 0 ]; then
    dsb_error_exit "Please define some service (yaml file) in the COMPOSE_FILE variable\n"
fi

function dsblib__restart_service()
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
            dsb_red_message "Container $myContainer not found - cannot restart it."
            MYFAILURE=1
        else
            echo -e "Restarting container $myContainer ($DSB_OUT_CONTAINER_ID) ... "
            dsb_message "docker restart -t $DSB_SHUTDOWN_TIMEOUT $DSB_OUT_CONTAINER_ID"
            if docker container restart -t "$DSB_SHUTDOWN_TIMEOUT" "$DSB_OUT_CONTAINER_ID" >/dev/null ; then
                dsb_green_message "done"
            else
                dsb_red_message "FAILURE"
                MYFAILURE=1
            fi            
        fi
        return
    fi

    dsblib_get_service_replicas "$myService"
    if [ "$DSBLIB_RESULT" = 0 ]; then
        dsb_red_message "Service '$myService': No containers to restart"
        MYFAILURE=1
    else
        echo -e "Restarting service $myService ..."
        if ! dsb_docker_compose --dsblib-echo restart -t "$DSB_SHUTDOWN_TIMEOUT" "$myService" ; then
            dsb_red_message "FAILURE"
            MYFAILURE=1
        fi
    fi
}

if [ "$#" = 0 ]; then
    dsb_exec cd "$DSB_BOX"
    echo -e "Restarting Dsb ..."
    if ! dsb_docker_compose --dsblib-echo restart -t "$DSB_SHUTDOWN_TIMEOUT" ; then
        dsb_error_exit
    fi
    dsblib_exit
fi

echo
for MYSERVICEARG in "$@" ; do
    dsblib__restart_service "$MYSERVICEARG"
    echo
done

if [ "$MYFAILURE" = 1 ]; then
    dsb_error_exit
fi
dsblib_exit