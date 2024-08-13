#
#   Echo container IP address
#

declare -r MYSERVICEARG="$1"

if [ -z "$MYSERVICEARG" -o "$#" -gt 1 ]; then
    dsb_yellow_message "Usage: $DSBLIB_DSBCMD SERVICE_NAME"
    dsb_error_exit
fi

dsb_get_container_id "$MYSERVICEARG"

declare MYOUT="$( docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}|{{.IPPrefixLen}}{{end}}' "$DSB_OUT_CONTAINER_ID" )"
if [ -z "$MYOUT" ]; then
    # try old Docker client syntax:
    MYOUT="$( docker inspect --format '{{ .NetworkSettings.IPAddress }}|{{ .NetworkSettings.IPPrefixLen }}' "$DSB_OUT_CONTAINER_ID" )"
fi

if [ -z "$MYOUT" -o "${MYOUT#|}" != "$MYOUT" ]; then
    dsb_error_exit "Unsupported 'docker inspect' output"
fi

echo "${MYOUT%%|*}"
dsblib_exit