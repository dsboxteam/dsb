#!/usr/bin/env sh
#
#   Usage: sh /dsbutils/adduser.sh [ ( <UID:GID> | - ) [ ( <userHomeDir> | - ) [ <skelDir> ] ] ]
#

MYNAME="dsbuser"
MYGROUP="dsbuser"

MYUIDGID="${1:-$DSB_UID_GID}"
if [ -z "$MYUIDGID" -o "$MYUIDGID" = "-" ]; then
    MYUIDGID="$DSB_UID_GID"
fi
MYUID="${MYUIDGID%:*}"
MYGID="${MYUIDGID#*:}"
if [ -z "$MYUID" -o "$MYUID" = "$MYUIDGID" -o -z "$MYGID" -o "$MYGID" = "$MYUIDGID" ]; then
    echo "$0: DSB_UID_GID variable or first argument (UID:GID) is not defined or has wrong value" 1>&2
    exit 100
fi

MYHOME="$2"

MYSKEL="${3%/}"
if [ -z "$MYSKEL" -o "${MYSKEL#*.}" != "$MYSKEL" -o "${MYSKEL#* }" != "$MYSKEL" -o "${MYSKEL#/}" = "$MYSKEL" ]; then
    if   [ -d "/dsbskel" ]; then
        MYSKEL="/dsbskel"
    elif [ -d "/etc/skel" ]; then
        MYSKEL="/etc/skel"
    else
        MYSKEL=
    fi
elif [ -d "$MYSKEL" ]; then
    MYSKEL="$( cd "$MYSKEL"; pwd )"
    if [ "$MYSKEL" = "/" ]; then
        MYSKEL=
    fi
else
    MYSKEL=
fi

MYWHICH=
my_which()
{
    MYWHICH=
    if   [ -x "/bin/$1" ]; then
        MYWHICH="/bin/$1"
        return 0
    elif [ -x "/usr/bin/$1" ]; then
        MYWHICH="/usr/bin/$1"
        return 0
    elif [ -x "/usr/local/bin/$1" ]; then
        MYWHICH="/usr/local/bin/$1"
        return 0
    elif [ -x "/sbin/$1" ]; then
        MYWHICH="/sbin/$1"
        return 0
    elif [ -x "/usr/sbin/$1" ]; then
        MYWHICH="/usr/sbin/$1"
        return 0
    elif [ -x "/usr/local/sbin/$1" ]; then
        MYWHICH="/usr/local/sbin/$1"
        return 0
    fi
    return 1
}

if ! hash id 2>/dev/null ; then
    echo "$0: Command 'id' not found" 1>&2
    exit 100
elif [ "$( id -u )" != 0 ]; then
    echo "$0: Must be run as root only!" 1>&2
    exit 100
fi

# Set dsb container flag - /.dsbservice file
if [ ! -f /.dsbservice -o -n "$DSB_SERVICE" ]; then
    echo "${DSB_SERVICE:-[dsb]}" > /.dsbservice
fi
chmod "a=r" /.dsbservice

if ! hash cut 2>/dev/null ; then
    echo "$0: Command 'cut' not found" 1>&2
    exit 100
fi

if ! hash sed 2>/dev/null ; then
    echo "$0: Command 'sed' not found" 1>&2
    exit 100
fi

MYOSNAME="$(
    if [ -f /etc/os-release ]; then
        ID=
        ID_LIKE=
        . /etc/os-release
        if [ "$ID" = debian -o "$ID_LIKE" = debian -o "$ID" = ubuntu -o "$ID_LIKE" = ubuntu ]; then
            echo debian
        elif [ "$ID" = alpine ]; then
            echo alpine
        elif [ "$ID" = fedora -o "$ID_LIKE" = fedora -o "$ID" = ol -o "$ID_LIKE" = ol ]; then
            echo fedora
        elif [ "$ID" = centos ]; then
            echo centos
        elif [ "$ID" = amzn  ]; then
            echo amzn
        elif [ "$ID" = clear-linux-os ]; then
            echo clear-linux-os
        elif [ "$ID" = buildroot ]; then
            echo buildroot
        fi
    elif hash busybox 2>/dev/null ; then
        echo busybox
    fi
)"

