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

declare    MYOPT_CMD=
declare    MYOPT_INITD=
declare    MYOPT_BUILD=

function my_usage()
{
    dsblib_yellow_message "Usage: $DSBLIB_BINCMD $DSBLIB_DSBARG SERVICE_NAME [ DOCKER_IMAGE ] [ --sleep | --cmd  ] [ --initd ] [ --build ]"
    dsblib_error_exit
}

function my_parse_options()
{
    local mysleep=
    local myopt=
    for myopt in "$@" ; do
        case "$myopt" in
            --cmd   ) MYOPT_CMD=1 ;;
            --sleep ) mysleep=1   ;;
            --initd ) MYOPT_INITD=1 ;;
            --build ) MYOPT_BUILD=1 ;;
            *) dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Unknown option: $myopt" ;;
        esac
    done

    if [ "$MYOPT_CMD" = 1 -a "$mysleep" = 1 ]; then
        dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: --sleep and --cmd options cannot be used together"
    fi
}

function my_inspect_image()
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
        dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: docker image '$MYIMAGE' not found"
    elif [ "${#myarr[@]}" -gt 1 ]; then
        for myline in "${myarr[@]}" ; do
            dsblib_yellow_message "$myline"
        done
        dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: There are several tags for docker image '$MYIMAGE'"
    fi

    MYIMAGE="${myarr[0]}"

    dsblib_trim "$( docker image inspect "$MYIMAGE" --format='{{.Config.User|printf "%q"}}' )"
    MYUSER="$DSBLIB_RESULT"

    dsblib_trim "$( docker image inspect "$MYIMAGE" --format='{{.Config.WorkingDir|printf "%q"}}' )"
    MYWORKINGDIR="$DSBLIB_RESULT"

    dsblib_trim "$( docker image inspect "$MYIMAGE" --format '{{range .Config.Entrypoint}} {{.|printf "%q"}}{{end}}{{range .Config.Cmd}} {{.|printf "%q"}}{{end}}' )"
    MYENTRYPOINT="$DSBLIB_RESULT"
}

if [ -z "$MYSERVICENAME" ]; then
    my_usage
elif [ -f "$MYFILE" ]; then
    dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: File '$MYFILE' already exists"
fi

shift

if [ -n "$MYIMAGE" -a "${MYIMAGE#-}" = "$MYIMAGE" ]; then
    shift
else
    MYIMAGE=
fi

my_parse_options "$@"

if [ -n "$MYIMAGE" ]; then
    my_inspect_image
elif [ "$MYOPT_CMD" = 1 ]; then
    dsblib_error_exit "$DSBLIB_BINCMD $DSBLIB_DSBARG: Docker image must be defined with --cmd option"
fi

function my_create_yaml()
{
    local -r myeol=$'\n'
    local -r myindent="        "
    local -r myvindent="      - "
    local -r myMountInitd="/dsbinit.d"
    local -r myConfigInitd="$DSB_BOX/config/$MYSERVICENAME/dsbinit.d"
    local    mycmds=
    local    myVolumes=
    local    myNamedVolumes=
    local    myImage=

    if [ -n "$MYIMAGE" ]; then
        myImage="${myImage}${myeol}    image: '$MYIMAGE'"
    fi

    if [ "$MYOPT_BUILD" = 1 ]; then
        myImage="${myImage}${myeol}    build: \$DSB_ROOT/${MYSERVICENAME}"
    fi

    if dsblib_is_home_volumes ; then
        myVolumes="${myVolumes}${myvindent}${MYHOMEVOLUME}:/dsbhome${myeol}"
        myNamedVolumes="${myeol}volumes:${myeol}  ${MYHOMEVOLUME}:"
    else
        myVolumes="${myVolumes}${myvindent}\$DSB_BOX/home/${MYSERVICENAME}:/dsbhome${myeol}"
    fi

    local    mySkelSrc='$DSB_LIB_SKEL'
    if [ -d "$DSB_BOX/skel" ]; then
        mySkelSrc='$DSB_BOX/skel'
    fi

    if [ "$MYOPT_INITD" = 1 ]; then
        myVolumes="${myVolumes}${myvindent}\$DSB_BOX/${myConfigInitd#$DSB_BOX/}:${myMountInitd}${myeol}"
        mycmds="${mycmds}${myindent}sh /dsbutils/initd.sh ${myMountInitd}${myeol}"
        if dsblib_is_prod_mode ; then
            if [ ! -d "$myConfigInitd" ]; then
                dsblib_yellow_message "Warning: Please create ${myConfigInitd#${DSB_BOX%/*}/} directory"
            fi
        else
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
            mycmds="${mycmds}${myindent}cd ${MYWORKINGDIR}${myeol}"
        fi
        if [ -n "$MYUSER" -a "$MYUSER" != '""' -a "$MYUSER" != "''" ]; then
            mycmds="${mycmds}${myindent}exec sh /dsbutils/dsbgosu.sh ${MYUSER} ${MYENTRYPOINT}"
        else
            mycmds="${mycmds}${myindent}exec ${MYENTRYPOINT}"
        fi
    fi

    : > "$MYFILE"
    chmod go-rwx "$MYFILE"

    echo "version: '${DSB_COMPOSE_FILE_VERSION:-3.3}'
services:
  ${MYSERVICENAME}:${myImage}
    user:  root
    networks:
      dsbnet:
    environment:
      DSB_SERVICE: ${MYSERVICENAME}
    volumes:
      - \$DSB_SPACE:/dsbspace
      - \$DSB_LIB_UTILS:/dsbutils:ro
      - ${mySkelSrc}:/dsbskel:ro
${myVolumes}#   
#   Mount additional host directories:
#
#      - \$DSB_BOX/config/${MYSERVICENAME}/... : ... :ro
#      - \$DSB_BOX/logs/${MYSERVICENAME}/... : ...
#      - \$DSB_BOX/storage/${MYSERVICENAME}/... : ...
#
#   Define additional configuration options:
#
#    ports:
#      - '8080:8080'

    entrypoint:
      - sh
      - '-c'
      - |
        set -e
        sh /dsbutils/adduser.sh \"\$DSB_UID_GID\"
${mycmds}${myNamedVolumes}" > "$MYFILE"
}
if ! my_create_yaml ; then
    dsblib_error_exit
fi

dsblib_exit