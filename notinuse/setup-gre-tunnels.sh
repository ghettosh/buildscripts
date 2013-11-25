#!/usr/bin/env bash

# This script establishes gre tunnels to all other hypervisors

# Since ovs uses the host's networking stack, set vlan-tagged interfaces instead of br1:192.168.10.0/24

HYPERVISORS=( 192.168.10.102 192.168.10.103 192.168.10.104 192.168.10.105 )
GRETUN=0
EXTBR="br1" # Bridge that has the port containing the tunnel endpoint IP
INTBR="br2" # Internal bridge that VMs will plug their tap interfaces into
INDEX=1

for i in ${HYPERVISORS[@]}; do 
    ip a sh | grep $i >/dev/null 2>&1 && \
        { echo "Will not configure tunnel endpoint to myself, continuing"; continue; }
    TARGET_TUN=$( echo $i | cut -d. -f4)
    printf "INFO: Creating gretun for hypervisor ${INDEX} of ${#HYPERVISORS[@]} (${i})\n" 
    ovs-vsctl list-ports $INTBR | egrep "tun${TARGET_TUN}" > /dev/null 2>&1 && \
        { echo "tun to $i already exists. Skipping"; continue; }
    ovs-vsctl add-port $INTBR gre${TARGET_TUN} -- set interface gre${TARGET_TUN} type=gre options:remote_ip=${i} || \
        echo "WARNING: Could not create tun for $i"
    INDEX=$(( $INDEX + 1 ))
done
