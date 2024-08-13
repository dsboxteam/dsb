#
#   Remove Dsb services / containers
#

declare MYFAILURE=
declare MYSERVICEARG=

function dsblib__down_remove_service()
{
    if ! dsb_validate_service_arg "$1" --message ; then
        MYFAILURE=1
        return
    fi
    local -r myService="$DSB_OUT_SERVICE_NAME"

    if [ -n "$DSB_OUT_SERVICE_INDEX" ]; then
        local -r myContainer="${DSB_OUT_SERVICE_NAME}${DSBLIB_CHAR_INDEX}${DSB_OUT_SERVICE_INDEX}"
        dsb_get_container_id "$myContainer" --anystatus
        if [ -z "$DSB_OUT_CONTAINER_ID" ]; then
            dsb_red_message "Container $myContainer not found"
            MYFAILURE=1
            return
        fi        
        if [ "$DSB_OUT_CONTAINER_STATUS" != "$DSBLIB_STATUS_EXITED" ]; then
            echo -e "Stopping container $myContainer ($DSB_OUT_CONTAINER_ID) ... "
            dsb_message "docker container stop -t $DSB_SHUTDOWN_TIMEOUT $DSB_OUT_CONTAINER_ID"
            if ! docker container stop -t "$DSB_SHUTDOWN_TIMEOUT" "$DSB_OUT_CONTAINER_ID" ; then
                dsb_red_message "FAILURE"
                MYFAILURE=1
                return
            fi
        fi
        echo -e "Removing container $myContainer ($DSB_OUT_CONTAINER_ID) ... "
        dsb_message "docker container rm -f -v $DSB_OUT_CONTAINER_ID"
        if docker container rm -f -v "$DSB_OUT_CONTAINER_ID" ; then
            dsb_green_message "done"
        else
            dsb_red_message "FAILURE"
            MYFAILURE=1
        fi        
    else
        echo -e "Stopping service $myService ..."
        if ! dsb_docker_compose --dsblib-echo stop -t "$DSB_SHUTDOWN_TIMEOUT" "$myService" ; then
            MYFAILURE=1
        else
            echo -e "Removing service $myService ..."
            if ! dsb_docker_compose --dsblib-echo rm -f -v "$myService" ; then
                MYFAILURE=1
            fi
        fi
    fi
}

function dsblib__down_remove_all_services()
{
    dsb_message "\nRemoving all Dsb containers..."
    local    myLine=
    local -a myList
    mapfile -t myList < <( docker container ls --all --format='{{.ID}}\t{{.Names}}' )
    for myLine in "${myList[@]}" ; do
        dsblib_split "$myLine" "$DSBLIB_CHAR_TAB"
        local myid="${DSBLIB_ARRAY_RESULT[0]}"
        local myname="${DSBLIB_ARRAY_RESULT[1]}"

        if [ "${myname#${DSBLIB_PROJECT_PREFIX}}" != "$myname" ]; then
            docker container stop  -t $DSB_SHUTDOWN_TIMEOUT  "$myid" >/dev/null
            docker container rm -f -v "$myid"
        fi
    done
}

function dsblib__down_remove_all_networks()
{
    dsb_message "\nRemoving all Dsb networks..."
    local    myLine=
    local -a myList
    mapfile -t myList < <( docker network ls --format '{{.ID}}\t{{.Name}}' )
    for myLine in "${myList[@]}" ; do
        dsblib_split "$myLine" "$DSBLIB_CHAR_TAB"
        local myid="${DSBLIB_ARRAY_RESULT[0]}"
        local myname="${DSBLIB_ARRAY_RESULT[1]}"

        if [ "${myname#${DSBLIB_PROJECT_PREFIX}}" != "$myname" ]; then
            docker network rm "$myid"
        fi
    done
}

if [ "$1" = '--host' ]; then
    dsb_yellow_message -n "\nAre you sure you want to remove all Dsb containers from the host system? [yN] "
    read MYITEM
    if [ "$MYITEM" != "y" ]; then
        dsb_yellow_message "CANCELLED"
        dsb_error_exit
    fi
    dsb_yellow_message -n "\nAre you really sure? [yN] "
    read MYITEM
    if [ "$MYITEM" != "y" ]; then
        dsb_yellow_message "CANCELLED"
        dsb_error_exit
    fi
    if dsb_set_box --check ; then
        dsblib_check_compose_version
        dsblib_check_shutdown_timeout
        dsb_docker_compose --dsblib-echo  down -t "$DSB_SHUTDOWN_TIMEOUT" --remove-orphans
    fi
    dsblib__down_remove_all_services
    dsblib__down_remove_all_networks
    dsblib_exit
fi

dsb_set_box
dsblib_check_compose_version
dsblib_check_shutdown_timeout
dsblib_check_uid_gid '-'

if [ "$#" = 0 ]; then
    echo -e "Shutdown Dsb ..."
    if ! dsb_docker_compose --dsblib-echo  down -t "$DSB_SHUTDOWN_TIMEOUT" --remove-orphans ; then
        dsb_error_exit
    fi
    dsblib_exit
fi

echo
for MYSERVICEARG in "$@" ; do
    dsblib__down_remove_service "$MYSERVICEARG"
    echo
done

if [ "$MYFAILURE" = 1 ]; then
    dsb_error_exit
fi
dsblib_exit