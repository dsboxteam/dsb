#
#  Clean storage, logs and home subdirectories in the .dsb directory
#

declare -r MYSERVICENAME="$1"
declare -r MYTIMEOUT="${DSB_SHUTDOWN_TIMEOUT:-$DSBLIB_SHUTDOWN_TIMEOUT}"

dsblib_check_compose_version

dsb_set_box

if dsblib_is_prod_mode ; then
    dsblib_error_exit "This subcommand is not supported in Prod Mode (DSB_PROD_MODE=true)"
fi

dsblib_exec cd "$DSB_BOX"

function my_are_you_sure()
{
    local -l myreply=
    dsblib_n_yellow_message "\nGoing to remove ${1}\nAre you sure? [yN] "
    read myreply
    if [ "$myreply" != "y" ]; then
        dsblib_yellow_message "CANCELLED"
        dsblib_error_exit
    fi
}

function my_remove_dir()
{
    mysubdir="$1"
    dsblib_clean_dir "$mysubdir"

    if [ "$2" = "--remove" ]; then
        if ! rm -fr "$mysubdir" ; then
            dsblib_error_exit "\nCould not remove directory '${mysubdir}'"
        fi
        echo -e "Removed  $mysubdir"
    fi
}

function my_clean_box()
{
    local -r mydir="$1"
    local -r myservice="$2"
    local    mysubdir=

    if [ ! -d "$mydir" ]; then
        return 0
    fi

    if [ -z "$myservice" ]; then
        pushd "$PWD" > /dev/null 
        dsblib_exec cd "$mydir"
        local    myname=
        local -a mylist    
        mapfile -t  mylist < <( find . -maxdepth 1 -type d ! -name '\.' -printf '%f\n' )
        for myname in "${mylist[@]}" ; do
            my_remove_dir "$mydir/$myname" --remove
        done
        popd > /dev/null
    else
        my_remove_dir "$mydir/$myservice"
    fi
}

function my_clean_home()
{
    if ! dsblib_is_home_volumes ; then
        return 0
    fi

    local -a myservices=()
    if [ -n "$1" ]; then
        myservices=( "$1" )
    else
        dsblib_set_services
        myservices=( "${DSBLIB_PROJECT_SERVICES[@]}" )
    fi

    local myname=
    for myname in "${myservices[@]}" ; do
        if dsblib_get_docker_volume "dsbuser-$myname" ; then
            local mydockervol="$DSBLIB_RESULT"
            dsblib_select_busybox_image
            echo -e -n "Cleaning Docker volume '$mydockervol' ... "
            if docker run --rm -it -v "$mydockervol:/var/www" "$DSBLIB_BUSYBOX_IMAGE" sh -c 'rm -rf /var/www/*' ; then
                dsblib_green_message "done"
            else
                dsblib_error_exit "\nCouldn't clean Docker volume '$mydockervol'"
            fi
        fi
    done
    return 0
}

declare MYRESTART=
declare MYSERVICESUBDIR=

DSBLIB_SERVICE_NAME=

if [ -n "$MYSERVICENAME" ]; then

    dsblib_parse_service_arg "$MYSERVICENAME"
    if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
        dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Wrong service name: $MYSERVICENAME"
    fi

    dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"
    MYSERVICESUBDIR="/$DSBLIB_SERVICE_NAME"

    case "$DSBLIB_DSBARG" in
        clean )         my_are_you_sure "logs, storage and home contents for service '$MYSERVICENAME'" ;;
        clean-logs )    my_are_you_sure "logs contents for service '$MYSERVICENAME'" ;;
        clean-storage ) my_are_you_sure "storage contents for service '$MYSERVICENAME'" ;;
        clean-home )    my_are_you_sure "dsbuser home contents for service '$MYSERVICENAME'" ;;
    esac

    if ! dsblib_make_sure_service_stopped "$DSBLIB_SERVICE_NAME" ; then
        MYRESTART=1
        dsblib_message "Stopping service $DSBLIB_SERVICE_NAME ..."
        if ! dsb_docker_compose stop -t "$MYTIMEOUT" "$DSBLIB_SERVICE_NAME" ; then
            dsblib_error_exit
        fi
        if ! dsblib_make_sure_service_stopped "$DSBLIB_SERVICE_NAME" ; then
            dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Cannot stop service '$MYSERVICENAME'"
        fi
    fi

else
    case "$DSBLIB_DSBARG" in
        clean )         my_are_you_sure "dsb project logs, storage and home contents" ;;
        clean-logs )    my_are_you_sure "dsb project logs contents" ;;
        clean-storage ) my_are_you_sure "dsb project storage contents" ;;
        clean-home )    my_are_you_sure "dsb project home contents" ;;
    esac

    # NOTE: Down and do not restart project after cleaning...
    if ! dsblib_make_sure_no_containers ; then
        echo -e "Shutdown dsb ..."
        if ! dsb_docker_compose --dsblib-echo  down -t "$MYTIMEOUT" --remove-orphans ; then
            dsblib_error_exit "Could not shutdown dsb project"
        fi
    fi
fi

dsblib_message "Cleaning ${DSB_BOX} ..."
case "$DSBLIB_DSBARG" in
    clean )
        my_clean_box "$DSB_BOX/home"        "$DSBLIB_SERVICE_NAME"
        my_clean_box "$DSB_BOX/storage"     "$DSBLIB_SERVICE_NAME"
        my_clean_box "$DSB_BOX/logs"        "$DSBLIB_SERVICE_NAME"
        ;;
    clean-logs )
        my_clean_box "$DSB_BOX/logs"        "$DSBLIB_SERVICE_NAME"
        ;;
    clean-storage )
        my_clean_box "$DSB_BOX/storage"     "$DSBLIB_SERVICE_NAME"
        ;;
    clean-home )
        my_clean_box "$DSB_BOX/home"        "$DSBLIB_SERVICE_NAME"
        ;;
#    clean-config )
#        if [ -n "$DSBLIB_SERVICE_NAME" ]; then
#            my_clean_box "$DSB_BOX/config"  "$DSBLIB_SERVICE_NAME"
#        fi
#        ;;
esac

if dsblib_is_home_volumes ; then
    if [ -z "$DSBLIB_SERVICE_NAME" ]; then
        dsblib_message "Removing dsbuser home volumes ..."
    else
        dsblib_message "Cleaning dsbuser home volumes ..."
    fi
    case "$DSBLIB_DSBARG" in
        clean | clean-home ) my_clean_home "$DSBLIB_SERVICE_NAME" ;;
    esac
fi

if [ "$MYRESTART" = 1 ]; then
    if [ -n "$DSBLIB_SERVICE_NAME" ]; then
        dsblib_get_service_replicas "$DSBLIB_SERVICE_NAME"
        if [ "$DSBLIB_RESULT" -gt 0 ]; then
            if ! dsb_docker_compose start "$DSBLIB_SERVICE_NAME" ; then
                dsblib_error_exit
            fi
        else
            dsblib_init_service "$DSBLIB_SERVICE_NAME"
            if ! dsb_docker_compose --dsblib-echo  up -t "$MYTIMEOUT" --no-deps --detach "$DSBLIB_SERVICE_NAME" ; then
                dsblib_error_exit
            fi
        fi
    elif ! dsb_docker_compose --dsblib-echo  up -t "$MYTIMEOUT" --detach --remove-orphans ; then
        dsblib_error_exit
    fi
fi

dsblib_exit