
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

declare  DSBLIB_ECHO_OPTS=

# Usage: dsblib_echo <prefix> <suffix> [ ...<text> ]
function dsblib_echo()
{
    local -r myprefix="$1"
    local -r mysuffix="$2"
    shift 2
    local myskipeol=
    if [ "$1" = '-n' ]; then
        myskipeol='-n'
        shift 1
    fi
    echo -e $myskipeol "$myprefix""$@""$mysuffix"
}

function dsb_message()          { if [ -t 1 -a -n "$DSBLIB_COLOR_TERM" ]; then dsblib_echo "\e[36m" "\e[m" "$@" ; else dsblib_echo '' '' "$@" ; fi }
function dsb_green_message()    { if [ -t 1 -a -n "$DSBLIB_COLOR_TERM" ]; then dsblib_echo "\e[32m" "\e[m" "$@" ; else dsblib_echo '' '' "$@" ; fi }

# NOTE:  dsb_red_message must write to STDERR only!
function dsb_red_message()      { if [ -t 2 -a -n "$DSBLIB_COLOR_TERM" ]; then dsblib_echo "\e[31m" "\e[m" "$@" 1>&2 ; else dsblib_echo '' '' "$@" 1>&2 ; fi }

# NOTE:  dsb_yellow_message must write to STDERR only!
function dsb_yellow_message()   { if [ -t 2 -a -n "$DSBLIB_COLOR_TERM" ]; then dsblib_echo "\e[33m" "\e[m" "$@" 1>&2 ; else dsblib_echo '' '' "$@" 1>&2 ; fi }

function dsblib_exit()
{
    exit "${1:-0}"
}

function dsb_error_exit()
{
    local mymsg="$@"
    if [ -n "$mymsg" ]; then
        if [ "${mymsg%\.}" != "$mymsg" ]; then
            mymsg="$mymsg "
        elif [ "${mymsg%\\n}" = "$mymsg" ]; then
            mymsg="$mymsg - "
        fi
        mymsg="${mymsg}EXECUTION ABORTED"

        dsb_red_message "$mymsg" 1>&2

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
            dsb_error_exit "${DSBLIB_BINCMD}: '$mycmd' command not found"
        fi
    done
}

#### Check runtime utilities

dsblib_which  cp cut docker find id ls rm

case "$DSBLIB_OSTYPE" in
    LINUX )     dsblib_which  readlink  ;;
    OSX | BSD ) dsblib_which  greadlink ;;
    *)  dsb_error_exit "${DSBLIB_BINCMD}: Unsupported OS Type: $OSTYPE - EXECUTION ABORTED" 1>&2
        exit 100
        ;;
esac

######################
#
#   GLOBAL VARIABLES
#
#   Declared in the dsb_set_box():  DSB_ROOT, DSB_BOX, DSB_COMPOSE, DSBLIB_PROJECT_NAME, DSBLIB_LOWER_PROJECT

declare -r  DSBLIB_LIB="${BASH_SOURCE[0]%/*}"
# Note: ${BASH_SOURCE[0]} is always a full path string. See dsb and dsb-script

declare -r  DSB_UTILS="$DSBLIB_LIB/utils"
declare -r  DSB_SKEL="$DSBLIB_LIB/skel"
declare -r  DSB_UID="$( id -u )"
declare -r  DSB_GID="$( id -g )"
declare -r  DSB_UID_GID="$DSB_UID:$DSB_GID"   # used in .yaml files

# dsb-script runtime variable:
declare     DSB_SCRIPT_PATH=
declare     DSB_SCRIPT_NAME=

# default values for .dsbenv variables:
declare -l  DSB_STANDALONE_SYNTAX=false
declare -l  DSB_HOME_VOLUMES=false
declare -l  DSB_PROD_MODE=false
declare     DSB_SHUTDOWN_TIMEOUT=15
declare     DSB_UMASK_ROOT=
declare     DSB_UMASK_SH=
declare     DSB_ARGS_MAPPING=

# dsb_get_container_id(), dsblib_parse_container_name() output variables:
declare     DSB_OUT_CONTAINER_ID=
declare     DSB_OUT_CONTAINER_SERVICE=
declare     DSB_OUT_CONTAINER_INDEX=
declare     DSB_OUT_CONTAINER_STATUS=

declare     DSBLIB_CMDPATH="${DSBLIB_LIB%/*}/bin/$DSBLIB_BINCMD"
# The constant contains the full path name of the executable command

declare -r  DSBLIB_DSBENV='.dsbenv'
declare -r  DSBLIB_NOTSET='@@@#*^NOTSET^*#@@@'
declare -r  DSBLIB_PROJECT_PREFIX="dsb-"
declare -r  DSBLIB_STATUS_RUNNING="running"
declare -r  DSBLIB_STATUS_EXITED="exited"
declare -r  DSBLIB_STATUS_PAUSED="paused"
declare -r  DSBLIB_CHAR_EOL=$'\n'
declare -r  DSBLIB_CHAR_TAB=$'\t'
declare -r  DSBLIB_CHAR_INDEX='#'  # container's index delimiter

declare -a  DSBLIB_PROJECT_SERVICES=()
declare -a  DSBLIB_RUN_ENV=()
declare -a  DSBLIB_RESOLVE_EXTS=()
declare -a  DSBLIB_RESOLVED_ARGS=()

declare     DSBLIB_RESULT=
declare -a  DSBLIB_ARRAY_RESULT=()

# dsb_get_container_id() internal cache:
declare -A  DSBLIB_CONTAINERS_CACHE=()

# dsblib_check_compose_version() output variables:
declare     DSBLIB_COMPOSE_VERSION_MAJOR=
declare     DSBLIB_COMPOSE_VERSION_MINOR=
declare     DSBLIB_COMPOSE_VERSION_PATCH=

# dsblib_get_service_replicas() output variable:
declare -A  DSBLIB_REPLICAS=()

# dsb_parse_service_arg() & dsb_validate_service_arg() output variables:
declare     DSB_OUT_SERVICE_NAME=
declare     DSB_OUT_SERVICE_INDEX=
declare     DSBLIB_OUT_SERVICE_VAR=

# dsblib_set_container_space() input & output variables:
declare     DSBLIB_MOUNTS_CONTAINER=
declare -A  DSBLIB_MOUNTS_MAP=()
declare -Al DSBLIB_MOUNTS_RW_MAP=()

