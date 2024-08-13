#
#  List Dsb services
#

if [ "$#" -gt 1 ]; then
    dsb_yellow_message "Usage: $DSBLIB_DSBCMD [ SERVICE_NAME ]"
    dsb_error_exit
fi

dsb_set_box

function dsblib__ps_trunc_image()
{
    DSBLIB_RESULT="$1"
    if [ "${#DSBLIB_RESULT}" -gt 40 ]; then
        DSBLIB_RESULT="...${DSBLIB_RESULT:$(( ${#DSBLIB_RESULT} - 37 )):37}"
    fi
}

function dsblib__ps_ps()
{
    local    myservice="$1"
    local    myindex=
    local -a mylist=()

    dsblib_check_compose_version

    if [ -n "$myservice" ]; then
        dsb_validate_service_arg "$myservice"
        myservice="$DSB_OUT_SERVICE_NAME"
        myindex="$DSB_OUT_SERVICE_INDEX"
    fi

    local myok=
    if [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -gt 1 ]; then
        local -a myopts=( --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
        if [ -n "$myservice" ]; then
            myopts=( "${myopts[@]}" --filter "label=com.docker.compose.service=$myservice" )
            if [ -n "$myindex" ]; then
                myopts=( "${myopts[@]}" --filter "label=com.docker.compose.container-number=$myindex" )
            fi
        fi

        myopts=( --all --format='{{.Names}}\t{{.Image}}\t{{.State}}\t{{.Status}}\t{{.Ports}}' "${myopts[@]}" )

        if mapfile -t mylist < <( if docker container ls "${myopts[@]}" 2>/dev/null ; then echo "$DSBLIB_NOTSET" ; fi ) ; then
            if [ "${mylist[ $(( ${#mylist[@]} - 1 )) ]}" = "$DSBLIB_NOTSET" ]; then
                myok=1
            fi
        fi
    fi

    if [ -z "$myok" ]; then # fallback to compose ps ...
        local myalloption=
        if [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -gt 1 ] || [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -eq 1 -a "$DSBLIB_COMPOSE_VERSION_MINOR" -ge 25 ]; then
            myalloption="--all"
        fi
        dsb_docker_compose --dsblib-echo  ps $myalloption $myservice
        dsblib_exit
    fi

    local maxName=9
    local maxImage=5
    local maxService=7 
    local maxState=5
    local maxStatus=6
    local myitem=
    for myline in "${mylist[@]}" ; do
        if [ "$myline" = "$DSBLIB_NOTSET" ]; then continue; fi
        dsblib_split "$myline" "$DSBLIB_CHAR_TAB"
        myitem="${DSBLIB_ARRAY_RESULT[0]}" ; if [ "${#myitem}" -gt "$maxName"   ]  ; then maxName="${#myitem}"   ; fi

        dsblib__ps_trunc_image "${DSBLIB_ARRAY_RESULT[1]}"
        if [ "${#DSBLIB_RESULT}" -gt "$maxImage" ] ; then maxImage="${#DSBLIB_RESULT}" ; fi

        myitem="${DSBLIB_ARRAY_RESULT[2]}" ; if [ "${#myitem}" -gt "$maxState"  ]  ; then maxState="${#myitem}"  ; fi
        myitem="${DSBLIB_ARRAY_RESULT[3]}" ; if [ "${#myitem}" -gt "$maxStatus" ]  ; then maxStatus="${#myitem}" ; fi
        dsblib_parse_container_name "${DSBLIB_ARRAY_RESULT[0]}"
        if [ "${#DSB_OUT_CONTAINER_SERVICE}" -gt "$maxService" ] ; then maxService="${#DSB_OUT_CONTAINER_SERVICE}" ; fi
    done

    local del='  '
    local line=
    dsblib_append "CONTAINER" "$maxName"    ; line="${line}${DSBLIB_RESULT}${del}"
    # dsblib_append "IMAGE"   "$maxImage"   ; line="${line}${DSBLIB_RESULT}${del}"
    dsblib_append "SERVICE"   "$maxService" ; line="${line}${DSBLIB_RESULT}${del}"
    dsblib_append "STATE"     "$maxState"   ; line="${line}${DSBLIB_RESULT}${del}"
    dsblib_append "STATUS"    "$maxStatus"  ; line="${line}${DSBLIB_RESULT}${del}PORTS"
    dsb_message "$line"

    for myline in "${mylist[@]}" ; do
        if [ "$myline" = "$DSBLIB_NOTSET" ]; then continue; fi
        dsblib_split "$myline" "$DSBLIB_CHAR_TAB"
        dsblib_parse_container_name "${DSBLIB_ARRAY_RESULT[0]}"
        line=
        dsblib_append "${DSBLIB_ARRAY_RESULT[0]}"  "$maxName"    ; line="${line}${DSBLIB_RESULT}${del}"

        # dsblib__ps_trunc_image "${DSBLIB_ARRAY_RESULT[1]}"
        # dsblib_append "$DSBLIB_RESULT"           "$maxImage"   ; line="${line}${DSBLIB_RESULT}${del}"

        dsblib_append "$DSB_OUT_CONTAINER_SERVICE" "$maxService" ; line="${line}${DSBLIB_RESULT}${del}"
        dsblib_append "${DSBLIB_ARRAY_RESULT[2]}"  "$maxState"   ; line="${line}${DSBLIB_RESULT}${del}"
        dsblib_append "${DSBLIB_ARRAY_RESULT[3]}"  "$maxStatus"  ; line="${line}${DSBLIB_RESULT}${del}${DSBLIB_ARRAY_RESULT[4]}"
        echo "$line"
    done
}
dsblib__ps_ps "$@"

dsblib_exit