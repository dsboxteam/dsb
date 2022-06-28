#
#   Print to STDOUT the values of the Dsb Environment variables
#

declare -r MYVARNAME="$1"

if ! dsb_set_box --check ; then
    dsblib_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: Directory '.dsb' not found for the directory '${DSB_WORKDIR}' or any parent up to '/'"
    dsblib_error_exit
fi

function my_echo_vars()
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
    my_echo_vars  "DSB_" "COMPOSE_" "DOCKER_"
elif [ "${MYVARNAME#-}" = "$MYVARNAME" ] && [ "${!MYVARNAME-$DSBLIB_NOTSET}" != "$DSBLIB_NOTSET" ]; then
    echo "${!MYVARNAME}"
else
    dsblib_red_message "$DSBLIB_BINCMD $DSBLIB_DSBARG: variable '$MYVARNAME' is not defined"
    dsblib_error_exit
fi

dsblib_exit