# dsblib_parse_file_path() output variables:
declare     DSBLIB_PARSED_PATH_PARENT=
declare     DSBLIB_PARSED_PATH_NAME=

# dsb_run_dsb() internal variables (used in lib/dsb source files)
declare     DSBLIB_DSBCMD=
declare     DSBLIB_DSBARG=
declare -a  DSBLIB_DSBARG_STACK=()
declare -a  DSBLIB_DSBARG_STACK_BACKUP=()

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

# Usage: if dsblib_in_array <needle> ...<array_items> ; then ... ; fi
function dsblib_in_array()
{
    local -r myneedle="$1"
    shift
    local myitem=
    for myitem in "${@}" ; do
        if [ "$myitem" = "$myneedle" ]; then
            return 0
        fi
    done
    return 1
}

# Usage: dsblib_split <some_string> <some_delimiter>
# Output variable: DSBLIB_ARRAY_RESULT
function dsblib_split()
{
    local    myString="$1"
    local -r myDel="$2"
    local    myItem=
    DSBLIB_ARRAY_RESULT=()

    if [ -z "$myString" ]; then
        return
    fi

    while [ 1 ] ; do
        myItem="${myString%%${myDel}*}"
        DSBLIB_ARRAY_RESULT=( "${DSBLIB_ARRAY_RESULT[@]}" "$myItem" )
        if [ "$myString" = "$myItem" ]; then
            return
        fi
        myString="${myString#*${myDel}}"
    done 
}

# Usage: dsblib_append  <string> <length> [ <char> ]
function dsblib_append()
{   
    local char="${3:- }"
    local count="$(( $2 - ${#1} ))"
    DSBLIB_RESULT="$1"
    while (( count > 0 )) ; do
        DSBLIB_RESULT="${DSBLIB_RESULT}${char}"
        (( --count ))
    done
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
    dsb_exec mapfile -t mystdout < <( "$@" )
    for myline in "${mystdout[@]}" ; do
        if [ "$myline" = "$myneedle" ]; then
            return 0
        fi
    done
    return 1
}

# Usage: dsblib_parse_file_path  <file_or_directory_path>
# Output variables: DSBLIB_PARSED_PATH_PARENT, DSBLIB_PARSED_PATH_NAME
function dsblib_parse_file_path()
{
    DSBLIB_PARSED_PATH_PARENT=
    DSBLIB_PARSED_PATH_NAME=
    local mypath="$1"
    if [ -z "$mypath" -o "${mypath%/}" != "$mypath"  ]; then
        dsb_error_exit "dsblib_parse_file_path: WRONG PATH: ${mypath}"
    fi

    if [ "${mypath:0:2}" = './' ]; then
        mypath="${PWD%/}/${mypath:2}"
    elif [ "${mypath:0:1}" != '/' ]; then
        mypath="${PWD%/}/${mypath}"
    fi

    DSBLIB_PARSED_PATH_NAME="${mypath##*/}"
    DSBLIB_PARSED_PATH_PARENT="${mypath%/*}"
    if [ -z "$DSBLIB_PARSED_PATH_PARENT" -o -z "$DSBLIB_PARSED_PATH_NAME" ]; then
        dsb_error_exit "dsblib_parse_file_path: WRONG PATH: ${mypath} ($1)"
    fi
}

