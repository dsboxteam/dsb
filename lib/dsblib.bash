
set -e

function dsblib_reset_options()
{
    local    mymode=
    local -r myOptions="$-"
    local    mystr="HCEPfakmvxe" #  set +P  # ????
    while [ "${#mystr}" != 0 ]; do
        mymode="${mystr:0:1}"
        mystr="${mystr:1}"
        if [[ "$myOptions" =~ $mymode ]]; then
            set "+$mymode"
        fi
    done

    mystr="hB"
    while [ "${#mystr}" != 0 ]; do
        mymode="${mystr:0:1}"
        mystr="${mystr:1}"
        if [[ ! "$myOptions" =~ $mymode ]]; then
            set "-$mymode"
        fi
    done
}

function dsblib_export_env_vars()
{
    local    myPrefix=
    local    myvar=
    local -a myarr

    for myPrefix in "$@" ; do
        eval 'myarr=( "${!'"$myPrefix"'@}" )'
        for   myvar in "${myarr[@]}" ; do
            export "$myvar"
        done
    done
}

function dsblib_unset_env_vars()
{
    local    myPrefix=
    local    myvar=
    local -a myarr

    for myPrefix in "$@" ; do
        eval 'myarr=( "${!'"$myPrefix"'@}" )'
        for   myvar in "${myarr[@]}" ; do
            if ! unset "$myvar" ; then
                echo "dsblib.bash: unset '${myvar}' failure - EXECUTION ABORTED" 1>&2
                exit 1
            fi
        done
    done
}

dsblib_unset_env_vars  "DSB_" "DSBUSR_" "DSBLIB_" "COMPOSE_" "DOCKER_"

#### declare DSBLIB_OSTYPE

case "$OSTYPE" in
    linux*   )  declare -r DSBLIB_OSTYPE=LINUX   ;;
    darwin*  )  declare -r DSBLIB_OSTYPE=OSX     ;;
    bsd*     )  declare -r DSBLIB_OSTYPE=BSD     ;;
    solaris* )  declare -r DSBLIB_OSTYPE=SOLARIS ;;
    msys*    )  declare -r DSBLIB_OSTYPE=WINDOWS ;;
    cygwin*  )  declare -r DSBLIB_OSTYPE=WINDOWS ;;
    * ) declare -r DSBLIB_OSTYPE=UNKNOWN ;;
esac

declare -r  DSB_WORKDIR="$( pwd -P )"
declare     DSBLIB_BINCMD="${BASH_SOURCE[(( ${#BASH_SOURCE[@]} - 1 ))]##*/}"
# Note: The constant contains the name of the executable script (in 'dsb-script' the value is changed)


#### Echo functions:

if [[ "$TERM" =~ "color" ]]; then
    declare -r DSBLIB_COLOR_TERM=1
else
    declare -r DSBLIB_COLOR_TERM=
fi

function dsblib_message()          { if [ -t 1 -a -n "$DSBLIB_COLOR_TERM" ]; then echo -e "\e[36m""$@""\e[m" ; else echo -e "$@" ; fi }
function dsblib_n_message()        { if [ -t 1 -a -n "$DSBLIB_COLOR_TERM" ]; then echo -e -n "\e[36m""$@""\e[m" ; else echo -e -n "$@" ; fi }
function dsblib_green_message()    { if [ -t 1 -a -n "$DSBLIB_COLOR_TERM" ]; then echo -e "\e[32m""$@""\e[m" ; else echo -e "$@" ; fi }

# NOTE: mylib_red_message must write to STDERR only!
function dsblib_red_message()      { if [ -t 2 -a -n "$DSBLIB_COLOR_TERM" ]; then echo -e "\e[31m""$@""\e[m" 1>&2 ; else echo -e "$@" 1>&2 ; fi }

# NOTE: mylib_yellow_message must write to STDERR only!
function dsblib_yellow_message()   { if [ -t 2 -a -n "$DSBLIB_COLOR_TERM" ]; then echo -e "\e[33m""$@""\e[m" 1>&2 ; else echo -e "$@" 1>&2 ; fi }
function dsblib_n_yellow_message() { if [ -t 2 -a -n "$DSBLIB_COLOR_TERM" ]; then echo -e -n "\e[33m""$@""\e[m" 1>&2 ; else echo -e "$@" 1>&2 ; fi }

function dsblib_exit()
{
    exit "${1:-0}"
}

function dsblib_error_exit()
{
    local mymsg="$@"
    if [ -n "$mymsg" ]; then
        if [ "${mymsg%\.}" != "$mymsg" ]; then
            mymsg="$mymsg "
        elif [ "${mymsg%\\n}" = "$mymsg" ]; then
            mymsg="$mymsg - "
        fi
        mymsg="${mymsg}EXECUTION ABORTED"

        dsblib_red_message "$mymsg" 1>&2

        # Save last error in case of IDE integration problems
        if [ -n "$HOME" ]; then
            echo "$mymsg" > "$HOME/dsb-lasterror.log"
        fi
    fi
    exit 1
}

function dsblib_gnu_readlink()
{
    case "$DSBLIB_OSTYPE" in
        LINUX )     readlink  "$@" ; return "$?" ;;
        OSX | BSD ) greadlink "$@" ; return "$?" ;;
    esac
    echo -e "${DSBLIB_BINCMD}: dsblib_gnu_readlink: Unsupported OS Type: $DSBLIB_OSTYPE - EXECUTION ABORTED" 1>&2
    exit 100
}

function dsblib_which()
{
    local mycmd=
    for mycmd in "$@" ; do
        if ! hash "$mycmd" > /dev/null 2>/dev/null ; then
            dsblib_error_exit "${DSBLIB_BINCMD}: '$mycmd' command not found"
        fi
    done
}

#### Check runtime utilities

dsblib_which  cp cut docker docker-compose find id ls rm

case "$DSBLIB_OSTYPE" in
    LINUX )     dsblib_which  readlink  ;;
    OSX | BSD ) dsblib_which  greadlink ;;
    *)  dsblib_error_exit "${DSBLIB_BINCMD}: Unsupported OS Type: $OSTYPE - EXECUTION ABORTED" 1>&2
        exit 100
        ;;
esac

######################
#
#   GLOBAL VARIABLES
#
#   Declared in the dsb_set_box():  DSB_ROOT, DSB_BOX, DSB_COMPOSE, DSBLIB_PROJECT_NAME, DSBLIB_LOWER_PROJECT
#   Declared in the 'bin/dsb':      DSBLIB_DSBCMD, DSBLIB_DSBARG

declare -r  DSBLIB_LIB="${BASH_SOURCE[0]%/*}"
# Note: ${BASH_SOURCE[0]} is always a full path string. See dsb and dsb-script

declare -r  DSB_LIB_UTILS="$DSBLIB_LIB/utils"
declare -r  DSB_LIB_SKEL="$DSBLIB_LIB/skel"

declare -r  DSB_UID="$( id -u )"
declare -r  DSB_GID="$( id -g )"
declare -r  DSB_UID_GID="$DSB_UID:$DSB_GID"   # used in .yaml files

# dsb-script runtime variable:
declare     DSB_SCRIPT_PATH=
declare     DSB_SCRIPT_NAME=

# dsb_get_container_id() output variables:
declare     DSB_CONTAINER_ID=
declare     DSB_CONTAINER_SERVICE=
declare     DSB_CONTAINER_STATUS=

