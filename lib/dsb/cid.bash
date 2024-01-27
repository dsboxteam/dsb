#
#   Echo Container ID to STDOUT
#

declare -r MYSERVICEARG="$1"

if [ -z "$MYSERVICEARG" ]; then
    dsb_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: service name not specified "
    dsb_error_exit
fi

dsb_set_box
dsb_get_container_id "$MYSERVICEARG" --anystatus
if [ -z "$DSB_OUT_CONTAINER_ID" ]; then
    dsb_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: Container '$MYSERVICEARG' not found"
    dsb_error_exit
fi

echo "$DSB_OUT_CONTAINER_ID"
dsblib_exit