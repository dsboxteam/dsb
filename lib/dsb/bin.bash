#
#  Execute custom subcommand 
#

dsb_set_box
if [ ! -f "$DSB_BOX/bin/$DSBLIB_DSBARG" ] ; then
    dsb_error_exit "${DSBLIB_BINCMD}: '$DSBLIB_DSBARG' is not a subcommand"
fi

export DSB_SCRIPT_PATH="$DSB_BOX/bin/$DSBLIB_DSBARG"
export DSB_SCRIPT_NAME="${DSB_SCRIPT_PATH##*/}"

dsblib_check_uid_gid

if [ -x "$DSB_SCRIPT_PATH" ] ; then
    "$DSB_SCRIPT_PATH" "$@"  # Run as executable
else
    DSBLIB_BINCMD="$DSB_SCRIPT_NAME"
    . "$DSB_SCRIPT_PATH"
fi
dsblib_exit "$?"