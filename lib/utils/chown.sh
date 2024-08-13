#!/usr/bin/env sh
#
#   Usage: sh /dsbutils/chown.sh <UID:GID>    ...<filePath>
#          sh /dsbutils/chown.sh <UID:GID> -R ...<filePath>

MYNAME=
MYGROUP=
MYUIDGID="$1"
shift

MYUID="${MYUIDGID%:*}"
MYGID="${MYUIDGID#*:}"
if [ -z "$MYUID" -o "$MYUID" = "$MYUIDGID" -o -z "$MYGID" -o "$MYGID" = "$MYUIDGID" ]; then
    echo "$0: <UID:GID> parameter not defined or has wrong value" 1>&2
    exit 100
fi

if [ "$#" = 0 ]; then
    echo "$0: file parameters not defined" 1>&2
    exit 100
fi

if hash id 2>/dev/null && [ "$( id -u )" != 0 ]; then
    echo "$0: Must be run as root only!" 1>&2
    exit 100
fi

if ! hash cut 2>/dev/null ; then
    echo "$0: Command 'cut' not found" 1>&2
    exit 100
fi

if ! hash sed 2>/dev/null ; then
    echo "$0: Command 'sed' not found" 1>&2
    exit 100
fi

if [ ! -f /etc/group ]; then
    echo "$0: File '/etc/group' not found" 1>&2
    exit 100
fi

if [ ! -f /etc/passwd ]; then
    echo "$0: File '/etc/passwd' not found" 1>&2
    exit 100
fi

# Parse /etc/passwd
for mystr in $( cut -d: -f1,3 < /etc/passwd ) ; do
    if [ "${mystr##*:}" = "$MYUID" ]; then
        MYNAME="${mystr%%:*}"
        break
    fi
done
if [ -z "$MYNAME" ]; then
    echo "$0: User id '$MYUID' not found in /etc/passwd" 1>&2
    exit 100
fi

# Parse /etc/group
for mystr in $( cut -d: -f1,3 < /etc/group ) ; do
    if [ "${mystr##*:}" = "$MYGID" ]; then
        MYGROUP="${mystr%%:*}"
        break
    fi
done
if [ -z "$MYGROUP" ]; then
    echo "$0: Group id '$MYGID' not found in /etc/group" 1>&2
    exit 100
fi

if [ "$1" = "-R" ]; then
    shift
    MYCMD="chown -R"
else
    MYCMD="chown"
fi

if [ "$#" = 0 ]; then
    echo "$0: missing operands" 1>&2
    exit 100
fi

$MYCMD "$MYNAME:$MYGROUP" "$@"
exit "$?"