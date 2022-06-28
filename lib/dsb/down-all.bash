#
#  Shutdown all Dsb projects (containers & networks)
#

declare -r MYOLDPREFIX="dsbproject-"

dsblib_check_compose_version

if dsb_set_box --check ; then
    "$DSBLIB_CMDPATH" down
fi

sleep 1

dsblib_message "\nRemoving dsb containers..."
function my_remove_services()
{
    local    myLine=
    local -a myList
    mapfile -t myList < <( docker container ls --all --format='{{.ID}};{{.Names}};{{.Image}}' )
    for myLine in "${myList[@]}" ; do
        local myid="${myLine%%;*}"
        myLine="${myLine#*;}"
        local myname="${myLine%%;*}"
        local myimage="${myLine#*;}"

        if [ "${myname#${DSBLIB_PROJECT_PREFIX}}" != "$myname" -o "${myname#${MYOLDPREFIX}}" != "$myname" ]; then
            docker container stop     "$myid"
            docker container rm -f -v "$myid"
        fi
    done
}
my_remove_services

dsblib_message "\nRemoving dsb networks..."
function my_remove_networks()
{
    local    myLine=
    local -a myList
    mapfile -t myList < <( docker network ls --format '{{.ID}};{{.Name}}' )
    for myLine in "${myList[@]}"
    do
        local myid="${myLine%%;*}"
        local myname="${myLine#*;}"
        if [ "${myname#${DSBLIB_PROJECT_PREFIX}}" != "$myname" -o "${myname#${MYOLDPREFIX}}" != "$myname" ]; then
            docker network rm "$myid"
        fi
    done
}
my_remove_networks

dsblib_exit