MYSHELL=
if   my_which bash ; then
    MYSHELL="$MYWHICH"
elif my_which sh   ; then
    MYSHELL="$MYWHICH"
else
    echo "$0: Login shell (sh or bash) not found" 1>&2
    exit 100
fi

# Set/update DSB_SERVICE and DSB_UID_GID in /etc/environment
my_etc_environment()
{
    if [ -z "$2" ]; then
        return 0
    fi
    if [ ! -f /etc/environment ]; then
        echo "${1}=${2}" >> /etc/environment
        chmod a+r,go-w /etc/environment
        return 0
    fi
    sed -i -r '/^\s*'"$1"'=/d' /etc/environment
    echo "${1}=${2}" >> /etc/environment
}
my_etc_environment  DSB_SERVICE "$DSB_SERVICE"
my_etc_environment  DSB_UID_GID "$DSB_UID_GID"

#
# See: https://manpages.debian.org/stretch/login/su.1.en.html
#      https://manpages.debian.org/stretch/login/login.defs.5.en.html
if [ -f /etc/login.defs ]; then
    sed -i -r '/^\s*ENV_SUPATH\s/d' /etc/login.defs
    sed -i -r '/^\s*ENV_PATH\s/d'   /etc/login.defs
fi
echo "ENV_SUPATH  $PATH" >> /etc/login.defs
echo "ENV_PATH    $PATH" >> /etc/login.defs

# Add dsbhost to /etc/hosts
my_dsbhost()
{
    if hash cat 2>/dev/null ; then
        local myhosts="$( cat /etc/hosts )"
        if [ "${myhosts% dsbhost*}" != "$myhosts" ]; then
            return 0
        fi
    fi

    if ! hash awk 2>/dev/null ; then
        echo "$0: my_dsbhost: Command 'awk' not found" 1>&2
        return 0
    fi

    # Workaround for mawk 1.3.3 Nov 1996
    local myStrToNum='strtonum("0x" hex)'
    if [ "$( awk 'END { print strtonum("0xFF")}' < /dev/null 2>/dev/null )" != "255" ]; then
        myStrToNum='"0x" hex'
    fi

    local myhostip="$(
    awk ' 
BEGIN { gateway = "" }
{
    while (getline) {
        if (gateway == "" && $2 == "00000000" &&  $3 != "00000000" && $3 != "Gateway") {
            gateway = $3
        }
    }
}
END {
    if (1 == match(gateway,"^[0-9A-Fa-f]+$") && length(gateway) == 8) {
        ip = ""
        for (i=1; i<=7 ;i=i+2 ) {
            hex = substr(gateway,i,2)
            if (ip != "") ip =  "." ip
            ip = sprintf("%d", '"$myStrToNum"') ip
        }
        print ip
    }
}
' <  /proc/net/route )"
    if [ -n "$myhostip" -a "$myhostip" != "0.0.0.0" ]; then
        echo  >> /etc/hosts
        echo "$myhostip    dsbhost dsbhost.localhost" >> /etc/hosts
    fi
}
my_dsbhost

# Parse /etc/group
myFound=
if [ -f /etc/group ]; then
    for mystr in $( cut -d: -f1,3 < /etc/group ) ; do
        myTmpName="${mystr%%:*}"
        myTmpGID="${mystr##*:}"
        if [ "$myTmpGID" = "$MYGID" ]; then
            MYGROUP="$myTmpName"
            myFound=1
            break;
        elif [ "$myTmpName" = "$MYGROUP" ]; then  # just in case
            MYGROUP="${MYGROUP}${MYGID}"
        fi
    done
fi