declare     DSBLIB_CMDPATH="${DSBLIB_LIB%/*}/bin/$DSBLIB_BINCMD"
# The constant contains the full path name of the executable command

declare -r  DSBLIB_DSBENV='.dsbenv'
declare -r  DSBLIB_NOTSET='@@@#*^NOTSET^*#@@@'
declare -r  DSBLIB_PROJECT_PREFIX="dsb-"
declare -r  DSBLIB_STATUS_RUNNING="running"
declare -r  DSBLIB_STATUS_EXITED="exited"
declare -r  DSBLIB_STATUS_PAUSED="paused"
declare -r  DSBLIB_SHUTDOWN_TIMEOUT=10       # default stop/shutdown timeout

declare     DSBLIB_BUSYBOX_IMAGE=

declare -a  DSBLIB_PROJECT_SERVICES=()
declare -a  DSBLIB_DOCKER_EXEC_ARGS=()
declare -a  DSBLIB_RUN_ENV=()
declare -a  DSBLIB_RESOLVE_EXTS=()
declare -a  DSBLIB_RESOLVED_ARGS=()

declare     DSBLIB_RESULT=
declare -a  DSBLIB_ARRAY_RESULT=()

# dsb_get_container_id() internal variable:
declare     DSBLIB_LAST_SERVICE_ARG=

# dsblib_check_compose_version() output variables:
declare     DSBLIB_COMPOSE_VERSION_MAJOR=
declare     DSBLIB_COMPOSE_VERSION_MINOR=
declare     DSBLIB_COMPOSE_VERSION_PATCH=

# dsblib_get_service_replicas() output variable:
declare -A  DSBLIB_REPLICAS=()

# dsblib_parse_service_arg() & dsb_get_container_id() output variables:
declare     DSBLIB_SERVICE_VAR=
declare     DSBLIB_SERVICE_NAME=
declare     DSBLIB_SERVICE_INDEX=

# dsblib_set_container_space() output variables:
declare     DSBLIB_MOUNTS_CONTAINER=
declare -A  DSBLIB_MOUNTS_MAP=()
declare -Al DSBLIB_MOUNTS_RW_MAP=()

#############################
#
#   COMMON HELPER FUNCTIONS
#
#############################

# Usage: dsblib_trim <some_string>
# Output variable: DSBLIB_RESULT - trimmed string
function dsblib_trim()
{
    local mystr="$1"
    mystr="${mystr#"${mystr%%[![:space:]]*}"}"
    DSBLIB_RESULT="${mystr%"${mystr##*[![:space:]]}"}"
}

# Usage: dsblib_exec <some_command> ...<args>
function dsblib_exec()
{
    # NOTE: DO NOT ECHO TO STDOUT !!! 

    local mycaller="${FUNCNAME[1]}: ${FUNCNAME[0]}: "
    if [ "${FUNCNAME[1]}" = "main" -o "${FUNCNAME[1]}" = "source" ]; then
        mycaller=
    fi

    if [ -z "$*" ]; then
        if [ -z "$mycaller" ]; then
            mycaller="dsblib_exec: "
        fi
        dsblib_error_exit "${DSBLIB_BINCMD}: ${mycaller}empty command"
    fi

    "$@"
    local myrc="$?"

    if [ "$myrc" -ne 0 ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: ${mycaller}last command:" "$@" \
                          "\n${DSBLIB_BINCMD}: nonzero exit status (${myrc}) of the last command executed"
    fi
}

# Usage: dsblib_escape_for_regexp <some_string>
# Output variable: DSBLIB_RESULT - escaped string
function dsblib_escape_for_regexp()
{
    DSBLIB_RESULT=
    local mystr="$1"
    while [ "${#mystr}" != 0 ]; do
        local mychar="${mystr:0:1}"
        mystr="${mystr:1}"
        case "$mychar" in
            '[' | ']' | '(' | ')' | '{' | '}' | '*' | '+' | '.' | '^' | '$' | '?' | '\' )
                DSBLIB_RESULT="${DSBLIB_RESULT}\\${mychar}" ;;
            * ) DSBLIB_RESULT="${DSBLIB_RESULT}${mychar}"   ;;
        esac
    done
}

# Usage: dsblib_escape_for_golang <some_string>
# Output variable: DSBLIB_RESULT - escaped string
function dsblib_escape_for_golang()
{
    DSBLIB_RESULT=
    local mystr="$1"
    while [ "${#mystr}" != 0 ]; do
        local mychar="${mystr:0:1}"
        mystr="${mystr:1}"
        case "$mychar" in
            '"' | '\' )
                DSBLIB_RESULT="${DSBLIB_RESULT}\\${mychar}" ;;
            * ) DSBLIB_RESULT="${DSBLIB_RESULT}${mychar}"   ;;
        esac
    done
}

# Usage: if dsblib_stdout_includes <line> <command> ... args ; then ... ; fi
function dsblib_stdout_includes()
{
    local -r myneedle="$1"
    shift
    local    myline=
    local -a mystdout=()
    dsblib_exec mapfile -t mystdout < <( "$@" )
    for myline in "${mystdout[@]}" ; do
        if [ "$myline" = "$myneedle" ]; then
            return 0
        fi
    done
    return 1
}

function dsblib_select_busybox_image()
{
    if [ -n "$DSBLIB_BUSYBOX_IMAGE" ]; then
        return 0
    fi

    local   -a mylist=()
    mapfile -t mylist < <( docker images explore "--filter=reference=busybox:*" --format='{{.Repository}}:{{.Tag}}' )
    if [ "${#mylist[@]}" != 0 ]; then
        dsblib_trim "${mylist[0]}"
        DSBLIB_BUSYBOX_IMAGE="$DSBLIB_RESULT"
    fi

    if [ -n "$DSBLIB_BUSYBOX_IMAGE" ]; then
        return 0
    fi

    dsblib_error_exit "No access to docker 'busybox' image. Please run 'docker pull busybox:latest'."
}


############################
#
#   PRIVATE FUNCTIONS
#
############################

# Usage: dsblib_get_scale_options
# Input variables:  DSBLIB_REPLICAS
# Output variables: DSBLIB_ARRAY_RESULT
function dsblib_get_scale_options()
{
    DSBLIB_ARRAY_RESULT=()
    local myname=
    for myname in "${!DSBLIB_REPLICAS[@]}" ; do
        if [ "$1" = "--short" -a "${DSBLIB_REPLICAS[$myname]}" = 1 ]; then
            continue
        fi
        DSBLIB_ARRAY_RESULT=( "${DSBLIB_ARRAY_RESULT[@]}" --scale "${myname}=${DSBLIB_REPLICAS[$myname]}" )
    done
}

