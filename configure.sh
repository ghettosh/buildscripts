#########################
#
#  Welcome traveller
#    There is nothing to configure yet, so sit tight
#
#########################

# Do not look here, use the fabfile in ./fabric/

function _die(){
    echo "$@" 1>&2
}

# Set our method of parallel-commands. This drastically speeds up build times
# by deserializing ssh calls.
# If you don't have ssh, you will use my ghetto-pssh, gpssh.. 
# If you wish to use your own (sshpt, for_loop.sh, whatever, just make sure
# that you create function _pssh(){} like I did below
which pssh > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
# One day soon I'll support gpssh
#    PSSH="./gpssh"
#    function _pssh(){
#        ${PSSH} "$@"
#    }    
# but that is not today.
    _die "FATAL: Sorry, you must have pssh (parallel-ssh) installed to continue"
    exit 1
else
    PSSH="`which pssh`"
    HOSTLIST="./hypervisors.txt"
    if [[ ! -f ${HOSTLIST} ]]; then
        _die "FATAL: You must create a host list first"
        _die "FATAL: Put your hosts in ${HOSTLIST}"
        exit 1
    elif [[ $(wc -l ${HOSTLIST} | awk '{print $1}') -eq 0 ]]; then
        _die "FATAL: Your host list (${HOSTLIST}) is empty."
        exit 1
    fi
    function _pssh(){
        ${PSSH} -l root -h ${HOSTLIST} -t300 "$@" || \
            _die "pssh command failed somewhere: $@"
    }    
fi

#########################