# Add new group
my_add_group()
{
    case "$MYOSNAME" in
        debian  ) if hash addgroup 2>/dev/null ; then addgroup --gid "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        alpine  ) if hash addgroup 2>/dev/null ; then addgroup -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        busybox ) if hash addgroup 2>/dev/null ; then addgroup -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        fedora  ) if hash groupadd 2>/dev/null ; then groupadd -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        centos  ) if hash groupadd 2>/dev/null ; then groupadd -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        amzn    ) if hash groupadd 2>/dev/null ; then groupadd -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        clear-linux-os ) if hash groupadd 2>/dev/null ; then groupadd -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
        buildroot      ) if hash addgroup 2>/dev/null ; then addgroup -g "$MYGID" "$MYGROUP" >/dev/null ; return 0; fi ;;
    esac
    echo "${MYGROUP}:x:${MYGID}:" >> /etc/group
    echo "${MYGROUP}:!::"         >> /etc/gshadow
    chmod go=r   /etc/group
    chmod go-rwx /etc/gshadow
}
if [ "$myFound" != 1 ]; then
    my_add_group
fi

# Parse /etc/passwd
myUserFound=
if [ -f /etc/passwd ]; then
    for mystr in $( cut -d: -f1,3,4,6,7 < /etc/passwd ) ; do
        myTmpName="${mystr%%:*}"  ; mystr="${mystr#*:}"
        myTmpUID="${mystr%%:*}"   ; mystr="${mystr#*:}"
        myTmpGID="${mystr%%:*}"   ; mystr="${mystr#*:}"
        myTmpHOME="${mystr%%:*}"  ; mystr="${mystr#*:}"
        myTmpSHELL="${mystr%%:*}" ; mystr="${mystr#*:}"
        if [ "$MYUID" = "$myTmpUID" ]; then
            MYNAME="$myTmpName"
            myUserFound=1
            break
        fi
    done
fi

# NOTE: You can mount $DSB_BOX/home/<container> to /dsbhome or /home in yaml-files
if [ -z "$MYHOME" -o "$MYHOME" = "-" ]; then
    if [ -d "/dsbhome" ]; then
        MYHOME="/dsbhome/$MYNAME"
    else
        MYHOME="/home/$MYNAME"
    fi
fi

MYHOME="${MYHOME%/}"
if [ -z "$MYHOME" -o "$MYHOME" = "/" -o "${MYHOME#/}" = "$MYHOME" ]; then
    echo "$0: Bad user home directory: " 1>&2
    exit 100
fi

################ Add new user ...

mkdir -p "${MYHOME%/*}" # Init the parent directory of the user's home directory

my_create_home()
{
    if [ ! -d "$MYHOME" ]; then
        mkdir -p "$MYHOME"
        if [ -n "$MYSKEL" -a "$MYSKEL" != "/" ]; then
            if hash cp 2>/dev/null ; then
                cp -pPR "$MYSKEL"/. "$MYHOME"
            else
                echo "$0: Command 'cp' not found. Couldn't copy $MYSKEL to $MYHOME" 1>&2
            fi
        fi
        chmod -R "u=rwX,go-rwx"      "$MYHOME"
        chown -R "${MYUID}:${MYGID}" "$MYHOME"
    fi
}

