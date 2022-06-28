#
#  Execute custom subcommand 
#

if ! dsb_set_box --check || [ ! -f "$DSB_BOX/bin/$DSBLIB_DSBARG" ] ; then
    dsblib_error_exit "${DSBLIB_BINCMD}: '$DSBLIB_DSBARG' is not a subcommand"
fi

export DSB_SCRIPT_PATH="$DSB_BOX/bin/$DSBLIB_DSBARG"
export DSB_SCRIPT_NAME="${DSB_SCRIPT_PATH##*/}"

if [ -x "$DSB_SCRIPT_PATH" ] ; then
    exec "$DSB_SCRIPT_PATH" "$@"    # Run as executable ...
fi

DSBLIB_BINCMD="$DSB_SCRIPT_NAME"
. "$DSB_SCRIPT_PATH"                # Run as host-script ...