#
#   Start all Dsb services, all containers of the single service
#   or single container of the scaled service
#

declare -r MYSERVICENAME="$1"
declare -r MYTIMEOUT="${DSB_SHUTDOWN_TIMEOUT:-$DSBLIB_SHUTDOWN_TIMEOUT}"

dsblib_check_compose_version
dsb_set_box

dsblib_set_services
if [ "${#DSBLIB_PROJECT_SERVICES[@]}" = 0 ]; then
    dsblib_error_exit "Please define some service (yaml file) in the COMPOSE_FILE variable\n"
fi

function my_init_box()
{
    local -r mymode="$1"
    local    myname=
    local -a mylist

    pushd "$PWD" > /dev/null
    dsblib_exec cd  "$DSB_BOX"

    if ! dsblib_is_prod_mode ; then
        dsblib_exec chmod go-rwx  compose
        if [ -d config ]; then
            dsblib_exec chmod go-rwx  config  # disable config directory for other host-users
            mapfile -t  mylist < <( find config -mindepth 1 -maxdepth 1 -type d )
            for myname in "${mylist[@]}" ; do
                dsblib_exec chmod -R a+rX  "$myname"  # by default, enable config subdirectories for containers
                if [ -d "$myname/dsbinit.d" ]; then
                    chmod go-rwx "$myname/dsbinit.d"
                fi
            done
        fi        
    fi

    # Create home, logs and storage directories and disable this ones for other host-users:
    if dsblib_mkdir_or_dev_mode      home ; then
        dsblib_exec chmod go-rwx home
    fi
    if dsblib_mkdir_or_dev_mode      logs ; then
        dsblib_exec chmod go-rwx logs
    fi
    if dsblib_mkdir_or_dev_mode      storage ; then
        dsblib_exec chmod go-rwx storage
    fi

    # clear all logs directories:
    if ! dsblib_is_prod_mode ; then
        mapfile -t  mylist < <( find logs -mindepth 1 -maxdepth 1 -type d )
        for myname in "${mylist[@]}" ; do
            if [ "$mymode" = "--all" -o -z "${DSBLIB_REPLICAS[$myname]} -o "${DSBLIB_REPLICAS[$myname]}" = 0" ]; then
                dsblib_clean_dir   "$DSB_BOX/$myname" > /dev/null
                dsblib_exec rm -fr "$DSB_BOX/$myname"
            fi
        done
    fi

    dsblib_set_services  # Fill DSBLIB_PROJECT_SERVICES array
    for myname in "${DSBLIB_PROJECT_SERVICES[@]}" ; do
        if [ "$mymode" = "--all" -o -z "${DSBLIB_REPLICAS[$myname]} -o "${DSBLIB_REPLICAS[$myname]}" = 0" ]; then
            dsblib_init_service "$myname"
        fi
    done
    popd > /dev/null
}

if [ -n "$MYSERVICENAME" ]; then

    dsblib_parse_service_arg "$MYSERVICENAME"
    dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"

    if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
        dsb_get_container_id "${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX}" --anystatus
        if   [ -z "$DSB_CONTAINER_ID" ]; then
            dsblib_error_exit "Container ${DSBLIB_SERVICE_NAME}:${DSBLIB_SERVICE_INDEX} not found - cannot start it."
        elif [ "$DSB_CONTAINER_STATUS" = "$DSBLIB_STATUS_RUNNING" ]; then
            dsblib_yellow_message "Container $DSBLIB_SERVICE_NAME:$DSBLIB_SERVICE_INDEX ($DSB_CONTAINER_ID) is already running"
            dsblib_exit
        fi
        echo -e "Starting container $DSBLIB_SERVICE_NAME:$DSBLIB_SERVICE_INDEX ($DSB_CONTAINER_ID) ... "
        dsblib_message "docker container start $DSB_CONTAINER_ID"
        if ! docker container start "$DSB_CONTAINER_ID" >/dev/null ; then
            dsblib_error_exit "FAILURE"
        fi
        dsblib_green_message "done"
        dsblib_exit
    fi

    echo -e "Starting service $DSBLIB_SERVICE_NAME ..."
    dsblib_get_service_replicas "$DSBLIB_SERVICE_NAME"
    if [ "$DSBLIB_RESULT" -gt 0 ]; then
        if ! dsb_docker_compose --dsblib-echo start "$DSBLIB_SERVICE_NAME" ; then
            dsblib_error_exit
        fi
    else
        dsblib_init_service "$DSBLIB_SERVICE_NAME"
        if ! dsb_docker_compose --dsblib-echo  up -t "$MYTIMEOUT" --no-deps --detach "$DSBLIB_SERVICE_NAME" ; then
            dsblib_error_exit
        fi
    fi
    dsblib_exit
fi

echo -e "Starting dsb ..."
dsblib_get_service_replicas "-" "--skip-orphans"
if [ "${#DSBLIB_REPLICAS[@]}" = 0 ]; then
    my_init_box --all   # init all services
    if ! dsb_docker_compose --dsblib-echo  up -t "$MYTIMEOUT" --detach --remove-orphans ; then
        dsblib_error_exit
    fi
else
    my_init_box         # init only services without containers
    if ! dsb_docker_compose --dsblib-echo  start "${!DSBLIB_REPLICAS[@]}" ; then
        dsblib_error_exit
    fi
    dsblib_get_scale_options --short  # fill DSBLIB_ARRAY_RESULT array
    if ! dsb_docker_compose --dsblib-echo  up -t "$MYTIMEOUT" --detach --remove-orphans "${DSBLIB_ARRAY_RESULT[@]}" ; then
        dsblib_error_exit
    fi
fi

dsblib_exit