my_add_user()
{
    my_create_home

    if [ -d "$MYHOME" ]; then
        case "$MYOSNAME" in
            debian  ) if hash adduser 2>/dev/null ; then adduser --no-create-home --quiet --disabled-password --gecos "" --uid "$MYUID" --gid "$MYGID" --shell "$MYSHELL" --home "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            alpine  ) if hash adduser 2>/dev/null ; then adduser -D -u "$MYUID" -G "$MYGROUP" -s "$MYSHELL" -H -h "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            busybox ) if hash adduser 2>/dev/null ; then adduser -D -u "$MYUID" -G "$MYGROUP" -s "$MYSHELL" -H -h "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            fedora  ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -M -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            centos  ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -M -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            amzn    ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -M -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            clear-linux-os ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -M -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            buildroot      ) if hash adduser 2>/dev/null ; then adduser -D -u "$MYUID" -G "$MYGROUP" -s "$MYSHELL" -H -h "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        esac
    else
        MYOPTSKEL=
        if [ -n "$MYSKEL" ]; then
            MYOPTSKEL="-k $MYSKEL"
        fi
        case "$MYOSNAME" in
            debian  ) if hash adduser 2>/dev/null ; then adduser --quiet --disabled-password --gecos "" --uid "$MYUID" --gid "$MYGID" --shell "$MYSHELL" --home "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
            alpine  ) if hash adduser 2>/dev/null ; then adduser -D -u "$MYUID" -G "$MYGROUP" -s "$MYSHELL" -h "$MYHOME" $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
            busybox ) if hash adduser 2>/dev/null ; then adduser -D -u "$MYUID" -G "$MYGROUP" -s "$MYSHELL" -h "$MYHOME" $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
            fedora  ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -d "$MYHOME" -m $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
            centos  ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -d "$MYHOME" -m $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
            amzn    ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -d "$MYHOME" -m $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
            clear-linux-os ) if hash useradd 2>/dev/null ; then useradd    -u "$MYUID" -g "$MYGID"   -s "$MYSHELL" -d "$MYHOME" -m $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
            buildroot      ) if hash adduser 2>/dev/null ; then adduser -D -u "$MYUID" -G "$MYGROUP" -s "$MYSHELL" -h "$MYHOME" $MYOPTSKEL "$MYNAME" >/dev/null ; return 0; fi ;;
        esac
    fi

    # add user manually...

    echo "${MYNAME}:x:${MYUID}:${MYGID}:${MYNAME}:${MYHOME}:${MYSHELL}" >> /etc/passwd
    chmod go=r /etc/passwd

    if hash date 2>/dev/null && hash expr 2>/dev/null ; then
        MYCURRDAY="$( date +%s )"
        MYCURRDAY="$( expr "$MYCURRDAY" / 86400 )"
    else
        MYCURRDAY=18996
    fi
    echo "${MYNAME}:*:${MYCURRDAY}:0:99999:7:::" >> /etc/shadow
    chmod go-rwx /etc/shadow
}

if [ "$myUserFound" != 1 ]; then
    my_add_user
    chmod -R "u=rwX,go-rwx"  "$MYHOME"
    exit 0      ######## EXIT
fi

################ Modify existing user ...

# Add user to group:
my_add_to_group()
{
    case "$MYOSNAME" in
        debian  ) if hash adduser  2>/dev/null ; then adduser  "$MYNAME"  "$MYGROUP" >/dev/null ; return 0; fi ;;
        alpine  ) if hash addgroup 2>/dev/null ; then addgroup "$MYNAME"  "$MYGROUP" >/dev/null ; return 0; fi ;;
        busybox ) if hash addgroup 2>/dev/null ; then addgroup "$MYNAME"  "$MYGROUP" >/dev/null ; return 0; fi ;;
        fedora  ) if hash usermod  2>/dev/null ; then usermod -a -G "$MYGROUP" "$MYNAME" >/dev/null ; return 0; fi ;;
        centos  ) if hash usermod  2>/dev/null ; then usermod -a -G "$MYGROUP" "$MYNAME" >/dev/null ; return 0; fi ;;
        amzn    ) if hash usermod  2>/dev/null ; then usermod -a -G "$MYGROUP" "$MYNAME" >/dev/null ; return 0; fi ;;
        clear-linux-os ) if hash usermod 2>/dev/null ; then usermod -a -G "$MYGROUP" "$MYNAME" >/dev/null ; return 0; fi ;;
        # buildroot ) BusyBox may be compiled with FEATURE_ADDUSER_TO_GROUP disabled. This is the case in cirros:latest docker image.
    esac

    for mystr in $( cut -d: -f1,4 < /etc/group ) ; do
        myTmpGroupName="${mystr%%:*}"
        if [ "$myTmpGroupName" = "$MYGROUP" ]; then
            myTmpGroupUsers="${mystr##*:}"
            if [   "$myTmpGroupUsers" = "$MYNAME" \
                -o "${myTmpGroupUsers%,${MYNAME}}"   != "$myTmpGroupUsers" \
                -o "${myTmpGroupUsers#${MYNAME},}"   != "$myTmpGroupUsers" \
                -o "${myTmpGroupUsers#*,${MYNAME},}" != "$myTmpGroupUsers" ]
            then
                return 0
            fi

            if [ -z "$myTmpGroupUsers" ]; then
                sed -i -r 's|^('"$MYGROUP"':[^:]*:'"$MYGID"'):.*$|\1:'"$MYNAME"'|g' /etc/group
                sed -i -r 's|^('"$MYGROUP"':[^:]*:[^:]*):.*$|\1:'"$MYNAME"'|g'      /etc/gshadow
            else
                sed -i -r 's|^('"$MYGROUP"':[^:]*:'"$MYGID"':.*)$|\1,'"$MYNAME"'|g' /etc/group
                sed -i -r 's|^('"$MYGROUP"':[^:]*:[^:]*:.*)$|\1,'"$MYNAME"'|g'      /etc/gshadow
            fi
            chmod go-rwx /etc/gshadow
            return 0
        fi
    done
}
if [ "$myTmpGID" != "$MYGID" ]; then
    my_add_to_group