# Usage: dsblib_parse_service_arg <service_name>[:<container_index>] | @<service_alias>[:<container_index>]
# Output variables: 
#   DSBLIB_SERVICE_NAME
#   DSBLIB_SERVICE_INDEX (empty string or number)
#   DSBLIB_SERVICE_VAR   (may be empty)
function dsblib_parse_service_arg()
{
    DSBLIB_SERVICE_NAME=
    DSBLIB_SERVICE_INDEX=
    DSBLIB_SERVICE_VAR=

    dsb_set_box 1>&2  # never use STDOUT

    local myservice="$1"
    if [ "${myservice%:*}" != "$myservice" ]; then
        DSBLIB_SERVICE_INDEX="${myservice##*:}"
        myservice="${myservice%:*}"
        local -r mypattern='^[1-9][0-9]*$'
        if [[ ! "$DSBLIB_SERVICE_INDEX" =~ $mypattern ]]; then
            dsblib_error_exit "${DSBLIB_BINCMD}: Wrong container index: $DSBLIB_SERVICE_INDEX"
        fi
    fi

    if [ "${myservice:0:1}" = "@" ]; then
        local -u myupper="${myservice:1}"
        if [ -z "$myupper" ]; then
            dsblib_error_exit "${DSBLIB_BINCMD}: Wrong service alias: $myservice"
        elif [ "$myservice" != "@$myupper" ]; then
            dsblib_error_exit "${DSBLIB_BINCMD}: Wrong service alias: $myservice - must be uppercase"
        fi

        DSBLIB_SERVICE_VAR="DSB_SERVICE_$myupper"
        myservice="${!DSBLIB_SERVICE_VAR}"
        if [ -z "$myservice" ]; then
            myservice="$DSB_SERVICE"
            if [ -z "$myservice" ]; then
                local -l mylower="$myupper"
                myservice="$mylower"
            fi
        fi
    fi

    DSBLIB_SERVICE_NAME="$myservice"
}

# Usage: if dsblib_get_docker_volume <compose_named_volume> ; then
#           ... handle Docker volume name in $DSBLIB_RESULT
#        fi
# Output variable: DSBLIB_RESULT - Docker volume name or empty string
# Return: 0 - if volume found
#         1 - if not found
function dsblib_get_docker_volume()
{
    dsblib_escape_for_golang "$1"
    local -r myvol="$DSBLIB_RESULT"

    local   -a myvolumes=()
    dsblib_exec mapfile -t myvolumes < <( docker volume ls --filter "label=com.docker.compose.project=${DSBLIB_LOWER_PROJECT}" --format '{{.Name}}' )
    DSBLIB_RESULT=
    if [ "${#myvolumes[@]}" != 0 ]; then
        dsblib_trim "$(
            docker volume inspect "${myvolumes[@]}" \
            --format '{{ $x := index .Labels "com.docker.compose.volume" }}{{if eq $x "'"$myvol"'"}}{{.Name}}{{end}}'
        )"
        if [ -n "$DSBLIB_RESULT" ]; then
            return 0
        fi
    fi
    return 1
}

