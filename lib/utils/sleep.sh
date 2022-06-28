#!/usr/bin/env sh
#
#   Usage: sh /dsbutils/sleep.sh

MYSLEEPPID=

shutdown()
{
    echo 
    echo "Trapped SIGTERM/SIGINT so shutting down ..."
    if [ -n "$MYSLEEPPID" ]; then
        kill "$MYSLEEPPID"
        MYSLEEPPID=
    fi
    exit 0
}

trap shutdown TERM INT

echo "Waiting shutdown signal ..."
while [ 1 ]; do
    sleep 30 &
    MYSLEEPPID="$!"
    wait  "$MYSLEEPPID"
done
exit 0