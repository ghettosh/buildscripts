#!/usr/bin/env bash

# Sorry, this is kind of complicated.
# This script will take the 4th octet from br0 and apply it to the subnets
# listed in the array. 
#

MASTERIF=eth0                          # Take the 4th octet from this interface
declare -A eth          
eth["1"]="192.168.20.0/24"            # set eth1 to 192.168.20.0/24
eth["2"]="192.168.10.0/24"            # set eth2 to 192.168.10.0/24
CFGPATH=/etc/sysconfig/network-scripts
LINKSTAT=
OCTET4=
DEV=
SUBNET=
SETIPADDR=true                        # Actually set an IP on the hypervisor
                                      # on the bridge. Do not use this in prod


echo "DEBUG: Figuring out what I should be"
LINKSTAT="$(ip lin sh dev ${MASTERIF} | awk '/,UP,/ {print "UP"}')"
if [[ "$LINKSTAT"x == "x" ]]; then
    echo "FATAL: Originator interface: $MASTERIF is not up" 1>&2
    echo "FATAL: Cannot continue"                           1>&2
    exit 1
else
    echo "DEBUG: Originator interface: $MASTERIF is up"
    OCTET4="$(ip a sh dev ${MASTERIF} | \
        awk '/inet /{gsub("/.*",""); split($2,a,"."); print a[4]}')"
    if [[ "$OCTET4"x == "x" ]]; then
        echo "FATAL: Cannot determine the 4th octet of $MASTERIF" 1>&2
        echo "FATAL: Cannot continue"                             1>&2
        exit 1
    fi
fi

for i in ${!eth[@]}; do
    DEV=$i
    SUBNET=${eth[$i]}
    NMSK=$(ipcalc -m $SUBNET)
    echo "doing eth${DEV} -> br${DEV}:${SUBNET}${OCTET4}"
    for D in eth$DEV br$DEV; do
        CFGFILE="ifcfg-${D}"
        CFG=${CFGPATH}/${CFGFILE}
        [ -f ${CFG} ] && { echo "DEBUG: Backing up ${D}"; \
            cp ${CFG} $HOME/backup-${D}.`date +%s`; }
        if [[ $D =~ eth ]]; then
            MAC="$(ip lin sh dev ${D} | awk '/ether/ {print $2}')"
            echo "DEVICE=${D}"                          > $CFG 
            echo "HWADDR=${MAC}"                        >> $CFG 
            echo "ONBOOT=yes"                           >> $CFG   
            echo "BRIDGE=br${DEV}"                      >> $CFG
        elif [[ $D =~ br ]]; then
            echo "DEVICE=${D}"                          > $CFG
            echo "TYPE=Bridge"                          >> $CFG
            echo "BOOTPROTO=static"                     >> $CFG
            echo "ONBOOT=yes"                           >> $CFG
            echo "DELAY=0"                              >> $CFG
            echo "STP=yes"                              >> $CFG
            echo "IPV6INIT=yes"                         >> $CFG
            echo "IPV6_AUTOCONF=no"                     >> $CFG
            if $SETIPADDR ; then
                echo "IPADDR=${SUBNET/.0*/.${OCTET4}}"  >> $CFG
                echo "${NMSK}"                          >> $CFG
            fi
        fi
    done
    echo "DEBUG: Finished writing interface files. if-Down/Up'ing"
    ifdown br${DEV}
    ifup br${DEV}
done