# Usage: if dsblib_get_volume_containers <docker_named_volume> ; then
#           ... handle "${DSBLIB_ARRAY_RESULT[@]}"
#        fi
function dsblib_get_volume_containers()
{
    DSBLIB_ARRAY_RESULT=()
    local -a mylist=()
    dsblib_exec mapfile -t mylist < <( docker container ls --all --format '{{.ID}}' )
    if [ "${#mylist[@]}" != 0 ]; then
        local -a mylist2=()
        dsblib_escape_for_golang "$1"
        dsblib_exec mapfile -t mylist2 < <( 
            docker inspect "${mylist[@]}" --format \
            '{{ $id := .Id }}{{ if ne .State.Status "exited" }}{{ range .Mounts }}{{if eq .Type "volume"}}{{if eq .Name "'"$DSBLIB_RESULT"'"}}{{ print $id }}{{end}}{{end}}{{end}}{{end}}'
        )
        if [ "${#mylist2[@]}" != 0 ]; then
            local -A myids=()
            local    myline=
            for myline in "${mylist2[@]}" ; do
                dsblib_trim "$myline"
                if [ -n "$DSBLIB_RESULT" ]; then
                    myids["$DSBLIB_RESULT"]=1
                fi
            done

            DSBLIB_ARRAY_RESULT=( "${!myids[@]}" )
            if [ "${#DSBLIB_ARRAY_RESULT[@]}" != 0 ]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Usage: if dsblib_make_sure_service_name <service_name> [ --check ] ; then ... ; fi
# Input variables: DSBLIB_PROJECT_SERVICES
#                  DSBLIB_SERVICE_NAME & DSBLIB_SERVICE_VAR (for message only)
function dsblib_make_sure_service_name()
{
    dsblib_set_services
    local myname=
    for myname in "${DSBLIB_PROJECT_SERVICES[@]}" ; do
        if [ "$myname" = "$1" ]; then
            return 0
        fi
    done
    if [ "$2" != "--check" ]; then
        if [ "$1" = "$DSBLIB_SERVICE_NAME" -a -n "$DSBLIB_SERVICE_VAR" ]; then
            dsblib_error_exit "No such service: '${1}'\nDefine the proper name via $DSBLIB_SERVICE_VAR variable"
        fi
        dsblib_error_exit "No such service: '$1'"
    fi
    return 1
}

# Usage: dsblib_set_services
# Input & Output variable: DSBLIB_PROJECT_SERVICES
function dsblib_set_services()
{
    if [ "${#DSBLIB_PROJECT_SERVICES[@]}" = 0 ]; then
        local   -a myservices=()
        mapfile -t myservices < <( dsb_docker_compose config --services )

        local myname=
        for myname in "${myservices[@]}" ; do
            if [ -n "$myname" ]; then
                DSBLIB_PROJECT_SERVICES=( "${DSBLIB_PROJECT_SERVICES[@]}" "$myname" )
            fi
        done
    fi
}

# Usage: if dsblib_make_sure_no_containers [ SERVICE ] ; then ... ; fi
# Returns:  0 if there are no project/service containers
#           1 if there is any project/service container
function dsblib_make_sure_no_containers()
{
    dsb_set_box

    local -r myservice="$1"
    local -a myopts=( --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
    if [ -n "$myservice" ]; then
        myopts=( "${myopts[@]}" --filter "label=com.docker.compose.service=$myservice" )
    fi

    local -a mylist
    mapfile -t mylist < <( docker container ls --all --format='{{.Names}}' "${myopts[@]}" )
    if [ "${#mylist[@]}" != 0 ]; then
        return 1
    fi
    return 0
}

# Usage: if dsblib_make_sure_service_stopped <service_name> ; then ... ; fi
# Input variable: DSBLIB_LOWER_PROJECT
# Returns:  0 if service is stopped
#           1 if there are running containers with status != DSBLIB_STATUS_EXITED
function dsblib_make_sure_service_stopped()
{
    local -r myservice="$1"

    dsb_set_box

    local    mystate=
    local -a mylist
    mapfile -t mylist < <( 
        docker container ls --all --format='{{.State}}' \
            --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" \
            --filter "label=com.docker.compose.service=$myservice"
    )
    for mystate in "${mylist[@]}" ; do
        if [ "$mystate" != "$DSBLIB_STATUS_EXITED" ]; then
            return 1
        fi
    done
    return 0
}

# Usage: dsblib_get_service_replicas ( <service_name> | - ) [ --skip-orphans ]
# Input variable:   DSBLIB_LOWER_PROJECT
# Output variables: 
#   DSBLIB_RESULT       - replicas number
#   DSBLIB_ARRAY_RESULT - "--scale" options list
#   DSBLIB_REPLICAS     - service to replicas map
function dsblib_get_service_replicas()
{
    DSBLIB_RESULT=0
    DSBLIB_REPLICAS=()

    if [ -z "$DSBLIB_LOWER_PROJECT" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsblib_get_service_replicas: Empty DSBLIB_LOWER_PROJECT variable!"
    fi

    local -r  myservice="$1"
    local -r  mymode="$2"
    local -r  myoptskip="--skip-orphans"
    local     myname=
    local -a  mylist

    mapfile -t mylist < <( docker container ls --all --format='{{.Names}}' --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
    for myname in "${mylist[@]}" ; do
        local mykey="${myname#$DSBLIB_LOWER_PROJECT}"
        mykey="${mykey:1}"

        local mylng="${#mykey}"
        local mypos="$(( mylng - 1 ))"
        local mychar="${mykey:$mypos:1}"
        while [ "$mypos" -ge 0 -a "$mychar" != "-" -a "$mychar" != "_" ]; do
            (( --mypos ))
            mychar="${mykey:$mypos:1}"
        done
        mykey="${mykey:0:$mypos}"

        if (( (mylng - mypos) > 5 )) && [ "$mychar" = "_" -a "${mykey%_run}" != "$mykey" ]; then
            continue  # skip 'docker-compose run' containers
        fi

        if [ -n "$mykey" ]; then
            if [ "$mymode" = "$myoptskip" ] && ! dsblib_make_sure_service_name "$mykey" --check ; then
                continue
            elif [ -n "$myservice" -a "$myservice" != "-" -a "$myservice" = "$mykey" ]; then
                (( ++ DSBLIB_RESULT ))
            fi
            local myreplicas="${DSBLIB_REPLICAS[$mykey]}"
            if [ -n "$myreplicas" ]; then
                (( ++ myreplicas ))
                DSBLIB_REPLICAS[$mykey]="$myreplicas"
            else
                DSBLIB_REPLICAS[$mykey]=1
            fi
        fi
    done
}

# Usage: dsblib_set_container_space <container_id> <host_path>
# Output varible:
#   DSBLIB_RESULT           - path in the container
#   DSBLIB_MOUNTS_MAP
#   DSBLIB_MOUNTS_RW_MAP
#   DSBLIB_MOUNTS_CONTAINER - container_id for DSBLIB_MOUNTS_MAP & DSBLIB_MOUNTS_RW_MAP
# Returns: 0 - if nonempty DSBLIB_RESULT
#          1 - if empty    DSBLIB_RESULT (host path is not available in the container)
function dsblib_set_container_space()
{
    DSBLIB_RESULT=
    local -r myid="$1"
    local -r mypath="$2"
    local    mysrc=
    local    mydest=
    local    myrw=
    local    mykey=

    if [ -z "$myid" -o -z "$mypath" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsblib_set_container_space: WRONG USAGE: ${@}"
    fi

    if [ "$DSBLIB_MOUNTS_CONTAINER" != "$myid" ]; then
        DSBLIB_MOUNTS_CONTAINER="$myid"
        DSBLIB_MOUNTS_MAP=()
        DSBLIB_MOUNTS_RW_MAP=()

        local -r myEOL=$'\n'
        local -r myTAB=$'\t'
        local -a mylist
        mapfile -t  mylist < <( docker container inspect "$DSBLIB_MOUNTS_CONTAINER" --format "{{range .Mounts}}{{if eq .Type \"bind\" }}{{.Source}}${myTAB}{{.Destination}}${myTAB}{{.RW}}${myEOL}{{end}}{{end}}" )
        local myline=
        for myline in "${mylist[@]}" ; do
            if [ -z "$myline" ]; then continue; fi
            mysrc="${myline%%${myTAB}*}"
            myline="${myline#*${myTAB}}"
            mydest="${myline%%${myTAB}*}"
            myrw="${myline#*${myTAB}}"

            local -A myDelete=()
            for mykey in "${!DSBLIB_MOUNTS_MAP[@]}" ; do
                if [ "${DSBLIB_MOUNTS_RW_MAP[$mykey]}" != "$myrw" -o "$mykey" = "$mysrc" ]; then
                    continue
                elif [ "${mykey#$mysrc/}" != "$mykey" ]; then
                    myDelete[$mykey]=1
                elif [ "${mysrc#$mykey/}" != "$mysrc" ]; then
                    mysrc=
                    break
                fi
            done

            for mykey in "${!myDelete[@]}" ; do
                unset DSBLIB_MOUNTS_MAP[$mykey]
                unset DSBLIB_MOUNTS_RW_MAP[$mykey]
            done

            if [ -n "$mysrc" ]; then
                DSBLIB_MOUNTS_MAP[$mysrc]="$mydest"
                DSBLIB_MOUNTS_RW_MAP[$mysrc]="$myrw"
            fi
        done        
    fi

    local mybase=
    for mysrc in "${!DSBLIB_MOUNTS_MAP[@]}" ; do
        if [ "${DSBLIB_MOUNTS_RW_MAP[$mysrc]}" = true ] && [ "$mypath" = "$mysrc" -o "${mypath#$mysrc/}" != "$mypath" ]; then
            mybase="$mysrc"
            break
        fi
    done
    if [ -z "$mybase" ]; then
        for mysrc in "${!DSBLIB_MOUNTS_MAP[@]}" ; do
            if [ "${DSBLIB_MOUNTS_RW_MAP[$mysrc]}" != true ] && [ "$mypath" = "$mysrc" -o "${mypath#$mysrc/}" != "$mypath" ]; then
                mybase="$mysrc"
                break
            fi
        done
    fi

    if [ -z "$mybase" ]; then
        return 1
    fi
    if [ "${mypath#$mybase/}" != "$mypath" ]; then
        DSBLIB_RESULT="${DSBLIB_MOUNTS_MAP[$mybase]}/${mypath#$mybase/}"
        return 0
    fi
    if [ "$mypath" = "$mybase" ]; then
        DSBLIB_RESULT="${DSBLIB_MOUNTS_MAP[$mybase]}"
        return 0
    fi
    return 1
}

# NOTE: This algorithm is not perfect, but it is quite sufficient for real use cases.
# The main purpose of this algorithm is to be able:
# - to execute a command with full path file-arguments;
# - to execute a command when the current working directory is outside the mounted space,
#   but the real full path of the file-arguments falls within this space.
# The need for this may arise when integrating dsb... commands with the IDE. 
#
# Usage: dsblib_resolve_args ...<args>
# Input variables:
#   DSBLIB_RESOLVE_EXTS
#   DSBLIB_MOUNTS_MAP
#   DSBLIB_MOUNTS_RW_MAP
#
# Output variable:
#   DSBLIB_RESOLVED_ARGS
#
function dsblib_resolve_args()
{
    DSBLIB_RESOLVED_ARGS=( "$@" )

    if [ "$#" = 0 ]; then
        return 0
    fi

    pushd "$PWD" > /dev/null
    dsblib_exec cd "$DSB_WORKDIR"

    local -r myLeftDels='[ =:,;><"'"'"'`()]'
    local -r myRightDels='[ =:,;><"'"'"'`()/]'
    local -r mySysDirs='^/(dsbhome|dsbutils|dsbspace|dev|bin|etc|lib|logs|proc|run|sbin|sys|tmp|usr)/'
    local    myPattern=
    local    myName=
    local    myTemp=
    local    mySrc=
    local    mySrcRE=
    local    myDest=

    local -r mycount="${#DSBLIB_RESOLVED_ARGS[@]}"
    local    myind=0    
    while (( myind < mycount )) ; do
        local myArg="${DSBLIB_RESOLVED_ARGS[$myind]}"

        case "$myArg" in
            '' | '-' | '--' | '-l' | '-c' | '-o' | 'sh' | 'bash' ) (( ++myind )) ; continue ;;
        esac

        if [ "${myArg#dsbnop:}" != "$myArg" ]; then
            DSBLIB_RESOLVED_ARGS[$myind]="${myArg#dsbnop:}"   # transparent
            (( ++myind ))
            continue
        fi

        # Resolve relative path to fullpath for file extentions from DSBLIB_RESOLVE_EXTS ...
        if [ "${#DSBLIB_RESOLVE_EXTS[@]}" != 0 ] && [[ ! "$myArg" =~ $myLeftDels ]]; then

            # ATTENTION: skipping /tmp/... files is essential for PhpStorm validation script /tmp/ide-phpinfo.php
            # See also bin/dsbphp
            if [ "${myArg#/tmp/ide-}" != "$myArg" ]; then
                (( ++myind ))
                continue
            fi

            myName="${myArg##*/}"
            myTemp="${myName##*\.}"
            if [ -n "$myTemp" -a "$myTemp" != "$myName" ]; then
                local myExt=
                for myExt in "${DSBLIB_RESOLVE_EXTS[@]}" ; do
                    if [ "$myTemp" = "$myExt" ]; then
                        myTemp="$( dsblib_gnu_readlink -f "$myArg" )"
                        if [ -n "$myTemp" ]; then
                            # Сheck to be inside the Service Space for files listed via 'dsb_resolve_files' function
                            if [[ ! "$myTemp" =~ $mySysDirs ]] && [ -z "$HOME" -o "${myTemp#$HOME/}" != "$myTemp" ]; then
                                if ! dsblib_set_container_space "$DSB_CONTAINER_ID" "$myTemp" ; then
                                    dsblib_error_exit "Cannot map ${DSBLIB_RESOLVED_ARGS[$myind]} to the container"
                                fi
                                DSBLIB_RESOLVED_ARGS[$myind]="$DSBLIB_RESULT"
                                (( ++myind ))
                                continue 2  # CONTINUE MAIN LOOP
                            fi
                            myArg="$myTemp"
                        fi
                        break
                    fi
                done
            fi
        fi

        ### MAP SUBSTRINGS ...

        # At first handle ReadWrite bind mounts ...
        for mySrc in "${!DSBLIB_MOUNTS_MAP[@]}" ; do

            if [ "${DSBLIB_MOUNTS_RW_MAP[$mySrc]}" != true ] || [[ "$mySrc" =~ $mySysDirs ]]; then
                continue
            fi

            myDest=${DSBLIB_MOUNTS_MAP[$mySrc]}

            if [ "$myArg" = "$mySrc" ]; then
                myArg="$myDest"
                break
            fi

            dsblib_escape_for_regexp "$mySrc"
            mySrcRE="$DSBLIB_RESULT"

            myPattern="$myLeftDels${mySrcRE}$myRightDels"
            if [[ "$myArg" =~ $myPattern ]]; then
                myTemp="${BASH_REMATCH[0]}"
                myArg="${myArg//$myTemp/${myTemp:0:1}$myDest${myTemp:$(( ${#myTemp} - 1 )):1}}"
            fi

            myPattern="^${mySrcRE}$myRightDels"
            if [[ "$myArg" =~ $myPattern ]]; then
                myTemp="${BASH_REMATCH[0]}"
                myArg="${myArg/#$myTemp/$myDest${myTemp:$(( ${#myTemp} - 1 )):1}}"
            fi

            myPattern="$myLeftDels${mySrcRE}\$"
            if [[ "$myArg" =~ $myPattern ]]; then
                myTemp="${BASH_REMATCH[0]}"
                myArg="${myArg/%$myTemp/${myTemp:0:1}$myDest}"
            fi
        done

        # Next handle ReadOnly bind mounts ...
        for mySrc in "${!DSBLIB_MOUNTS_MAP[@]}" ; do

            if [ "${DSBLIB_MOUNTS_RW_MAP[$mySrc]}" = true ] || [[ "$mySrc" =~ $mySysDirs ]]; then
                continue
            fi

            myDest=${DSBLIB_MOUNTS_MAP[$mySrc]}

            if [ "$myArg" = "$mySrc" ]; then
                myArg="$myDest"
                break
            fi

            myDest=${DSBLIB_MOUNTS_MAP[$mySrc]}

            dsblib_escape_for_regexp "$mySrc"
            mySrcRE="$DSBLIB_RESULT"

            myPattern="$myLeftDels${mySrcRE}$myRightDels"
            if [[ "$myArg" =~ $myPattern ]]; then
                myTemp="${BASH_REMATCH[0]}"
                myArg="${myArg//$myTemp/${myTemp:0:1}$myDest${myTemp:$(( ${#myTemp} - 1 )):1}}"
            fi

            myPattern="^${mySrcRE}$myRightDels"
            if [[ "$myArg" =~ $myPattern ]]; then
                myTemp="${BASH_REMATCH[0]}"
                myArg="${myArg/#$myTemp/$myDest${myTemp:$(( ${#myTemp} - 1 )):1}}"
            fi

            myPattern="$myLeftDels${mySrcRE}\$"
            if [[ "$myArg" =~ $myPattern ]]; then
                myTemp="${BASH_REMATCH[0]}"
                myArg="${myArg/%$myTemp/${myTemp:0:1}$myDest}"
            fi
        done

        DSBLIB_RESOLVED_ARGS[$myind]="$myArg"
        (( ++myind ))
    done
    popd > /dev/null
}

# Usage: dsblib_run_command <service> <UID:GID> <command> [ ...<parameters> ]
function dsblib_run_command()
{
    dsb_get_container_id "$1"  # set DSB_CONTAINER_ID & DSB_CONTAINER_SERVICE
    local -r myExecUser="$2"
    shift 2

    local myUmask=
    local myTemp="${myExecUser%%:*}"
    if [ "$myTemp" = "0" -o "$myTemp" = "root" ]; then
        if [ -n "$DSB_UMASK_ROOT" ]; then
            myUmask="$DSB_UMASK_ROOT"
        fi
    else
        if [ -n "$DSB_UMASK_SH" ]; then
            myUmask="$DSB_UMASK_SH"
        fi
    fi    
    if [ -z "$myUmask" ]; then
        myUmask="$( umask )"
        # if dsblib_is_prod_mode ; then
        #     myUmask="${myUmask:0:$(( ${#myUmask} == 0 ? 0 : ${#myUmask} - 1 ))}7" # chmod o-rwx ...
        # fi
    fi

    local myCWD="-"
    if dsblib_set_container_space "$DSB_CONTAINER_ID" "$DSB_WORKDIR" ; then
        # the current working directory is available in the container
        myCWD="$DSBLIB_RESULT"
    fi

    # NOTE: docker exec -it ... combining STDERR and STDOUT streams.
    # So, we use '-it' only in real interactive mode or if there are no redirects.
    local myterm=''
    if  [ -t 0 -a -t 1 -a -t 2 ] || [ "$1" = "-" -a "$2" = "-l" -a "$3" = "-c" -a "$#" -le 5 ]; then
        myterm=t
    fi

    local -a myEnv=()
    local    myVar=
    for myVar in "${DSBLIB_RUN_ENV[@]}" ; do
        if [ "${!myVar-${DSBLIB_NOTSET}}" != "$DSBLIB_NOTSET" ]; then
            myEnv=( "${myEnv[@]}" --env "${myVar}=${!myVar}" )
        fi
    done

    dsblib_resolve_args "$@"
    docker exec "-i${myterm}" "${myEnv[@]}" "${DSBLIB_DOCKER_EXEC_ARGS[@]}" --user "$myExecUser" "$DSB_CONTAINER_ID" \
        sh /dsbutils/exec.sh "$myExecUser" "${TERM:--}" "${myUmask:--}" "$myCWD" "${DSBLIB_RESOLVED_ARGS[@]}"
}

#####################################
#
#   PRIVATE: .dsb directory helpers
#
#####################################

# Usage: dsblib_check_compose_version
# See also: https://docs.docker.com/engine/reference/commandline/version/
function dsblib_check_compose_version()
{
    if [ -n "$DSBLIB_COMPOSE_VERSION_MAJOR" ]; then
        return 0
    fi

    local myver=
    local myrest=

    local -r myMinMajor=1
    local -r myMinMinor=24

    DSBLIB_COMPOSE_VERSION_MAJOR=0
    DSBLIB_COMPOSE_VERSION_MINOR=0
    DSBLIB_COMPOSE_VERSION_PATCH=0

    local -l myline="$( docker-compose -v )"
    # myline examples:
    # docker-compose version 1.26.2, build eefe0d31
    # docker compose version v2.2.3

    myrest="${myline#docker-compose version }"
    if [ "$myrest" = "$myline" ]; then
        myrest="${myline#docker compose version v}"
    fi
    if [ "$myrest" = "$myline" ]; then
        dsblib_error_exit "Unsupported docker-compose version: $myline"
    fi
    myver="${myrest%%,*}"
    myver="${myver%%-*}" # truncate possible pre-release

    if [ -n "$myver" ]; then
        DSBLIB_COMPOSE_VERSION_MAJOR="${myver%%.*}"
        if [ "$myver" != "$DSBLIB_COMPOSE_VERSION_MAJOR" ]; then
            myver="${myver#${DSBLIB_COMPOSE_VERSION_MAJOR}.}"
            DSBLIB_COMPOSE_VERSION_MINOR="${myver%%.*}"
            if [ "$myver" != "$DSBLIB_COMPOSE_VERSION_MINOR" ]; then
                DSBLIB_COMPOSE_VERSION_PATCH="${myver#${DSBLIB_COMPOSE_VERSION_MINOR}.}"
            fi
        fi
        local mypattern='^[0-9]+$'
        if [[ "$DSBLIB_COMPOSE_VERSION_MAJOR" =~ $mypattern ]] && \
           [[ "$DSBLIB_COMPOSE_VERSION_MINOR" =~ $mypattern ]] && \
           [[ "$DSBLIB_COMPOSE_VERSION_PATCH" =~ $mypattern ]]
        then
            if [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -gt "$myMinMajor" ] || \
               [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -eq "$myMinMajor" -a "$DSBLIB_COMPOSE_VERSION_MINOR" -ge "$myMinMinor" ]
            then
                return 0
            fi
        fi
    fi
    echo "$myline" 1>&2
    dsblib_error_exit "Please upgrade docker-compose to version >= $myMinMajor.$myMinMinor.0"
}

# Usage: if dsblib_is_prod_mode ; then ... ; fi
function dsblib_is_prod_mode()
{
    local -l myval="$DSB_PROD_MODE"
    if [ "$myval" = "true" ]; then
        return 0
    fi
    return 1
}

# Usage: if dsblib_is_prod_mode ; then ... ; fi
function dsblib_is_home_volumes()
{
    local -l myval="$DSB_HOME_VOLUMES"
    if [ "$myval" = "true" ]; then
        return 0
    fi
    return 1
}


# Usage: if dsblib_empty_dir <directory_path> ; then ... ; else ... ; fi
function dsblib_empty_dir()
{
    local mydir="$1"
    local myrc=0
    pushd "$PWD" > /dev/null 

    dsblib_exec cd "$mydir"
    local    mycount=0
    local -a myList
    mapfile -t myList < <( ls -a1 )
    for myLine in "${myList[@]}" ; do
        if [ -n "$myLine" -a "$myLine" != "." -a "$myLine" != ".." ]; then
            popd > /dev/null
            return 1
        fi
    done
    popd > /dev/null
    return 0
}

# Usage: dsblib_clean_dir <directory_path> <mode>
function dsblib_chmod_dir()
{
    local mydir="$1"
    local mymod="$2"
    if [ ! -d "$1" ]; then
        # echo "$mydir directory is absent"
        return 0
    fi
    mydir="$( cd -- "$mydir"; pwd -P )"
    if chmod "$mymod" "$mydir" &>/dev/null ; then
        return 0
    fi

    if [ "$DSB_UID" != 0 ]; then
        if ! hash sudo 2>/dev/null ; then
            dsblib_yellow_message "Command 'sudo' not found - couldn't execute: chmod $mymod $mydir"
            return 1
        fi

        echo -e "sudo chmod $mymod $mydir ... "
        if sudo chmod "$mymod" "$mydir" ; then
            return 0
        fi
    fi

    dsblib_red_message "FAILURE: chmod $mymod $mydir"
    return 1
}

# Usage: dsblib_clean_dir <directory_path>
function dsblib_clean_dir()
{
    local mydir="$1"
    if [ ! -d "$mydir" ]; then
        # echo "$mydir directory is absent"
        return 0
    fi

    mydir="$( cd -- "$mydir"; pwd -P )"
    echo -e -n "Cleaning $mydir ... "

    local    myname=
    local -a mylist=()
    mapfile -t  mylist < <( find "$mydir" -mindepth 1 -maxdepth 1 )
    for myname in "${mylist[@]}" ; do
        rm -fr "$myname" &>/dev/null || :
    done

    if dsblib_empty_dir "$mydir" ; then
        dsblib_green_message done
        return 0
    fi

    if ! hash sudo 2>/dev/null ; then
        dsblib_yellow_message "Command 'sudo' not found - couldn't clean '$mydir' directory"
        return 1
    fi

    if [ "$DSB_UID" != 0 ]; then
        echo -e -n "via sudo ... "
        local    myname=
        local -a mylist=()
        mapfile -t  mylist < <( find "$mydir" -mindepth 1 -maxdepth 1 )
        for myname in "${mylist[@]}" ; do
            sudo rm -fr "$myname" &>/dev/null || :
        done

        if dsblib_empty_dir "$mydir" ; then
            dsblib_green_message done
            return 0
        fi
    fi

    dsblib_red_message "FAILURE: Couldn't clean '$mydir' directory"
    return 1
}

# Usage: if dsblib_mkdir_or_dev_mode <directory_path> ; then ... ; fi
function dsblib_mkdir_or_dev_mode()
{
    local mydir="$1"
    if [ -d "$mydir" ]; then
        if dsblib_is_prod_mode ; then
            return 1
        fi
        return 0
    fi
    dsblib_exec mkdir -p "$mydir"
    return 0
}

# Usage: dsblib_init_service <service_name>
function dsblib_init_service()
{
    local myname="$1"
    if [ -z "$myname" ]; then
        dsblib_error_exit "dsblib_init_service: WRONG USAGE: ${@}"
    fi

    pushd "$PWD" > /dev/null
    dsblib_exec cd "$DSB_BOX"

    local  mydir="storage/$myname"
    if dsblib_mkdir_or_dev_mode  "$mydir" ; then
        dsblib_chmod_dir        "$mydir" "a=rwx"
    fi

    mydir="home/$myname"
    if dsblib_mkdir_or_dev_mode  "$mydir" ; then
        dsblib_chmod_dir        "$mydir" "u=rwx,go=rx"
    fi

    mydir="logs/$myname"
    if dsblib_mkdir_or_dev_mode "$mydir" ; then
        dsblib_chmod_dir        "$mydir" "a=rwx"
        dsblib_clean_dir        "$mydir" > /dev/null
    fi
    
    popd > /dev/null
}

############################
#
#   PUBLIC FUNCTIONS
#
############################

# Usage: dsb_set_single_box [ --check ]
function dsb_set_single_box()
{
    local    mydir=
    local    mytmp=
    local    mystr=
    local    myline=
    local -a mylist
    mapfile -t mylist < <( docker container ps --format "{{.State }}|{{.Labels}}" )
    for myline in "${mylist[@]}" ; do
        mystr="${myline%%|*}"
        if [ "$mystr" = "running" ]; then
            mystr="${myline#*|}"
            mytmp="${mystr#*com\.docker\.compose\.project\.working_dir=}"
            if [ "$mytmp" != "$mystr" ]; then
                mystr="${mytmp%%,*}"
                mytmp="${mystr%/compose}"
                if [ "${mytmp%/.dsb}" != "$mytmp" ]; then
                    if [ -z "$mydir" ]; then
                        mydir="$mytmp"
                    elif [ "$mytmp" != "$mydir" ]; then
                        if [ "$1" = "--check" ]; then
                            return 1
                        fi
                        dsblib_yellow_message "Several Dsb projects are running now."
                        dsblib_error_exit "Only one project should be active for this command to execute"
                    fi
                fi
            fi
        fi
    done

    if [ -z "$mydir" ] || [ ! -d "$mydir" ]; then
        if [ "$1" = "--check" ]; then
            return 1
        fi
        dsblib_error_exit "Active dsb project not found"
    fi

    dsb_set_box --dir "$mydir"
    return 0
}

# Usage: dsb_set_box [ --check ] [ --dir <current_dir> ]
function dsb_set_box()
{
    if [ -n "$DSB_BOX" ]; then
        return 0
    fi

    local -r mypattern='^[a-zA-Z0-9_\-]*$'
    local    myboxdir=
    local    mydir="$DSB_WORKDIR"
    local    mycheck=

    local    myopt=
    while [ "$#" != 0 ]; do
        case "$1" in
            "--check" )
                mycheck=1
                shift
                ;;
            "--dir" )
                if [ -z "$2" ] || [ ! -d "$2" ]; then
                    dsblib_error_exit "${DSBLIB_BINCMD}: dsb_set_box: wrong --dir option: ${2}"
                fi
                mydir="$( cd $2 ; pwd -P )"
                shift 2
                ;;
            * )
                dsblib_error_exit "${DSBLIB_BINCMD}: dsb_set_box: wrong argument: ${1}"
                ;;
        esac
    done

    local -r mysrc="$mydir"

    while [ -n "$mydir" ]; do
        myboxdir="$mydir/.dsb"
        if [ -d "$myboxdir" ]; then
            declare -gr DSB_ROOT="$mydir"
            declare -gr DSB_BOX="$DSB_ROOT/.dsb"
            declare -g  DSB_SPACE="$DSB_ROOT"
            break
        fi

        if [ "$mydir" = "/" ]; then
            break;
        fi

        mydir="${mydir%/*}"
        if [ -z "$mydir" ]; then
            mydir="/"
        fi
    done

    if [ -z "$DSB_BOX" ]; then
        if [ "$mycheck" != 1 ]; then
            dsblib_error_exit "Directory '.dsb' not found for the directory '${mysrc}' or any parent up to '/'\n"
        fi
        return 1
    fi

    # .dsb is found ...

    declare -gr DSB_COMPOSE="$DSB_BOX/compose"

    if [ ! -d "$DSB_COMPOSE" -a "$1" != check ]; then
        dsblib_error_exit "Directory '${DSB_COMPOSE}' not found.\nPlease configure the project!\n"
    fi

    # import Dsb related global variables:    
    local -r myDotFile="$DSB_COMPOSE/$DSBLIB_DSBENV"
    if [ -f "$myDotFile" ]; then
        pushd "$PWD" > /dev/null
        set -ea     # export each variable that is created or modified in the .dsbenv

        cd "$DSB_COMPOSE" 1>&2
        . "$myDotFile"    1>&2

        set +ea
        popd > /dev/null
        dsblib_reset_options # restore important options
    fi

    # Some validation...

    if   [ -z "$DSB_PROJECT_ID" ]; then
        dsblib_error_exit "DSB_PROJECT_ID variable is not defined"
    elif [[ ! "$DSB_PROJECT_ID" =~ $mypattern  ]]; then
        dsblib_error_exit "DSB_PROJECT_ID: the value '$DSB_PROJECT_ID' is not allowed"
    elif [ -z "$COMPOSE_FILE" ]; then
        dsblib_error_exit "COMPOSE_FILE variable is not defined"
    elif [ "$COMPOSE_FILE" != "${COMPOSE_FILE%:}" ]; then
        dsblib_error_exit "COMPOSE_FILE: value '$COMPOSE_FILE' is not allowed"
    elif [ -n "$COMPOSE_PROJECT_NAME" -o "${COMPOSE_PROJECT_NAME-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
        dsblib_error_exit "COMPOSE_PROJECT_NAME variable should not be defined in the $DSBLIB_DSBENV"
    elif [ -n "$DSBLIB_PROJECT_NAME" -o "${DSBLIB_PROJECT_NAME-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
        dsblib_error_exit "DSBLIB_PROJECT_NAME variable should not be defined in the $DSBLIB_DSBENV"
    elif [ -n "$DSBLIB_LOWER_PROJECT" -o "${DSBLIB_LOWER_PROJECT-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
        dsblib_error_exit "DSBLIB_LOWER_PROJECT variable should not be defined in the $DSBLIB_DSBENV"
    elif [ -n "$DSB_HOME_VOLUMES" -a "$DSB_HOME_VOLUMES" != true -a "$DSB_HOME_VOLUMES" != false ]; then
        dsblib_error_exit "DSB_HOME_VOLUMES: the value '$DSB_HOME_VOLUMES' is not allowed"
    elif [ -n "$DSB_PROD_MODE" -a "$DSB_PROD_MODE" != true -a "$DSB_PROD_MODE" != false ]; then
        dsblib_error_exit "DSB_PROD_MODE: the value '$DSB_PROD_MODE' is not allowed"
    fi

    local myvar=
    for   myvar in "${!DSB_SERVICE_@}" ; do
        if [ "$myvar" = "DSB_SERVICE_" ]; then
            dsblib_error_exit "The variable '$myvar' is not allowed"
        fi
        local -u myuppervar="$myvar"
        if [ "$myvar" != "$myuppervar" ] ; then
            dsblib_error_exit "The variable '$myvar' is not allowed - must be uppercase"
        fi
    done

    declare -gr  COMPOSE_FILE
    declare -gr  DSB_PROJECT_ID

    # NOTE: docker-compose v2 doesn't like uppercase letters in project name
    declare -grl DSBLIB_PROJECT_NAME="${DSBLIB_PROJECT_PREFIX}${DSB_PROJECT_ID}"
    declare -grl DSBLIB_LOWER_PROJECT="$DSBLIB_PROJECT_NAME"
    declare -gr  COMPOSE_PROJECT_NAME="$DSBLIB_PROJECT_NAME"

    # export variables for docker-compose
    dsblib_export_env_vars "DSB_" "DSBUSR_" "COMPOSE_" "DOCKER_" 

    return 0
}

# Usage: dsb_get_container_id ( <service_name>[:<container_index>] | @<service_alias>[:<container_index>] ) [ --anystatus ]
#
# Input internal variable:
#   DSBLIB_LAST_SERVICE_ARG
#
# Output variables:
#   DSBLIB_SERVICE_NAME
#   DSBLIB_SERVICE_INDEX
#   DSBLIB_SERVICE_VAR
#   DSB_CONTAINER_ID
#   DSB_CONTAINER_SERVICE
#   DSB_CONTAINER_STATUS
function dsb_get_container_id()
{
    local -r mymode="$2"
    if [ -z "$1" ] || [ -n "$mymode" -a "$mymode" != "--anystatus" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsb_get_container_id: wrong arguments: ${@} \n"
    fi

    if [ "$1" = "$DSBLIB_LAST_SERVICE_ARG" -a -n "$DSB_CONTAINER_ID" -a -z "$mymode" ]; then
        if [ "$DSB_CONTAINER_STATUS" = "$DSBLIB_STATUS_RUNNING" ]; then
            return 0
        fi
        dsblib_error_exit "Service '$DSBLIB_SERVICE_NAME': container '$DSBLIB_SERVICE_NAME:${DSBLIB_SERVICE_INDEX:-1}' status: ${DSB_CONTAINER_STATUS}\nPlease restart service or dsb project"
    fi

    dsblib_parse_service_arg "$1"   # Note: 'dsb_set_box' is called here

    if   [ -z "$DSBLIB_SERVICE_NAME" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsb_get_container_id: service name not specified"
    elif [ -z "$DSBLIB_LOWER_PROJECT" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsb_get_container_id: Empty DSBLIB_LOWER_PROJECT variable!"
    fi

    local -r  myindex="${DSBLIB_SERVICE_INDEX:-1}"

    DSBLIB_LAST_SERVICE_ARG="$1"
    DSB_CONTAINER_ID=
    DSB_CONTAINER_SERVICE=
    DSB_CONTAINER_STATUS=

    local    myrunning=
    local    myline=
    local -a mylist
    mapfile -t mylist < <( docker container ls --all --format='{{.ID}}|{{.Names}}|{{.State}}' --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
    for myline in "${mylist[@]}" ; do
        local myid="${myline%%|*}"    ; myline="${myline#*|}"
        local myname="${myline%%|*}"  ; myline="${myline#*|}"
        local mystatus="$myline"

        myname="${myname#$DSBLIB_LOWER_PROJECT}"
        myname="${myname:1}"

        local mylng="${#myname}"
        local mypos="$(( mylng - 1 ))"
        local mychar="${myname:$mypos:1}"
        while [ "$mypos" -ge 0 -a "$mychar" != "-" -a "$mychar" != "_" ]; do
            (( --mypos ))
            mychar="${myname:$mypos:1}"
        done

        local mystr="${myname:0:$mypos}"
        if (( (mylng - mypos) > 5 )) && [ "$mychar" = "_" -a "${mystr%_run}" != "$mystr" ]; then
            continue  # skip 'docker-compose run' containers
        fi

        myrunning=1

        myname="${myname%${mychar}${myindex}}"
        if [ "$myname" = "$DSBLIB_SERVICE_NAME" ]; then
            DSB_CONTAINER_ID="$myid"
            DSB_CONTAINER_SERVICE="$myname"
            DSB_CONTAINER_STATUS="$mystatus" # running | exited | paused
            break
        fi
    done

    if [ -z "$DSB_CONTAINER_ID" ]; then
        dsblib_make_sure_service_name "$DSBLIB_SERVICE_NAME" 1>&2

        if [ -n "$mymode" ]; then
            return 1 # may be dsb is not running
        fi

        if [ -z "$myrunning" ]; then
            dsblib_error_exit "Please start dsb project"
        fi
        dsblib_error_exit "Service '$DSBLIB_SERVICE_NAME': container '$DSBLIB_SERVICE_NAME:$myindex' not found"

    elif [ "$DSB_CONTAINER_STATUS" != "$DSBLIB_STATUS_RUNNING" -a -z "$mymode" ]; then
        dsblib_error_exit "Service '$DSBLIB_SERVICE_NAME': container '$DSBLIB_SERVICE_NAME:$myindex' status: ${DSB_CONTAINER_STATUS}\nPlease restart service or dsb project"
    fi
    return 0    
}

function dsb_map_env()
{
    DSBLIB_RUN_ENV=( "$@" )
}

function dsb_resolve_files()
{
    DSBLIB_RESOLVE_EXTS=( "$@" )
}

# Usage: dsb_run_as_user <service> <command> [ ...<parameters> ]
function dsb_run_as_user()
{
    if [ -z "$1" -o -z "$2" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsb_run_as_user: wrong arguments: ${@} \n"
    fi

    local -r myService="$1"
    local -r myCommand="${2@Q}"
    shift 2  # skip <service> & <command>

    local -r myScript='if ! hash '$myCommand' 2>/dev/null ; then echo "Command '$myCommand' not found in the container" 1>&2 ; exit 127 ; fi ; '$myCommand' "$@"'
    dsblib_run_command "$myService" "$DSB_UID_GID" - -l -c "$myScript" "$DSBLIB_BINCMD" "$@"
}

# Usage: dsb_run_as_root <service> <command> [ ...<parameters> ]
function dsb_run_as_root()
{
    if [ -z "$1" -o -z "$2" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsb_run_as_root: wrong arguments: ${@} \n"
    fi

    local -r myService="$1"
    local -r myCommand="${2@Q}"
    shift 2  # skip <service> & <command>

    local -r myScript='if ! hash '$myCommand' 2>/dev/null ; then echo "Command '$myCommand' not found in the container" 1>&2 ; exit 127 ; fi ; '$myCommand' "$@"'
    dsblib_run_command "$myService" "0:0" - -l -c "$myScript" "$DSBLIB_BINCMD" "$@"
}

function dsb_docker_compose()
{
    dsb_set_box 1>&2  # never use STDOUT

    if [ -z "$DSBLIB_PROJECT_NAME" ]; then
        dsblib_error_exit "${DSBLIB_BINCMD}: dsb_docker_compose: Empty DSBLIB_PROJECT_NAME variable!"
    fi

    if [ "$1" = "--dsblib-echo" ]; then
        shift
        dsblib_message "docker-compose --project-name $DSBLIB_PROJECT_NAME ${@}"
    fi

    local myrc=
    pushd "$PWD" > /dev/null
    dsblib_exec cd "$DSB_COMPOSE"
    docker-compose --project-name "$DSBLIB_PROJECT_NAME" --project-directory "$DSB_COMPOSE" "$@"
    myrc="$?"
    popd > /dev/null
    return "$myrc"
}

function dsb_message()          { dsblib_message "$@" ; }
function dsb_green_message()    { dsblib_green_message "$@" ; }
function dsb_red_message()      { dsblib_red_message "$@" ; }
function dsb_yellow_message()   { dsblib_yellow_message "$@" ; }

############################

dsblib_reset_options

declare -r DSBLIB_LIB_OK=1