fi

# Modify user's shell:
my_mod_shell()
{
    case "$MYOSNAME" in
        debian  ) if hash usermod 2>/dev/null ; then usermod -s "$MYSHELL" "$MYNAME" >/dev/null ; return 0; fi ;;
        alpine  ) if hash usermod 2>/dev/null ; then usermod -s "$MYSHELL" "$MYNAME" >/dev/null ; return 0; fi ;;
        # busybox ) - modifying login shell is not supported
        fedora  ) if hash usermod 2>/dev/null ; then usermod -s "$MYSHELL" "$MYNAME" >/dev/null ; return 0; fi ;;
        centos  ) if hash usermod 2>/dev/null ; then usermod -s "$MYSHELL" "$MYNAME" >/dev/null ; return 0; fi ;;
        amzn    ) if hash usermod 2>/dev/null ; then usermod -s "$MYSHELL" "$MYNAME" >/dev/null ; return 0; fi ;;
        clear-linux-os ) if hash usermod 2>/dev/null ; then usermod -s "$MYSHELL" "$MYNAME" >/dev/null ; return 0; fi ;;
        # buildroot ) - modifying login shell is not supported
    esac
    sed -i -r 's|^('"$MYNAME"':[^:]*:[^:]*:[^:]*:[^:]*:[^:]*):.*$|\1:'"$MYSHELL"'|g' /etc/passwd
}
if [ "$myTmpSHELL" != "$MYSHELL" ]; then
    my_mod_shell
fi

# Create & Modify user's home directory:
my_mod_home()
{
    case "$MYOSNAME" in
        debian  ) if hash usermod 2>/dev/null ; then usermod -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        alpine  ) if hash usermod 2>/dev/null ; then usermod -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        # busybox ) - modifying user's home is not supported
        fedora  ) if hash usermod 2>/dev/null ; then usermod -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        centos  ) if hash usermod 2>/dev/null ; then usermod -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        amzn    ) if hash usermod 2>/dev/null ; then usermod -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        clear-linux-os ) if hash usermod 2>/dev/null ; then usermod -d "$MYHOME" "$MYNAME" >/dev/null ; return 0; fi ;;
        # buildroot ) - modifying user's home is not supported
    esac
    sed -i -r 's|^('"$MYNAME"':[^:]*:[^:]*:[^:]*:[^:]*):[^:]*:(.*)$|\1:'"$MYHOME"':\2|g' /etc/passwd
}
my_create_home
if [ "$myTmpHOME" != "$MYHOME" ]; then
    my_mod_home
fi

exit 0