# Usage: if dsblib_test_file_mod <file_path> <ls_regexp_pattern> ; then ... fi
function dsblib_test_file_mod()
{
    local myPath="$1"
    local myPattern="$2"
    if [ -z "$myPath" ] || [ ! -e "$myPath" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsblib_test_file_mod: BAD USAGE: '${myPath}' - filepath not found!\n"
    fi
    if [ -z "$myPattern" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsblib_test_file_mod: BAD USAGE: pattern arg is not defined!\n"
    fi

    local myMod="$( ls -lLd1 "$myPath" )"
    myMod="${myMod%% *}"
    dsblib_trim "$myMod"

    if [[ "$DSBLIB_RESULT" =~ $myPattern ]]; then
        return 0
    fi
    return 1
}

############################
#
#   PRIVATE FUNCTIONS
#
############################

function dsblib_usage()
{
    local myCmd="${DSBLIB_BINCMD:-dsb}"
    dsb_yellow_message "
Usage:
  $myCmd cid  SERVICE_NAME
  $myCmd compose  ...PARAMETERS
  $myCmd down  [ --host | ...SERVICE_NAMES ]
  $myCmd help
  $myCmd init
  $myCmd ip    SERVICE_NAME
  $myCmd logs    [ SERVICE_NAME ]
  $myCmd ps      [ SERVICE_NAME ]
  $myCmd restart [ ...SERVICE_NAMES ]
  $myCmd rm-vols [ --host | ...VOLUME_NAMES ]
  $myCmd root  SERVICE_NAME [ COMMAND [ ...PARAMETERS ] ]
  $myCmd sh    SERVICE_NAME [ COMMAND [ ...PARAMETERS ] ]
  $myCmd scale SERVICE_NAME  REPLICAS
  $myCmd start [ ...SERVICE_NAMES ]
  $myCmd stop  [ ...SERVICE_NAMES ]
  $myCmd var   [ VARIABLE_NAME ]
  $myCmd vols  [ --quiet ]
  $myCmd yaml  SERVICE_NAME [ DOCKER_IMAGE ] [ --sleep | --cmd  ] [ --initd ] [ --build ]
"
    if [ "$( env dsb-script -c 'echo OK' )" != "OK" ]; then
        dsb_red_message "WARNING: 'dsb-script' command is not available for the 'env' command.\nA possible reason is the use of the tilde character in the value of the PATH variable."
        return 1
    fi
    return 0
}

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

# Usage: dsblib_parse_container_name <container_name>
# Output variables:
#   DSB_OUT_CONTAINER_SERVICE
#   DSB_OUT_CONTAINER_INDEX  (empty if 'compose run ...' container )
function dsblib_parse_container_name()
{
    DSB_OUT_CONTAINER_SERVICE=
    DSB_OUT_CONTAINER_INDEX=
    local -r errorMsg="dsblib_parse_container_name: Unsupported container name '$1'"
    local mylng=
    local mychar=
    local myindex=

    local myservice="${1#$DSBLIB_LOWER_PROJECT}"
    if [ "$myservice" = "$1" -o -z "$myservice" ]; then
        dsb_error_exit "$errorMsg"
    fi

    myservice="${myservice:1}"
    mylng="${#myservice}"
    while (( mylng > 0 )); do
        (( --mylng ))
        mychar="${myservice:${mylng}:1}"
        myservice="${myservice:0:${mylng}}"
        if [ "$mychar" = "-" -o "$mychar" = "_" ]; then
            break
        fi
        myindex="${mychar}${myindex}"
    done

    if [ -z "$myservice" -o -z "$myindex" ]; then
        dsb_error_exit "$errorMsg"
    fi

    if [ ${#myindex} -gt 5 -a "${myservice%${mychar}run}" != "$myservice" ]; then
        # 'compose run ...' container
        DSB_OUT_CONTAINER_SERVICE="${myservice%${mychar}run}"
        return
    fi

    local mypattern='^[0-9]+$'    
    if [[ ! "$myindex" =~ $mypattern ]]; then
        dsb_error_exit "$errorMsg"
    fi
    DSB_OUT_CONTAINER_SERVICE="$myservice"
    DSB_OUT_CONTAINER_INDEX="$myindex"
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
    dsb_exec mapfile -t myvolumes < <( docker volume ls --filter "label=com.docker.compose.project=${DSBLIB_LOWER_PROJECT}" --format '{{.Name}}' )
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
        dsb_error_exit "${DSBLIB_BINCMD}: dsblib_get_service_replicas: Empty DSBLIB_LOWER_PROJECT variable!"
    fi

    local -r  myservice="$1"
    local -r  mymode="$2"
    local -r  myoptskip="--skip-orphans"
    local     myname=
    local -a  mylist
    mapfile -t mylist < <( docker container ls --all --format='{{.Names}}' --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
    for myname in "${mylist[@]}" ; do
        dsblib_parse_container_name "$myname"
        if [ -z "$DSB_OUT_CONTAINER_INDEX" ]; then
            continue  # skip 'compose run' containers
        fi
        local mykey="$DSB_OUT_CONTAINER_SERVICE"
        if [ "$mymode" = "$myoptskip" ] && ! dsb_validate_service_arg "$mykey" --check ; then
            continue
        fi

        if [ -n "$myservice" -a "$myservice" != "-" -a "$myservice" = "$mykey" ]; then
            (( ++ DSBLIB_RESULT ))
        fi
        local myreplicas="${DSBLIB_REPLICAS[$mykey]}"
        if [ -n "$myreplicas" ]; then
            (( ++ myreplicas ))
            DSBLIB_REPLICAS[$mykey]="$myreplicas"
        else
            DSBLIB_REPLICAS[$mykey]=1
        fi
    done
}

# Usage: dsblib_set_container_space <container_id> <host_path>
# Output varible:
#   DSBLIB_RESULT - path in the container
# Input & Output variables:
#   DSBLIB_MOUNTS_MAP
#   DSBLIB_MOUNTS_RW_MAP
#   DSBLIB_MOUNTS_CONTAINER - container_id for DSBLIB_MOUNTS_MAP & DSBLIB_MOUNTS_RW_MAP
# Returns: 0 - if nonempty DSBLIB_RESULT
#          1 - if empty    DSBLIB_RESULT (host path is not available in the container)
#
# Note: DSBLIB_MOUNTS_MAP and DSBLIB_MOUNTS_RW_MAP arrays have keys,
#       that are top-level directory paths with corresponding properties
#
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
        dsb_error_exit "${DSBLIB_BINCMD}: dsblib_set_container_space: WRONG ARGS: ${@}"
    fi

    if [ "$DSBLIB_MOUNTS_CONTAINER" != "$myid" ]; then
        DSBLIB_MOUNTS_CONTAINER="$myid"
        DSBLIB_MOUNTS_MAP=()
        DSBLIB_MOUNTS_RW_MAP=()

        local -a mylist
        mapfile -t  mylist < <( docker container inspect "$DSBLIB_MOUNTS_CONTAINER" --format "{{range .Mounts}}{{if eq .Type \"bind\" }}{{.Source}}${DSBLIB_CHAR_TAB}{{.Destination}}${DSBLIB_CHAR_TAB}{{.RW}}${DSBLIB_CHAR_EOL}{{end}}{{end}}" )
        local myline=
        for myline in "${mylist[@]}" ; do
            if [ -z "$myline" ]; then
                continue
            fi
            dsblib_split "$myline" "$DSBLIB_CHAR_TAB"
            mysrc="${DSBLIB_ARRAY_RESULT[0]}"
            mydest="${DSBLIB_ARRAY_RESULT[1]}"
            myrw="${DSBLIB_ARRAY_RESULT[2]}"

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

# Usage: dsblib_resolve_args <service_name> [ ...<args> ]
# NOTE: The 'dsblib_set_container_space' function must be called before this function call
#
# Input variables:
#   DSBLIB_RESOLVE_EXTS
#   DSBLIB_MOUNTS_CONTAINER
#   DSBLIB_MOUNTS_MAP
#   DSBLIB_MOUNTS_RW_MAP
#
# Output variable:
#   DSBLIB_RESOLVED_ARGS
#
# NOTE: The function's algorithm is not perfect, but it is quite sufficient for real use cases.
# The main purpose of this algorithm is:
# - to execute a command with full path file-arguments;
# - to execute a command when the current working directory is outside the mounted space,
#   but the real full path of the file-arguments falls within this space.
# The need for this may arise when integrating Dsb scripts with IDE.
#
function dsblib_resolve_args()
{
    if [ -z "$DSBLIB_MOUNTS_CONTAINER" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsblib_resolve_args: DSBLIB_MOUNTS_CONTAINER is empty"
    fi

    local myService="$1"
    local myFullpathMapping=
    if dsblib_args_mapping "$myService" ; then
        myFullpathMapping=1
    fi
    shift

    DSBLIB_RESOLVED_ARGS=( "$@" )

    if [ "$#" = 0 ]; then
        return 0
    fi

    pushd "$PWD" > /dev/null

    local -r myLeftDels='[ =:,;><"'"'"'`()]'
    local -r myRightDels='[ =:,;><"'"'"'`()/]'
    local -r mySysDirs='^/(dsbhome|dsbutils|dsbspace|dev|bin|etc|lib|logs|proc|run|sbin|snap|sys|tmp|usr|var)/'
    local    myPattern=
    local    myName=
    local    myTemp=
    local    myExt=
    local    mySrc=
    local    mySrcRE=
    local    myDest=

    local -r mycount="${#DSBLIB_RESOLVED_ARGS[@]}"
    local    myind=0    
    while (( myind < mycount )) ; do
        local myArg="${DSBLIB_RESOLVED_ARGS[$myind]}"

        if [ "${myArg#dsbnop:}" != "$myArg" ]; then
            DSBLIB_RESOLVED_ARGS[$myind]="${myArg#dsbnop:}"   # transparent
            (( ++myind ))
            continue
        fi

        myName="${myArg##*/}"
        if [ "$myArg" = "$myName" -o "$myFullpathMapping" != 1 ]; then
            (( ++myind ))
            continue
        fi

        # Resolve relative path to fullpath for file extentions from DSBLIB_RESOLVE_EXTS ...
        if [ "${#DSBLIB_RESOLVE_EXTS[@]}" != 0 ] && [[ ! "$myArg" =~ $myLeftDels ]]; then
            # NOTE: skipping /tmp/... files is essential for PhpStorm validation script /tmp/ide-phpinfo.php. See dsbscripts/dsbphp
            if [ "${myArg#/tmp/}" != "$myArg" ]; then
                (( ++myind ))
                continue
            fi

            myTemp="${myName##*\.}"
            if [ -n "$myTemp" -a "$myTemp" != "$myName" ]; then
                for myExt in "${DSBLIB_RESOLVE_EXTS[@]}" ; do
                    if [ "$myTemp" = "$myExt" ]; then
                        myTemp="$( dsblib_gnu_readlink -f "$myArg" )"
                        if [ -n "$myTemp" -a "$myTemp" != "$myArg" ]; then
                            # Сheck to be inside the mounted directory
                            if [[ "$myTemp" =~ $mySysDirs ]]; then
                                dsb_error_exit "Host's file '$myArg' ($myTemp) is not allowed for mapping to containers"
                            elif ! dsblib_set_container_space "$DSBLIB_MOUNTS_CONTAINER" "$myTemp" ; then
                                dsb_error_exit "Cannot map host's file '$myArg' ($myTemp) to the '$myService' container"
                            fi
                            DSBLIB_RESOLVED_ARGS[$myind]="$DSBLIB_RESULT"
                            (( ++myind ))
                            continue 2  # CONTINUE MAIN LOOP
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

# Usage: if dsblib_args_mapping <service_name> ; then ... ; fi
function dsblib_args_mapping()
{
    if [ "$DSB_ARGS_MAPPING" = '*' ]; then
        return 0
    fi
    local mystr=":${DSB_ARGS_MAPPING}:"
    if [ "${mystr#*:${1}:}" != "$mystr" ]; then
        return 0
    fi
    return 1
}

# Usage: dsblib_check_uid_gid [ "Are you sure ... ?" ]
function dsblib_check_uid_gid()
{
    DSBLIB_RESULT=
    local    mySureMsg="$1"
    local    myMsg=
    local    myItem=
    local    myValue=
    local -l myReply=
    local -a myArray
    dsb_exec mapfile -t myArray < <( docker container ls --all --format='{{.ID}}' --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
    if [ "${#myArray[@]}" = 0 ]; then
        return 0
    fi
    dsb_exec mapfile -t myArray < <( docker container inspect --format='{{range .Config.Env}}{{.|printf "%s"}}'"$DSBLIB_CHAR_EOL"'{{end}}' ${myArray[@]} )
    if [ "${#myArray[@]}" = 0 ]; then
        return 0
    fi

    for myItem in "${myArray[@]}" ; do
        myValue="${myItem#DSB_UID_GID=}"
        if [ "$myValue" != "$myItem" -a "$myValue" != "$DSB_UID_GID" ]; then
            DSBLIB_RESULT="$myValue"
            myMsg="There is Dsb project's container with DSB_UID_GID=${myValue}, your current DSB_UID_GID=${DSB_UID_GID}"
            if [ -z "$mySureMsg" -o "$DSB_UID" != 0 ]; then
                dsb_error_exit "${myMsg}\nDSB_UID_GID conflict"
            elif [ "$mySureMsg" = '-' ]; then
                dsb_yellow_message "WARNING: ${myMsg}"
                return 1
            fi
            
            dsb_yellow_message -n "${myMsg}\n${mySureMsg} [yN] "
            read myReply
            if [ "$myReply" != "y" ]; then
                dsb_yellow_message "CANCELLED"
                dsb_error_exit
            fi
            return 0
        fi
    done
    return 0
}

# Usage: dsblib_reset_cache
function dsblib_reset_cache()
{
    # NOTE: the DSBLIB_PROJECT_SERVICES variable is not reset
    # because the COMPOSE_FILE variable does not change its value during script execution

    DSBLIB_CONTAINERS_CACHE=()

    # Just in case, reset DSBLIB_MOUNTS_... variables (in case the service definition changes)
    DSBLIB_MOUNTS_CONTAINER=
    DSBLIB_MOUNTS_MAP=()
    DSBLIB_MOUNTS_RW_MAP=()
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
    local -r myMinMinor=27

    DSBLIB_COMPOSE_VERSION_MAJOR=0
    DSBLIB_COMPOSE_VERSION_MINOR=0
    DSBLIB_COMPOSE_VERSION_PATCH=0

    local -l myver="$(
        local myCompose="docker compose"
        if [ "$DSB_STANDALONE_SYNTAX" = true ] && hash docker-compose > /dev/null 2>/dev/null ; then
            myCompose="docker-compose"
        fi
        $myCompose version --short 2>/dev/null
    )"

    myver="${myver%%-*}" # truncate possible pre-release
    myver="${myver#v}"   # truncate v-prefix

    local mypattern='^[0-9]+\.[0-9]+\.[0-9]+$'
    if [[ "$myver" =~ $mypattern ]]; then
        dsblib_split "$myver" '.'
        DSBLIB_COMPOSE_VERSION_MAJOR="${DSBLIB_ARRAY_RESULT[0]}"
        DSBLIB_COMPOSE_VERSION_MINOR="${DSBLIB_ARRAY_RESULT[1]}"
        DSBLIB_COMPOSE_VERSION_PATCH="${DSBLIB_ARRAY_RESULT[2]}"
        if  [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -gt "$myMinMajor" ] || \
            [ "$DSBLIB_COMPOSE_VERSION_MAJOR" -eq "$myMinMajor" -a "$DSBLIB_COMPOSE_VERSION_MINOR" -ge "$myMinMinor" ]
        then
            return 0
        fi
    else
        dsb_error_exit "Please install Docker Compose version >= $myMinMajor.$myMinMinor.0"
    fi
    echo "$myline" 1>&2
    dsb_error_exit "Please upgrade Docker Compose to version >= $myMinMajor.$myMinMinor.0"
}

# Usage: dsblib_check_shutdown_timeout
function dsblib_check_shutdown_timeout()
{
    local -r myPattern='^[0-9]+$'
    if [[ ! "$DSB_SHUTDOWN_TIMEOUT" =~ $myPattern ]] || [ "$DSB_SHUTDOWN_TIMEOUT" -lt 1 ] ; then
        dsb_error_exit "DSB_SHUTDOWN_TIMEOUT: the value '$DSB_SHUTDOWN_TIMEOUT' is not allowed"
    fi
}

# Usage: if dsblib_is_prod_mode ; then ... ; fi
function dsblib_is_prod_mode()
{
    if [ "$DSB_PROD_MODE" = "true" ]; then
        return 0
    fi
    return 1
}

# Usage: if dsblib_is_home_volumes ; then ... ; fi
function dsblib_is_home_volumes()
{
    if [ "$DSB_HOME_VOLUMES" = "true" ]; then
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

    dsb_exec cd "$mydir"
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

# Usage: dsblib_chmod_dir <directory_path> <mode>
function dsblib_chmod_dir()
{
    dsblib_parse_file_path "$1"
    local myParent="$DSBLIB_PARSED_PATH_PARENT"
    local myName="$DSBLIB_PARSED_PATH_NAME"
    local mydir="${DSBLIB_PARSED_PATH_PARENT}/${DSBLIB_PARSED_PATH_NAME}"
    local mymod="$2"

    if [ ! -d "$mydir" ]; then
        return 0
    fi

    local mypwd="$( if cd -- "$mydir" 2>/dev/null; then pwd -P ; fi )"
    if [ -n "$mypwd" -a "$mypwd" != "$mydir" ] ; then
        dsblib_parse_file_path "$mypwd"
        mydir="${DSBLIB_PARSED_PATH_PARENT}/${DSBLIB_PARSED_PATH_NAME}"
        myParent="$DSBLIB_PARSED_PATH_PARENT"
        myName="$DSBLIB_PARSED_PATH_NAME"
    fi

    if ! chmod "$mymod" "$mydir" &>/dev/null ; then
        dsb_yellow_message "dsblib_chmod_dir: Couldn't chmod $mymod $mydir"
        return 1
    fi
    return 0
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
    dsb_exec mkdir -p "$mydir"
    return 0
}

# Usage: dsblib_init_service <service_name>
function dsblib_init_service()
{
    local myname="$1"
    local mydir=

    if [ -z "$myname" ]; then
        dsb_error_exit "dsblib_init_service: WRONG USAGE: ${@}"
    fi

    pushd "$PWD" > /dev/null
    dsb_exec cd "$DSB_BOX"

    mydir="home/$myname"
    if dsblib_mkdir_or_dev_mode  "$mydir" ; then
        dsblib_chmod_dir        "$mydir" "u=rwx,go-rwx"
    fi

    mydir="logs/$myname"
    if dsblib_mkdir_or_dev_mode "$mydir" ; then
        dsblib_chmod_dir        "$mydir" "a=rwx"
    fi
    
    popd > /dev/null
}

############################
#
#   PUBLIC FUNCTIONS
#
############################

# Usage: dsb_exec <some_command> ...<args>
function dsb_exec()
{
    # NOTE: DO NOT ECHO TO STDOUT HERE!

    local mycaller="${FUNCNAME[1]}: ${FUNCNAME[0]}: "
    if [ "${FUNCNAME[1]}" = "main" -o "${FUNCNAME[1]}" = "source" ]; then
        mycaller=
    fi

    if [ -z "$*" ]; then
        if [ -z "$mycaller" ]; then
            mycaller="dsb_exec: "
        fi
        dsb_error_exit "${DSBLIB_BINCMD}: ${mycaller}empty command"
    fi

    "$@"
    local myrc="$?"

    if [ "$myrc" -ne 0 ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: ${mycaller}last command:" "$@" \
                          "\n${DSBLIB_BINCMD}: nonzero exit status (${myrc}) of the last command executed"
    fi
}

# Usage: dsb_run_dsb <dsb_subcommand> [ ...<subcommand_parameters> ]
function dsb_run_dsb()
{
    DSBLIB_DSBARG="$1"
    DSBLIB_DSBCMD="$DSBLIB_BINCMD $DSBLIB_DSBARG"

    shift   # skip DSBLIB_DSBARG

    if [ -n "$DSBLIB_DSBARG" ] && dsblib_in_array "$DSBLIB_DSBARG" "${DSBLIB_DSBARG_STACK[@]}" ; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_run_dsb: '${DSBLIB_DSBARG}' subcommand recursion"
    fi

    DSBLIB_DSBARG_STACK_BACKUP=( "${DSBLIB_DSBARG_STACK[@]}" )
    DSBLIB_DSBARG_STACK=( "${DSBLIB_DSBARG_STACK[@]}" "$DSBLIB_DSBARG" )

    case "$DSBLIB_DSBARG" in
        cid | compose | down | init | ip | logs | ps | restart | rm-vols | root | scale | sh | start | stop | var | vols | yaml )
            ( . "$DSBLIB_LIB/dsb/$DSBLIB_DSBARG.bash" )
            ;;
        "" | help )
            dsblib_usage
            ;;
        * )
            ( . "$DSBLIB_LIB/dsb/bin.bash" )
            ;;
    esac
    DSBLIB_RESULT="$?"

    dsblib_reset_cache
    DSBLIB_DSBARG_STACK=( "${DSBLIB_DSBARG_STACK_BACKUP[@]}" )
    DSBLIB_DSBARG_STACK_BACKUP=()    
    return "$DSBLIB_RESULT"
}

# Usage: dsb_set_single_box [ --check ]
function dsb_set_single_box()
{
    local    mydir=
    local    mytmp=
    local    mystr=
    local    myline=
    local -a mylist
    mapfile -t mylist < <( docker container ls --format "{{.State }}\t{{.Labels}}" )
    for myline in "${mylist[@]}" ; do
        dsblib_split "$myline" "$DSBLIB_CHAR_TAB"
        if [ "${DSBLIB_ARRAY_RESULT[0]}" = "running" ]; then
            mystr="${DSBLIB_ARRAY_RESULT[1]}"
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
                        dsb_yellow_message "Several Dsb projects are running now."
                        dsb_error_exit "Only one project should be active for this command to execute"
                    fi
                fi
            fi
        fi
    done

    if [ -z "$mydir" ] || [ ! -d "$mydir" ]; then
        if [ "$1" = "--check" ]; then
            return 1
        fi
        dsb_error_exit "Active Dsb project not found"
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
    local    mydir="$PWD"
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
                    dsb_error_exit "${DSBLIB_BINCMD}: dsb_set_box: wrong --dir option: ${2}"
                fi
                mydir="$( cd $2 ; pwd -P )"
                if [ "$2" != "$mydir" ]; then
                    dsb_error_exit "${DSBLIB_BINCMD}: dsb_set_box: --dir option cannot be a symlink: ${2}"
                fi
                shift 2
                ;;
            * )
                dsb_error_exit "${DSBLIB_BINCMD}: dsb_set_box: wrong argument: ${1}"
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
            dsb_error_exit "The '.dsb' subdirectory is not found in the '${mysrc}' directory or any parent up to '/'\n"
        fi
        return 1
    fi

    # .dsb is found ...

    declare -gr DSB_COMPOSE="$DSB_BOX/compose"

    if [ ! -d "$DSB_COMPOSE" -a "$1" != check ]; then
        dsb_error_exit "Directory '${DSB_COMPOSE}' not found.\nPlease configure the project!\n"
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
        dsb_error_exit "DSB_PROJECT_ID variable is not defined"
    elif [[ ! "$DSB_PROJECT_ID" =~ $mypattern  ]]; then
        dsb_error_exit "DSB_PROJECT_ID: the value '$DSB_PROJECT_ID' is not allowed"
    elif [ -z "$COMPOSE_FILE" ]; then
        dsb_error_exit "COMPOSE_FILE variable is not defined"
    elif [ "$COMPOSE_FILE" != "${COMPOSE_FILE%:}" ]; then
        dsb_error_exit "COMPOSE_FILE: value '$COMPOSE_FILE' is not allowed"
    elif [ -n "$COMPOSE_PROJECT_NAME" -o "${COMPOSE_PROJECT_NAME-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
        dsb_error_exit "COMPOSE_PROJECT_NAME variable should not be defined in the $DSBLIB_DSBENV"
    elif [ -n "$DSBLIB_PROJECT_NAME" -o "${DSBLIB_PROJECT_NAME-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
        dsb_error_exit "DSBLIB_PROJECT_NAME variable should not be defined in the $DSBLIB_DSBENV"
    elif [ -n "$DSBLIB_LOWER_PROJECT" -o "${DSBLIB_LOWER_PROJECT-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
        dsb_error_exit "DSBLIB_LOWER_PROJECT variable should not be defined in the $DSBLIB_DSBENV"
    elif [ "$DSB_HOME_VOLUMES" != true -a "$DSB_HOME_VOLUMES" != false ]; then
        dsb_error_exit "DSB_HOME_VOLUMES: the value '$DSB_HOME_VOLUMES' is not allowed"
    elif [ "$DSB_PROD_MODE" != true -a "$DSB_PROD_MODE" != false ]; then
        dsb_error_exit "DSB_PROD_MODE: the value '$DSB_PROD_MODE' is not allowed"
    elif [ "$DSB_STANDALONE_SYNTAX" != true -a "$DSB_STANDALONE_SYNTAX" != false ]; then
        dsb_error_exit "DSB_STANDALONE_SYNTAX: the value '$DSB_STANDALONE_SYNTAX' is not allowed"
    fi

    local myvar=
    for   myvar in "${!DSB_SERVICE_@}" ; do
        if [ "$myvar" = "DSB_SERVICE_" ]; then
            dsb_error_exit "The variable '$myvar' is not allowed"
        fi
        local -u myuppervar="$myvar"
        if [ "$myvar" != "$myuppervar" ] ; then
            dsb_error_exit "The variable '$myvar' is not allowed - must be uppercase"
        fi
    done

    declare -gr  COMPOSE_FILE
    declare -gr  DSB_PROJECT_ID

    # NOTE: Docker Compose v2 doesn't like uppercase letters in project name
    declare -grl DSBLIB_PROJECT_NAME="${DSBLIB_PROJECT_PREFIX}${DSB_PROJECT_ID}"
    declare -grl DSBLIB_LOWER_PROJECT="$DSBLIB_PROJECT_NAME"
    declare -gr  COMPOSE_PROJECT_NAME="$DSBLIB_PROJECT_NAME"

    # export variables for Docker Compose
    dsblib_export_env_vars "DSB_" "DSBUSR_" "COMPOSE_" "DOCKER_"

    return 0
}

# Usage: dsb_parse_service_arg <service_name>[#<container_index>] | @<service_alias>[#<container_index>]
#
# Public Output variables:
#   DSB_OUT_SERVICE_NAME
#   DSB_OUT_SERVICE_INDEX  - empty string or number
#
# Private Output variables:
#   DSBLIB_OUT_SERVICE_VAR - empty if arg is not service alias
function dsb_parse_service_arg()
{
    DSB_OUT_SERVICE_NAME=
    DSB_OUT_SERVICE_INDEX=
    DSBLIB_OUT_SERVICE_VAR=

    dsb_set_box 1>&2  # never use STDOUT

    local myservice="$1"
    local mytmp="${myservice%${DSBLIB_CHAR_INDEX}*}"
    if [ "$mytmp" != "$myservice" ]; then
        DSB_OUT_SERVICE_INDEX="${myservice##*${DSBLIB_CHAR_INDEX}}"
        myservice="$mytmp"
        local -r mypattern='^[1-9][0-9]*$'
        if [[ ! "$DSB_OUT_SERVICE_INDEX" =~ $mypattern ]]; then
            dsb_error_exit "${DSBLIB_BINCMD}: Wrong container index: $DSB_OUT_SERVICE_INDEX"
        fi
    fi

    if [ "${myservice:0:1}" = "@" ]; then
        local -u myupper="${myservice:1}"
        if [ -z "$myupper" ]; then
            dsb_error_exit "${DSBLIB_BINCMD}: Wrong service alias: $myservice"
        elif [ "$myservice" != "@$myupper" ]; then
            dsb_error_exit "${DSBLIB_BINCMD}: Wrong service alias: $myservice - must be uppercase"
        fi

        DSBLIB_OUT_SERVICE_VAR="DSB_SERVICE_$myupper"
        myservice="${!DSBLIB_OUT_SERVICE_VAR}"
        if [ -z "$myservice" ]; then
            myservice="$DSB_SERVICE"
            if [ -z "$myservice" ]; then
                local -l mylower="$myupper"
                myservice="$mylower"
            fi
        fi
    fi

    DSB_OUT_SERVICE_NAME="$myservice"
}

# Usage: dsb_validate_service_arg      <service_name>[#<container_index>] | @<service_alias>[#<container_index>]
#           or
#        if dsb_validate_service_arg ( <service_name>[#<container_index>] | @<service_alias>[#<container_index>] ) ( --check | --message ) ; then
#          ...
#        fi
# Output variables:
#   DSB_OUT_SERVICE_NAME
#   DSB_OUT_SERVICE_INDEX  - empty string or number
function dsb_validate_service_arg()
{
    dsb_parse_service_arg "$1"

    dsblib_set_services
    local myname=
    for myname in "${DSBLIB_PROJECT_SERVICES[@]}" ; do
        if [ "$myname" = "$DSB_OUT_SERVICE_NAME" ]; then
            return 0
        fi
    done

    if [ "$2" = "--check" ]; then
        return 1
    fi

    local message=
    if [ -n "$DSBLIB_OUT_SERVICE_VAR" ]; then
        message="No such service: '${DSB_OUT_SERVICE_NAME}'\nDefine the proper name via $DSBLIB_OUT_SERVICE_VAR variable"
    else
        message="No such service: '$DSB_OUT_SERVICE_NAME'"
    fi

    if [ "$2" = "--message" ]; then
        dsb_red_message "$message"
        return 1
    fi

    dsb_error_exit "$message"
}

# Usage: dsb_get_container_id ( <service_name>[#<container_index>] | @<service_alias>[#<container_index>] ) [ --anystatus ]
#
# Input internal variable:
#   DSBLIB_CONTAINERS_CACHE
#
# Output variables:
#   DSB_OUT_CONTAINER_ID
#   DSB_OUT_CONTAINER_STATUS
#   DSB_OUT_CONTAINER_SERVICE
#   DSB_OUT_CONTAINER_INDEX
#
function dsb_get_container_id()
{
    DSB_OUT_CONTAINER_ID=
    DSB_OUT_CONTAINER_STATUS=
    DSB_OUT_CONTAINER_SERVICE=
    DSB_OUT_CONTAINER_INDEX=

    local -r mymode="$2"
    if [ -z "$1" ] || [ -n "$mymode" -a "$mymode" != "--anystatus" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_get_container_id: wrong arguments: ${@} \n"
    fi

    if [ -n "${DSBLIB_CONTAINERS_CACHE["$1"]}" -a -z "$mymode" ]; then
        dsblib_split "${DSBLIB_CONTAINERS_CACHE["$1"]}" "$DSBLIB_CHAR_TAB"
        DSB_OUT_CONTAINER_ID="${DSBLIB_ARRAY_RESULT[0]}"
        DSB_OUT_CONTAINER_STATUS="${DSBLIB_ARRAY_RESULT[1]}"
        DSB_OUT_CONTAINER_SERVICE="${DSBLIB_ARRAY_RESULT[2]}"
        DSB_OUT_CONTAINER_INDEX="${DSBLIB_ARRAY_RESULT[3]}"
        if [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_RUNNING" ]; then
            return 0
        fi

        if [ "${1#*${DSBLIB_CHAR_INDEX}}" = "$1" ]; then
            local -r myContainerLabel="$DSB_OUT_CONTAINER_SERVICE"
        else
            local -r myContainerLabel="${DSB_OUT_CONTAINER_SERVICE}${DSBLIB_CHAR_INDEX}${DSB_OUT_CONTAINER_INDEX}"
        fi

        if [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_PAUSED" ]; then
            local mytip="Please unpause or restart it"
        else
            local mytip="Please restart it"
        fi

        dsb_error_exit "Container '$myContainerLabel' status: ${DSB_OUT_CONTAINER_STATUS}\n$mytip"
    fi

    dsb_parse_service_arg "$1"   # Note: 'dsb_set_box' is called here
    if   [ -z "$DSB_OUT_SERVICE_NAME" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_get_container_id: service name not specified"
    elif [ -z "$DSBLIB_LOWER_PROJECT" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_get_container_id: Empty DSBLIB_LOWER_PROJECT variable!"
    fi

    local -r myServiceName="$DSB_OUT_SERVICE_NAME"
    local -r myServiceIndex="${DSB_OUT_SERVICE_INDEX:-1}"
    local -r myContainer="${myServiceName}${DSBLIB_CHAR_INDEX}${myServiceIndex}"

    unset DSBLIB_CONTAINERS_CACHE["$1"]
    unset DSBLIB_CONTAINERS_CACHE["$myContainer"]

    local    myrunning=
    local    myline=
    local -a mylist
    mapfile -t mylist < <( docker container ls --all --format='{{.ID}}\t{{.Names}}\t{{.State}}' --filter "label=com.docker.compose.project=$DSBLIB_LOWER_PROJECT" )
    for myline in "${mylist[@]}" ; do
        dsblib_split "$myline" "$DSBLIB_CHAR_TAB"
        local myid="${DSBLIB_ARRAY_RESULT[0]}"
        local myname="${DSBLIB_ARRAY_RESULT[1]}"
        local mystatus="${DSBLIB_ARRAY_RESULT[2]}"

        dsblib_parse_container_name "$myname"  # Get DSB_OUT_CONTAINER_SERVICE & DSB_OUT_CONTAINER_INDEX
        if [ -z "$DSB_OUT_CONTAINER_INDEX" ]; then
            DSB_OUT_CONTAINER_SERVICE=
            continue  # skip 'compose run ...' container
        fi

        myrunning=1 # there are running containers

        if [ "$DSB_OUT_CONTAINER_SERVICE" = "$myServiceName" -a "$DSB_OUT_CONTAINER_INDEX" = "$myServiceIndex" ]; then
            DSB_OUT_CONTAINER_ID="$myid"
            DSB_OUT_CONTAINER_STATUS="$mystatus" # running | exited | paused
            DSBLIB_CONTAINERS_CACHE["$1"]="${DSB_OUT_CONTAINER_ID}${DSBLIB_CHAR_TAB}${DSB_OUT_CONTAINER_STATUS}${DSBLIB_CHAR_TAB}${DSB_OUT_CONTAINER_SERVICE}${DSBLIB_CHAR_TAB}${DSB_OUT_CONTAINER_INDEX}"
            if [ "$1" != "$myContainer" ]; then
                DSBLIB_CONTAINERS_CACHE["$myContainer"]="${DSBLIB_CONTAINERS_CACHE["$1"]}"
            fi
            break
        fi

        DSB_OUT_CONTAINER_SERVICE=
        DSB_OUT_CONTAINER_INDEX=
    done

    if [ "${1#*${DSBLIB_CHAR_INDEX}}" = "$1" ]; then
        local -r myContainerLabel="$myServiceName"
    else
        local -r myContainerLabel="$myContainer"
    fi

    if [ -z "$DSB_OUT_CONTAINER_ID" ]; then
        # Сheck the availability of the service in the Dsb project
        dsb_validate_service_arg "$myServiceName" 1>&2

        if [ -n "$mymode" ]; then
            return 1 # service is configured - may be containers not running
        fi

        if [ -z "$myrunning" ]; then
            dsb_error_exit "Please start Dsb project"
        fi
        dsb_error_exit "Container '$myContainerLabel' not found"

    elif [ "$DSB_OUT_CONTAINER_STATUS" != "$DSBLIB_STATUS_RUNNING" -a -z "$mymode" ]; then
        if [ "$DSB_OUT_CONTAINER_STATUS" = "$DSBLIB_STATUS_PAUSED" ]; then
            local mytip="Please unpause or restart it"
        else
            local mytip="Please restart it"
        fi
        dsb_error_exit "Container '$myContainerLabel' status: ${DSB_OUT_CONTAINER_STATUS}\n$mytip"
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

# Usage: dsb_run_command <service> <UID:GID> <command> [ ...<parameters> ]
function dsb_run_command()
{
    dsb_get_container_id "$1"
    local -r myContainerID="$DSB_OUT_CONTAINER_ID"
    local -r myServiceName="$DSB_OUT_CONTAINER_SERVICE"

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
    fi

    local myCWD="-"
    if dsblib_set_container_space "$myContainerID" "$PWD" ; then
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

    dsblib_resolve_args "$myServiceName" "$@"
    docker exec "-i${myterm}" "${myEnv[@]}" --user "$myExecUser" "$myContainerID" \
        sh /dsbutils/exec.sh "$myExecUser" "${TERM:--}" "${myUmask:--}" "$myCWD" "${DSBLIB_RESOLVED_ARGS[@]}"
}

# Usage: dsb_run_as_user <service> <command> [ ...<parameters> ]
function dsb_run_as_user()
{
    if [ "$DSB_UID" = 0 ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_run_as_user: Cannot run in root mode!\n"
    fi

    if [ -z "$1" -o -z "$2" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_run_as_user: wrong arguments: ${@} \n"
    fi

    local -r myService="$1"
    local -r myCommand="${2@Q}"
    shift 2  # skip <service> & <command>

    local -r myScript="MYUIDGID=${DSB_UID_GID@Q}"'
if [ -n "$DSB_UID_GID" -a "$DSB_UID_GID" != "$MYUIDGID" ]; then echo "The container was launched from the different account ${DSB_UID_GID}!" 1>&2 ; exit 126 ; fi
if ! hash '$myCommand' 2>/dev/null ; then echo "Command '$myCommand' not found in the container" 1>&2 ; exit 127 ; fi ; '$myCommand' "$@"'
    dsb_run_command "$myService" "$DSB_UID_GID" - -l -c "dsbnop:$myScript" "dsbnop:$DSBLIB_BINCMD" "$@"
}

# Usage: dsb_run_as_root <service> <command> [ ...<parameters> ]
function dsb_run_as_root()
{
    if [ -z "$1" -o -z "$2" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_run_as_root: wrong arguments: ${@} \n"
    fi

    local -r myService="$1"
    local -r myCommand="${2@Q}"
    shift 2  # skip <service> & <command>

    local -r myScript="MYUIDGID=${DSB_UID_GID@Q}"'
if [ -n "$DSB_UID_GID" -a "$MYUIDGID" != "0:0" -a "$DSB_UID_GID" != "$MYUIDGID" ]; then echo "The container was launched from the different account ${DSB_UID_GID}!" 1>&2 ; exit 126 ; fi
if ! hash '$myCommand' 2>/dev/null ; then echo "Command '$myCommand' not found in the container" 1>&2 ; exit 127 ; fi ; '$myCommand' "$@"'
    dsb_run_command "$myService" "0:0" - -l -c "dsbnop:$myScript" "dsbnop:$DSBLIB_BINCMD" "$@"
}

function dsb_docker_compose()
{
    dsb_set_box 1>&2  # never use STDOUT

    if [ -z "$DSBLIB_PROJECT_NAME" ]; then
        dsb_error_exit "${DSBLIB_BINCMD}: dsb_docker_compose: Empty DSBLIB_PROJECT_NAME variable!"
    fi

    local myCompose="docker compose"
    if [ "$DSB_STANDALONE_SYNTAX" = true ] && hash docker-compose > /dev/null 2>/dev/null ; then
        myCompose="docker-compose"
    fi

    if [ "$1" = "--dsblib-echo" ]; then
        shift
        dsb_message "$myCompose --project-name $DSBLIB_PROJECT_NAME ${@}"
    fi

    local myrc=
    pushd "$PWD" > /dev/null
    dsb_exec cd "$DSB_COMPOSE"
    $myCompose --project-name "$DSBLIB_PROJECT_NAME" --project-directory "$DSB_COMPOSE" "$@"
    myrc="$?"
    popd > /dev/null

    # Resetting internal cache variables in some cases
    case "$1" in
        config | cp | exec | events | images | kill | logs | ls | pause | port | ps | pull | push | restart | run | start | stop | top | unpause | version )
            ;;
        * )
            dsblib_reset_cache
            ;;
    esac

    return "$myrc"
}

############################

dsblib_reset_options

if [ "$PWD" != "$DSB_WORKDIR" ]; then
    dsb_error_exit "Please do not use Dsb with directory symlinks (${PWD} => ${DSB_WORKDIR})\n"
fi

declare -r DSBLIB_LIB_OK=1