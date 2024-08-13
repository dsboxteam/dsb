#
#   Creatе .yaml file template for a given Docker image 
#

dsb_set_box

declare -r MYSERVICENAME="$1"
declare    MYIMAGE="$2"

declare -r MYFILE="$DSB_COMPOSE/$MYSERVICENAME.yaml"
declare -r MYHOMEVOLUME="dsbuser-$MYSERVICENAME"
declare    MYUSER=
declare    MYWORKINGDIR=
declare    MYENTRYPOINT=
declare -a MYVOLUMES=()
declare -a MYEXPOSEDPORTS=()

declare    MYOPT_CMD=
declare    MYOPT_INITD=
declare    MYOPT_BUILD=

function dsblib__yaml_usage()
{
    dsb_yellow_message "Usage: $DSBLIB_BINCMD $DSBLIB_DSBARG SERVICE_NAME [ DOCKER_IMAGE ] [ --sleep | --cmd  ] [ --initd ] [ --build ]"
}

function dsblib__yaml_parse_options()
{
    local mysleep=
    local myopt=
    for myopt in "$@" ; do
        case "$myopt" in
            --cmd   ) MYOPT_CMD=1 ;;
            --sleep ) mysleep=1   ;;
            --initd ) MYOPT_INITD=1 ;;
            --build ) MYOPT_BUILD=1 ;;
            *) dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Unknown option: $myopt" ;;
        esac
    done

    if [ "$MYOPT_CMD" = 1 -a "$mysleep" = 1 ]; then
        dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: --sleep and --cmd options cannot be used together"
    fi
}

# Usage:   dsblib__yaml_parse_inspect_map <image> <property>
# Example: dsblib__yaml_parse_inspect_map 'postgres:14.1-bullseye' '.Config.Volumes'
#          ... handle $DSBLIB_ARRAY_RESULT array ...
function dsblib__yaml_parse_inspect_map()
{
    DSBLIB_ARRAY_RESULT=()
    local -a mylist
    mapfile -t mylist < <( docker image inspect "$1" --format '{{range $key, $value := '"$2"'}}{{$key}}'"$DSBLIB_CHAR_EOL"'{{end}}' )
    local mykey=
    for mykey in "${mylist[@]}" ; do
        dsblib_trim "$mykey"
        if [ -n "$DSBLIB_RESULT" ]; then
            DSBLIB_ARRAY_RESULT=( "${DSBLIB_ARRAY_RESULT[@]}" "$DSBLIB_RESULT" )
        fi
    done
}

function dsblib__yaml_inspect_image()
{
    local -a myarr
    local    myline=
    local    myname="${MYIMAGE##*/}"
    local mytag="${myname##*:}"
    if [ "$mytag" = "$myname" ]; then
        mapfile -t myarr < <( docker images explore "--filter=reference=${MYIMAGE}:*" --format='{{.Repository}}:{{.Tag}}' )
    else
        mapfile -t myarr < <( docker images explore "--filter=reference=${MYIMAGE}" --format='{{.Repository}}:{{.Tag}}' )
    fi

    if [ "${#myarr[@]}" = 0 ]; then
        if [ "$MYOPT_BUILD" = 1 ]; then
            return 0
        fi
        dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: docker image '$MYIMAGE' not found"
    elif [ "${#myarr[@]}" -gt 1 ]; then
        for myline in "${myarr[@]}" ; do
            dsb_yellow_message "$myline"
        done
        dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: There are several tags for docker image '$MYIMAGE'"
    fi

    MYIMAGE="${myarr[0]}"

    dsblib_trim "$( docker image inspect "$MYIMAGE" --format='{{.Config.User|printf "%q"}}' )"
    MYUSER="$DSBLIB_RESULT"

    dsblib_trim "$( docker image inspect "$MYIMAGE" --format='{{.Config.WorkingDir|printf "%q"}}' )"
    MYWORKINGDIR="$DSBLIB_RESULT"

    dsblib_trim "$( docker image inspect "$MYIMAGE" --format '{{range .Config.Entrypoint}} {{.|printf "%q"}}{{end}}{{range .Config.Cmd}} {{.|printf "%q"}}{{end}}' )"
    MYENTRYPOINT="$DSBLIB_RESULT"

    dsblib__yaml_parse_inspect_map "$MYIMAGE"  '.Config.Volumes'
    MYVOLUMES=( "${DSBLIB_ARRAY_RESULT[@]}" )

    dsblib__yaml_parse_inspect_map "$MYIMAGE"  '.Config.ExposedPorts'
    MYEXPOSEDPORTS=( "${DSBLIB_ARRAY_RESULT[@]}" )
}

