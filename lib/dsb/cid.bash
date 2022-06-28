#
#   Echo Container ID to STDOUT
#

declare -r MYSERVICENAME="$1"

if [ -z "$MYSERVICENAME" ]; then
    dsblib_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: service name not specified "
    dsblib_error_exit
fi

if ! dsb_set_box --check ; then
    dsb_set_single_box
fi

dsb_get_container_id "$MYSERVICENAME" --anystatus
if [ -z "$DSB_CONTAINER_ID" ]; then
    dsblib_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: Container '${DSBLIB_SERVICE_NAME}${DSBLIB_SERVICE_INDEX:+:$DSBLIB_SERVICE_INDEX}' not found"
    dsblib_error_exit
fi

echo "$DSB_CONTAINER_ID"
dsblib_exit