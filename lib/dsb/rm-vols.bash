#
#  Remove Compose Volumes
#

declare    MYFAILURE=
declare    MYHOSTMODE=
declare    MYALLMODE=
declare    MYVOL=
declare    MYITEM=
declare    MYPROJECTNAME=
declare -a MYDOCKERVOLUMES=()
declare -a MYVOLUMESMAP=()
declare -a MYVOLUMES=()
declare -a MYCONTAINERS=()

if [ "$1" = '--host' ]; then
    MYHOSTMODE=1
    shift
    if [ "$#" != 0 ]; then
        MYFAILURE=1
    fi
elif [ "$#" = 0 ]; then
    MYALLMODE=1
fi

for MYVOL in "$@" ; do
    if [ -z "$MYVOL" -o "${MYVOL#--}" != "$MYVOL" -o "${MYVOL#* }" != "$MYVOL" ]; then
        MYFAILURE=1
    fi
done

if [ "$MYFAILURE" = 1 ]; then
    dsb_yellow_message "Usage: $DSBLIB_DSBCMD $DSBLIB_DSBARG [ --host | ...VOLUME_NAMES ]"
    dsb_error_exit
fi

# Usage: if dsblib__rm_vols_get_volume_containers <docker_named_volume> ; then
#           ... handle "${DSBLIB_ARRAY_RESULT[@]}"
#        fi
function dsblib__rm_vols_get_volume_containers()
{
    DSBLIB_ARRAY_RESULT=()
    local -a mylist=()
    dsb_exec mapfile -t mylist < <( docker container ls --all --format '{{.ID}}' )
    if [ "${#mylist[@]}" != 0 ]; then
        local -a mylist2=()
        dsblib_escape_for_golang "$1"
        dsb_exec mapfile -t mylist2 < <( 
            docker inspect "${mylist[@]}" --format \
            '{{ $name := .Name }}{{ range .Mounts }}{{if eq .Type "volume"}}{{if eq .Name "'"$DSBLIB_RESULT"'"}}{{ print $name }}{{end}}{{end}}{{end}}'
        )
        if [ "${#mylist2[@]}" != 0 ]; then
            local -A myContainers=()
            local    myline=
            for myline in "${mylist2[@]}" ; do
                dsblib_trim "$myline"
                myline="${DSBLIB_RESULT#/}"
                if [ -n "$myline" ]; then
                    myContainers["$myline"]=1
                fi
            done

            DSBLIB_ARRAY_RESULT=( "${!myContainers[@]}" )
            if [ "${#DSBLIB_ARRAY_RESULT[@]}" != 0 ]; then
                return 0
            fi
        fi
    fi
    return 1
}

if [ "$MYHOSTMODE" = 1 ]; then
    dsb_set_box --check || :
else
    dsb_set_box
    MYPROJECTNAME="=${DSBLIB_LOWER_PROJECT}"
fi

dsblib_check_compose_version
dsblib_check_shutdown_timeout
if [ "$MYHOSTMODE" != 1 ]; then
    dsblib_check_uid_gid '-' || :
fi

dsb_exec mapfile -t MYDOCKERVOLUMES < <( docker volume ls --filter "label=com.docker.compose.project${MYPROJECTNAME}" --format '{{.Name}}' )
if [ "$MYALLMODE" != 1 -a "$MYHOSTMODE" != 1 ]; then
    dsb_exec mapfile -t MYVOLUMESMAP < <( docker volume inspect "${MYDOCKERVOLUMES[@]}" --format '{{ $x := index .Labels "com.docker.compose.volume" }}{{if ne $x ""}}{{ printf "%s " $x}}{{.Name}}{{end}}' )
    MYDOCKERVOLUMES=()
    for MYVOL in "${MYVOLUMESMAP[@]}" ; do
        if dsblib_in_array "${MYVOL%% *}" "$@"  && ! dsblib_in_array "${MYVOL##* }" "${MYDOCKERVOLUMES[@]}" ; then
            MYDOCKERVOLUMES=( "${MYDOCKERVOLUMES[@]}" "${MYVOL##* }" )
            MYVOLUMES=( "${MYVOLUMES[@]}" "${MYVOL%% *}" )
        fi
    done
fi

if [ "$MYALLMODE" != 1 -a "$MYHOSTMODE" != 1 ]; then
    for MYVOL in "$@" ; do
        if ! dsblib_in_array "$MYVOL" "${MYVOLUMES[@]}" ; then
            dsb_red_message "Compose volume '$MYVOL' does not exist"
            MYFAILURE=1
        fi
    done
fi

if [ "${#MYDOCKERVOLUMES[@]}" = 0 ]; then
    dsb_yellow_message "\nNothing to remove\n"
    dsb_error_exit
fi

for MYVOL in "${MYDOCKERVOLUMES[@]}" ; do
    if dsblib__rm_vols_get_volume_containers "$MYVOL" ; then
        for MYITEM in "${DSBLIB_ARRAY_RESULT[@]}" ; do
            if ! dsblib_in_array "$MYITEM" "${MYCONTAINERS[@]}" ; then
                MYCONTAINERS=( "${MYCONTAINERS[@]}" "$MYITEM" )
            fi
        done
    fi
done

if [ "${#MYCONTAINERS[@]}" != 0 ]; then
    dsb_yellow_message "\nThe following Docker containers will be removed:"
    for MYITEM in "${MYCONTAINERS[@]}" ; do
        echo "$MYITEM"
    done
fi

dsb_yellow_message "\nThe following Docker volumes will be removed:"
for MYVOL in "${MYDOCKERVOLUMES[@]}" ; do
    echo "$MYVOL"
done

dsb_yellow_message -n "\nAre you sure? [yN] "
read MYITEM
if [ "$MYITEM" != "y" ]; then
    dsb_yellow_message "CANCELLED"
    dsb_error_exit
fi

if [ "$MYHOSTMODE" = 1 ]; then
    dsb_yellow_message -n "\nAre you really sure? [yN] "
    read MYITEM
    if [ "$MYITEM" != "y" ]; then
        dsb_yellow_message "CANCELLED"
        dsb_error_exit
    fi
fi

if [ "${#MYCONTAINERS[@]}" != 0 ]; then
    dsb_message "\nRemoving Docker containers ..."
    if ! docker container rm -f -v "${MYCONTAINERS[@]}" ; then
        dsb_error_exit "FAILURE"
    fi
fi

dsb_message "\nRemoving Docker volumes ..."
if ! docker volume rm -f "${MYDOCKERVOLUMES[@]}" ; then
    dsb_error_exit "FAILURE"
fi

echo
if [ "$MYFAILURE" = 1 ]; then
    dsb_error_exit
fi
dsblib_exit