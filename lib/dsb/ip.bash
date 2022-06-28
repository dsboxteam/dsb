#
#   Echo container IP address
#

declare -r MYSERVICENAME="$1"

if [ -z "$MYSERVICENAME" ]; then
    dsblib_yellow_message "Usage: $DSBLIB_DSBCMD SERVICE_NAME"
    dsblib_error_exit
fi

dsb_get_container_id "$MYSERVICENAME"

declare MYOUT="$( docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}|{{.IPPrefixLen}}{{end}}' "$DSB_CONTAINER_ID" )"
if [ -z "$MYOUT" ]; then
    # try old Docker client syntax is:
    MYOUT="$( docker inspect --format '{{ .NetworkSettings.IPAddress }}|{{ .NetworkSettings.IPPrefixLen }}' "$DSB_CONTAINER_ID" )"
fi

if [ -z "$MYOUT" -o "${MYOUT#|}" != "$MYOUT" ]; then
    dsblib_error_exit "Uncompatible 'docker inspect' output"
fi

# dsblib_n_message "IPAddress:   "
# echo "${MYOUT%%|*}"
# 
# MYOUT="${MYOUT#*|}"
# if [ -n "$MYOUT" ]; then
#     dsblib_n_message "IPPrefixLen: "
#     echo "${MYOUT#*|}"
# fi

echo "${MYOUT%%|*}"

dsblib_exit