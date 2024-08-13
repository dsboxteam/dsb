#
#   Start Dsb services / containers
#

declare MYFAILURE=
declare MYSERVICEARG=
declare MYBADUID=

dsb_set_box
dsblib_check_compose_version
dsblib_check_shutdown_timeout

dsblib_set_services
if [ "${#DSBLIB_PROJECT_SERVICES[@]}" = 0 ]; then
    dsb_error_exit "Please define some service (yaml file) in the COMPOSE_FILE variable\n"
fi

function dsblib__start_init_box()
{
    local -r mymode="$1"
    local    myname=
    local -a mylist

    pushd "$PWD" > /dev/null
    dsb_exec cd  "$DSB_BOX"

    if ! dsblib_is_prod_mode ; then
        dsb_exec chmod go-rwx  compose
        if [ -d config ]; then
            dsb_exec chmod go-rwx  config  # disable config directory for other host system users
            mapfile -t  mylist < <( find config -mindepth 1 -maxdepth 1 -type d )
            for myname in "${mylist[@]}" ; do
                dsb_exec chmod -R a+rX,go-w  "$myname"  # by default, enable config subdirectories for containers
                if [ -d "$myname/dsbinit.d" ]; then
                    chmod go-rwx "$myname/dsbinit.d"
                fi
            done
        fi        
    fi

    # Create home and logs directories and disable this ones for other host system users:
    if dsblib_mkdir_or_dev_mode      home ; then
        dsb_exec chmod go-rwx home
    fi
    if dsblib_mkdir_or_dev_mode      logs ; then
        dsb_exec chmod go-rwx logs
    fi

    dsblib_set_services  # Fill DSBLIB_PROJECT_SERVICES array
    for myname in "${DSBLIB_PROJECT_SERVICES[@]}" ; do
        if [ "$mymode" = "--all" -o -z "${DSBLIB_REPLICAS[$myname]} -o "${DSBLIB_REPLICAS[$myname]}" = 0" ]; then
            dsblib_init_service "$myname"
        fi
    done
    popd > /dev/null
}

function dsblib__start_service()
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
            dsb_red_message "Container $myContainer not found - cannot start it."
            MYFAILURE=1
        elif [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_RUNNING" ]; then
            dsb_green_message "Container $myContainer ($DSB_OUT_CONTAINER_ID) is already running"
        elif [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_PAUSED" ]; then
            echo -e "Unpause container $myContainer ($DSB_OUT_CONTAINER_ID) ... "
            dsb_message "docker container unpause $DSB_OUT_CONTAINER_ID"
            if docker container unpause "$DSB_OUT_CONTAINER_ID" >/dev/null ; then
                dsb_green_message "done"
            else
                dsb_red_message "FAILURE"
                MYFAILURE=1
            fi
        else
            echo -e "Starting container $myContainer ($DSB_OUT_CONTAINER_ID) ... "
            dsb_message "docker container start $DSB_OUT_CONTAINER_ID"
            if docker container start "$DSB_OUT_CONTAINER_ID" >/dev/null ; then
                dsb_green_message "done"
            else
                dsb_error_exit "FAILURE"
                MYFAILURE=1
            fi            
        fi
        return
    fi

    echo -e "Starting service $myService ..."
    dsblib_get_service_replicas "$myService"
    if [ "$DSBLIB_RESULT" -gt 0 ]; then
        if [ "$DSBLIB_RESULT" -eq 1 ] \
            && dsb_get_container_id "$myService" --anystatus \
            && [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_EXITED" -a -z "$MYBADUID" ]
        then
            dsblib_init_service "$myService"
        fi
        if dsb_docker_compose --dsblib-echo start "$myService" ; then
            dsb_green_message "done"
        else
            MYFAILURE=1
        fi
    elif [ -z "$MYBADUID" ]; then
        dsblib_init_service "$myService"
        if dsb_docker_compose --dsblib-echo  up -t "$DSB_SHUTDOWN_TIMEOUT" --no-deps --detach "$myService" ; then
            dsb_green_message "done"
        else
            MYFAILURE=1
        fi
    else
        dsb_red_message "Service startup is forbidden due to DSB_UID_GID conflict."
        MYFAILURE=1
    fi
}

if [ "$#" = 0 ]; then
    echo -e "Starting Dsb ..."
    dsblib_check_uid_gid

    dsblib_get_service_replicas "-" "--skip-orphans"
    if [ "${#DSBLIB_REPLICAS[@]}" = 0 ]; then
        dsblib__start_init_box --all   # init all services
        if ! dsb_docker_compose --dsblib-echo  up -t "$DSB_SHUTDOWN_TIMEOUT" --detach --remove-orphans ; then
            dsb_error_exit
        fi
    else
        dsblib__start_init_box         # init only services without containers
        if ! dsb_docker_compose --dsblib-echo  start "${!DSBLIB_REPLICAS[@]}" ; then
            dsb_error_exit
        fi
        dsblib_get_scale_options --short  # fill DSBLIB_ARRAY_RESULT array
        if ! dsb_docker_compose --dsblib-echo  up -t "$DSB_SHUTDOWN_TIMEOUT" --detach --remove-orphans "${DSBLIB_ARRAY_RESULT[@]}" ; then
            dsb_error_exit
        fi
    fi
    dsblib_exit
fi

echo
if ! dsblib_check_uid_gid '-' ; then
    MYBADUID=1
fi
for MYSERVICEARG in "$@" ; do
    dsblib__start_service "$MYSERVICEARG"
    echo
done

if [ "$MYFAILURE" = 1 ]; then
    dsb_error_exit
fi
dsblib_exit