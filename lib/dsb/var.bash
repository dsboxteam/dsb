#
#   Print to STDOUT the values of the Dsb Environment variables
#

declare -r MYVARNAME="$1"

if [ "$#" -gt 1 ]; then
    dsb_yellow_message "Usage: $DSBLIB_DSBCMD [ VARIABLE_NAME ]"
    dsb_error_exit
fi

if ! dsb_set_box --check ; then
    dsb_red_message "The '.dsb' subdirectory is not found in the '${PWD}' directory or any parent up to '/'\n"
    dsb_error_exit
fi

function dsblib__var_echo_vars()
{
    local    myPrefix=
    local    myvar=
    local    myval=
    local -a myarr

    for myPrefix in "$@" ; do
        eval 'myarr=( "${!'"$myPrefix"'@}" )'
        for   myvar in "${myarr[@]}" ; do
            if [ "${myvar#DSB_CONTAINER_}" = "$myvar" -a "${myvar#DSB_SCRIPT_}" = "$myvar" ]; then
                myval="${!myvar}"
                echo "${myvar}=${myval@Q}" 1>&2
            fi
        done
    done
}

if [ -z "$MYVARNAME" ]; then
    dsblib__var_echo_vars  "DSB_" "DSBUSR_" "COMPOSE_" "DOCKER_"
elif [ "${MYVARNAME#-}" = "$MYVARNAME" ] && [ "${!MYVARNAME-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
    echo "${!MYVARNAME}"
else
    dsb_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: variable '$MYVARNAME' is not defined"
    dsb_error_exit
fi

dsblib_exit