if [ -z "$MYSERVICENAME" -o "${MYSERVICENAME#-}" != "$MYSERVICENAME" ]; then
    dsblib__yaml_usage
    dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: The SERVICE_NAME parameter is omitted"
elif [ -f "$MYFILE" ]; then
    dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: File '$MYFILE' already exists"
fi

shift

if [ -n "$MYIMAGE" -a "${MYIMAGE#-}" = "$MYIMAGE" ]; then
    shift
else
    MYIMAGE=
fi

dsblib__yaml_parse_options "$@"

if [ -n "$MYIMAGE" ]; then
    dsblib__yaml_inspect_image
elif [ "$MYOPT_CMD" = 1 ]; then
    dsblib__yaml_usage
    dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Docker image must be defined with --cmd option"
elif [ "$MYOPT_BUILD" != 1 ]; then
    dsblib__yaml_usage
    dsb_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: The DOCKER_IMAGE parameter can only be omitted if the --build option is present"
fi

function dsblib__yaml_create_yaml()
{
    local -r myindent="        "
    local -r myvindent="      - "
    local -r mynindent="  "
    local -r myMountInitd="/dsbinit.d"
    local -r myConfigDir="$DSB_BOX/config/$MYSERVICENAME"
    local -r myConfigInitd="$myConfigDir/dsbinit.d"
    local    mycmds=
    local    myVolumes=
    local    myNamedVolumes=
    local    myImage=
    local    myStorageVolumes=
    local    myCount=0
    local    myIndex=0
    local    myPorts=
    local    myport=
    local    myprotocol=
    local    mySkelSrc='$DSB_SKEL'

    if [ -d "$DSB_BOX/skel" ]; then
        mySkelSrc='$DSB_BOX/skel'
    fi

    if [ -n "$MYIMAGE" ]; then
        myImage="${myImage}${DSBLIB_CHAR_EOL}    image: '$MYIMAGE'"
    fi

    if [ "$MYOPT_BUILD" = 1 ]; then
        myImage="${myImage}${DSBLIB_CHAR_EOL}    build: \$DSB_ROOT/${MYSERVICENAME}"
    fi

    if dsblib_is_home_volumes ; then
        myVolumes="${myVolumes}${myvindent}${MYHOMEVOLUME}:/dsbhome${DSBLIB_CHAR_EOL}"
        myNamedVolumes="${DSBLIB_CHAR_EOL}volumes:${DSBLIB_CHAR_EOL}${mynindent}${MYHOMEVOLUME}:"
    else
        myVolumes="${myVolumes}${myvindent}\$DSB_BOX/home/${MYSERVICENAME}:/dsbhome${DSBLIB_CHAR_EOL}"
    fi

    # Initialize myStorageVolumes & myNamedVolumes
    if [ "${#MYVOLUMES[@]}" = 0 ]; then
        MYVOLUMES=( ' ...' )
    fi
    myCount="${#MYVOLUMES[@]}"
    if   [ "$myCount"  = 1 ]; then
        myStorageVolumes="${myStorageVolumes}#${myvindent}${MYSERVICENAME}:${MYVOLUMES[0]}${DSBLIB_CHAR_EOL}"
        if [ -z "$myNamedVolumes" ]; then
            myNamedVolumes="${DSBLIB_CHAR_EOL}#volumes:${DSBLIB_CHAR_EOL}#${mynindent}${MYSERVICENAME}:"
        else
            myNamedVolumes="${myNamedVolumes}${DSBLIB_CHAR_EOL}#${mynindent}${MYSERVICENAME}:"
        fi
    elif [ "$myCount" != 0 ]; then
        for (( myIndex=0 ; myIndex < myCount ; ++ myIndex )) ; do
            myStorageVolumes="${myStorageVolumes}#${myvindent}${MYSERVICENAME}-${myIndex}:${MYVOLUMES[$myIndex]}${DSBLIB_CHAR_EOL}"
            if [ -z "$myNamedVolumes" ]; then
                myNamedVolumes="${DSBLIB_CHAR_EOL}#volumes:${DSBLIB_CHAR_EOL}#${mynindent}${MYSERVICENAME}-${myIndex}:"
            else
                myNamedVolumes="${myNamedVolumes}${DSBLIB_CHAR_EOL}#${mynindent}${MYSERVICENAME}-${myIndex}:"
            fi
        done
    fi

    # Initialize myPorts
    if [ "${#MYEXPOSEDPORTS[@]}" = 0 ]; then
        MYEXPOSEDPORTS=( '8080/tcp' )
    fi
    myCount="${#MYEXPOSEDPORTS[@]}"
    for (( myIndex=0 ; myIndex < myCount ; ++ myIndex )) ; do
        myport="${MYEXPOSEDPORTS[$myIndex]}"
        myprotocol="${myport#*/}"
        if [ "$myport" = "$myprotocol" ]; then
            myprotocol=
        else
            myport="${myport%/*}"
            myprotocol="/${myprotocol}"
        fi
        myPorts="${myPorts}#${myvindent}'127.0.0.1:${myport}:${myport}${myprotocol}'${DSBLIB_CHAR_EOL}"
    done

    if [ "$MYOPT_INITD" = 1 ]; then
        myVolumes="${myVolumes}${myvindent}\$DSB_BOX/${myConfigInitd#$DSB_BOX/}:${myMountInitd}${DSBLIB_CHAR_EOL}"
        mycmds="${mycmds}${myindent}sh /dsbutils/initd.sh ${myMountInitd}${DSBLIB_CHAR_EOL}"
        if dsblib_is_prod_mode ; then
            if [ ! -d "$myConfigInitd" ]; then
                dsb_yellow_message "Warning: Please create ${myConfigInitd#${DSB_BOX%/*}/} directory"
            fi
        else
            # By default, we assume root or dsbuser access rights for the container's workload
            if [ ! -d "$myConfigDir" ]; then
                mkdir -p        "$myConfigDir"
                chmod "go-rwx"  "$myConfigDir"
            fi
            mkdir -p        "$myConfigInitd"
            chmod "go-rwx"  "$myConfigInitd"
        fi
    fi

    if [ "$MYOPT_CMD" != 1 \
         -o -z "$MYENTRYPOINT" \
         -o "$MYENTRYPOINT" = '"bash"' \
         -o "$MYENTRYPOINT" = '"/bin/bash"' \
         -o "$MYENTRYPOINT" = '"/usr/bin/bash"' \
         -o "$MYENTRYPOINT" = '"sh"' \
         -o "$MYENTRYPOINT" = '"/bin/sh"' \
         -o "$MYENTRYPOINT" = '"/usr/bin/sh"' \
         -o "$MYENTRYPOINT" = "bash" -o "$MYENTRYPOINT" = "sh" ]
    then
        mycmds="${mycmds}${myindent}exec sh /dsbutils/sleep.sh"
    else
        if [ -n "$MYWORKINGDIR" -a "$MYWORKINGDIR" != '""' -a "$MYWORKINGDIR" != "''" ]; then
            mycmds="${mycmds}${myindent}cd ${MYWORKINGDIR}${DSBLIB_CHAR_EOL}"
        fi
        if [ -n "$MYUSER" -a "$MYUSER" != '""' -a "$MYUSER" != "''" ]; then
            mycmds="${mycmds}${myindent}exec sh /dsbutils/dsbgosu.sh ${MYUSER} ${MYENTRYPOINT}"
        else
            mycmds="${mycmds}${myindent}exec ${MYENTRYPOINT}"
        fi
    fi

    : > "$MYFILE"
    chmod go-rwx "$MYFILE"

    echo "services:
  ${MYSERVICENAME}:${myImage}
    user:  root
    networks:
      dsbnet:
    environment:
      DSB_SERVICE: '${MYSERVICENAME}'
      DSB_UID_GID: '\${DSB_UID_GID}'
    volumes:
      - \$DSB_SPACE:/dsbspace
      - \$DSB_UTILS:/dsbutils:ro
      - ${mySkelSrc}:/dsbskel:ro
${myVolumes}#   
#   Mount additional host directories:
#
#      - \$DSB_BOX/config/${MYSERVICENAME}/... : ... :ro
#      - \$DSB_BOX/logs/${MYSERVICENAME}/... : ...
${myStorageVolumes}#
#   Define additional configuration options:
#
#    ports:
${myPorts}#

    entrypoint:
      - sh
      - '-c'
      - |
        set -e
        sh /dsbutils/adduser.sh \"\$DSB_UID_GID\"
${mycmds}${myNamedVolumes}" > "$MYFILE"
}
if ! dsblib__yaml_create_yaml ; then
    dsb_error_exit
fi

dsblib_exit