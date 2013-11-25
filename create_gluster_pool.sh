#!/usr/bin/env bash

# TODO: port this to fabric

# . ./configure.sh

# This script creates gluster resources on the remote hypervisors.
#
#
# ########################################################
# Glusterd must be running, and there must be two volumes:
#
# e.g.
# Volume Name: gimg
# Type: Stripe
# Volume ID: 8769f39b-9590-42c1-9a7f-837cde1862e1
# Status: Started
# Number of Bricks: 1 x 4 = 4
# Transport-type: tcp
# Bricks:
# Brick1: 192.168.20.102:/imgBrick
# Brick2: 192.168.20.103:/imgBrick
# Brick3: 192.168.20.104:/imgBrick
# Brick4: 192.168.20.105:/imgBrick
#
# and
#
#Volume Name: giso
#Type: Stripe
#Volume ID: 38f91039-85f9-44ae-a7d7-0ca62c2e1ca9
#Status: Started
#Number of Bricks: 1 x 4 = 4
#Transport-type: tcp
#Bricks:
#Brick1: 192.168.20.102:/isoBrick
#Brick2: 192.168.20.103:/isoBrick
#Brick3: 192.168.20.104:/isoBrick
#Brick4: 192.168.20.105:/isoBrick
#
# #########################################
# /{iso,img}Brick are gluster client mounts
#
# /{iso,img}Brick on each host should be mounted under fuse.glusterfs; your mtab
# should look something like: 
# 172.16.0.102:/gimg /data/img fuse.glusterfs rw,blah blah
# 172.16.0.102:/giso /data/iso fuse.glusterfs rw,blah blah
#
#
# And finally, since each hypervisor is part of the clutser, each hypervisor has
# the brick locally; e.g. here is my ftab:
# LABEL=ISO               /isoBrick               xfs     noatime,defaults   1 1
# LABEL=IMG               /imgBrick               xfs     noatime,defaults   1 1

declare -A configs
declare -a dirs=( img iso )

for dir in ${dirs[@]}; do
    GLUSTERPATH=/data/${dir}
    XML='
<pool type=\"dir\">
  <name>glusterDisk-'${dir}'</name>
  <target>
    <path>'${GLUSTERPATH}'</path>
  </target>
</pool>'
    configs[${dir}]=$XML
done
    
for dir in ${!configs[@]}; do
    _pssh -P "virsh pool-list --all | egrep glusterDisk-${dir} >/dev/null 2>&1 || echo \"${configs[${dir}]}\" > /tmp/glusterDisk-${dir}.xml && virsh pool-define /tmp/glusterDisk-${dir}.xml && virsh pool-start glusterDisk-${dir} && virsh pool-autostart glusterDisk-${dir}"
done
    
