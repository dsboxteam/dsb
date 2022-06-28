#
#  List Dsb services
#

dsblib_check_compose_version
dsb_set_box

declare -r MYSERVICENAME="$1"

declare MYALLOPTION=
if [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -gt 1 ] || \
   [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -eq 1 -a "$DSBLIB_COMPOSE_VERSION_MINOR" -ge 25 ]
then
    MYALLOPTION="--all"
fi

if [ -n "$MYSERVICENAME" ]; then
    dsblib_parse_service_arg "$MYSERVICENAME"
    if [ -n "$DSBLIB_SERVICE_INDEX" ]; then
        dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Wrong service name: $MYSERVICENAME"
    fi

    dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME"
    dsb_docker_compose --dsblib-echo  ps $MYALLOPTION "$DSBLIB_SERVICE_NAME" 
else
    dsb_docker_compose --dsblib-echo  ps $MYALLOPTION
fi

dsblib_exit