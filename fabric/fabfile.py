import urllib
from os import path
import random
from fabric.api import run, env, cd, put, local, hosts

# read this: this fabfile expects all hosts to have a hostname
#  that looks like 'sys[nnn], where 'nnn' is the intended 3rd octet
#  of that host's various ips

hvlist = []
# [ sys102, sys103, etc... ]
for i in range(2,6): hvlist.append('sys10' + str(i))

env.hosts = hvlist
env.user  = 'root'

def step00():
    """
    verify connectivity and access
    """
    # This functionality was put into the kickstart
    #keyniko = 'paste your ssh pub key here'
    #pubkeys = [ keyniko ]
    #run('uname -s')
    #for key in pubkeys:
        #keyid = key.split()[2]
        #cmd = 'mkdir -p /root/.ssh;'
        #cmd += ' grep {k} /root/.ssh/authorized_keys ||'.format(k=keyid)
        #cmd += ' echo \"{k}\" >> /root/.ssh/authorized_keys'.format(k=key)
        #run(cmd)

    # Attention: After getting a new switch, I no longer have this problem
    # So the kickstart with an LACP bond wasn't working. I've taken to simply using
    # balance-rr in the kickstart config and then changing it to an 802.3ad bond here
    # bondconf = '/etc/sysconfig/network-scripts/ifcfg-bond0'
    # cmd = 'grep balance-rr {b} > /dev/null 2>&1; if [ $? -eq 0 ]; then '.format(
    #     b=bondconf)
    # cmd += ' touch /tmp/.bondchanged;'
    # cmd += ' sed -i "s/balance-rr/4 miimon=100 lacp_rate=1/g" {b};'.format(
    #     b=bondconf)
    # cmd += ' fi'
    # run(cmd) 
    # run('if [ -f /tmp/.bondchanged ]; then \
    #     ifdown bond0 && ifup bond0; rm -f /tmp/.bondchanged; fi')
    # run(cmd)

    run('uname -a; ip address show')

def step01():
    """
    Set hostnames and ensure a unique uuid is set for libvirtd
    """
    set_hostname_command = '''
    O4=$(ip a sh dev bond0 | 
    awk '/inet /{gsub("/.*",""); split($2,a,"."); print a[4]}'); 
    hostname sys${O4}.ghetto.sh;
    sed -i "s/unconfigured/sys${O4}/g" \
        /etc/sysconfig/network /etc/sysconfig/network-scripts/ifcfg-*;
    '''
    run(set_hostname_command)

def step02():
    """
    Install extra repos, glusterfs and openvswitch
    """

    targetpath = './files/'
    epel_url  = 'http://mirror.oss.ou.edu/'
    epel_path = '/epel/6/x86_64/epel-release-6-8.noarch.rpm'
    epelrpm   = epel_url + epel_path
    epel      = 'latest-epel.rpm'
    
    if not path.isfile(epel):
        print "downloading latest epel"
        urllib.urlretrieve(epelrpm, targetpath + epel)

    gluster_url  = 'http://download.gluster.org/pub/gluster'
    gluster_path = '/glusterfs/LATEST/RHEL/glusterfs-epel.repo'
    glusterrepo  = gluster_url + gluster_path
    gluster      = './files/latest-gluster.repo'

    if not path.isfile(gluster):
        print "downloading latest gluster"
        urllib.urlretrieve(glusterrepo, targetpath + gluster)

    rpm_files = [   'kmod-openvswitch-2.0.0-1.el6.x86_64.rpm', 
                    'openvswitch-2.0.0-1.x86_64.rpm',
                    epel ]

    repo_files = [ gluster ]

    for rpm in rpm_files: 
        put('files/'+rpm, '/tmp')
        run('rpm -Uvh /tmp/%s' % rpm)

    for repo in repo_files:
        put(repo, '/etc/yum.repos.d/')

    run('yum repolist')

def step03():
    """
    Run a full yum update, but create a temporary local cache to do it
    """
    local('echo to do...')
    run('yum update -y')

def step04():
    """
    install and configure glusterd, probe all the peers
    """
    run('yum install -y glusterfs glusterfs-server')
    run('chkconfig glusterd on')
    run('service glusterd status || service glusterd restart')

def step05():
    """
    partition, format and mount usb drives
    """
    # TODO: Figure out a better way to verify that sdb and sdc are the 
    # right disks to target
    disks = {}
    disks['sdb'] = 'IMG'
    disks['sdc'] = 'ISO'
    for disk in disks:
        # if the directory is busy for any reason, give the user a 
        # chance to manually go in and fix it; as any busy devices will
        # stall future steps
        umount_cmd = '''if mount | grep "^/dev/{d}1 "; then
            UMOUNTED=0; while [ $UMOUNTED -eq 0 ]; do 
                umount /dev/{d}1 && UMOUNTED=1; 
                sleep 1; 
            done;
        fi'''.format(d=disk)
        run(umount_cmd)
        fn = disk + '.sfdisk'
        label = disks[disk]
        target_dir = '/' + label.lower() + 'Brick'
        localfile = 'files/' + fn
        remotefile = '/tmp/' + fn
        put(localfile, '/tmp')
        run('sfdisk -f /dev/{d} < {r}'.format(
			d=disk,r=remotefile))
        run('mkfs.xfs -f -i size=512 -L {l} /dev/{d}1'.format(
			l=label,d=disk))
        fstab_command = '''grep ^LABEL={l} /etc/fstab || \
        echo -e "LABEL={l}\t{t}\txfs\tnoatime,defaults\t1 1" >> \
        /etc/fstab'''.format(l=label,t=target_dir)
        run(fstab_command)
        run('mkdir -p {d} > /dev/null 2>&1'.format(d=target_dir))
        run('mount {d}'.format(d=target_dir))

@hosts(random.choice(hvlist))
def step06():
    """
    create gluster volumes from usb drives
    """
    hosts = env.hosts
    for peer in hosts:
        # in our environment, the last 3 characters in the hostname are the 
        # last octet upon which they will occupy on their networks.
        # Not sure what we'll do when we have more than 100 hosts, but 
        # faced with the choice of running this through re, or changing all
        # the hostnames to include a delimiter, i'll go this way.
        ip = '192.168.20.'+ str(peer[3:])
        run('gluster peer probe {i}'.format(i=ip))

def step07():
    """
    create libvirt resources from gluster volumes
    """
    local('echo to do...')

def step08():
    """
    create bridge on specified vm bridge, and make it a libvirt resource
    """
    local('echo to do...')


### The nuclear option ###

def step99():
    """
    zero out the mbr and force a re-kick. Use with care!!
    """
    run('dd if=/dev/zero of=/dev/sda bs=512 count=1')
    run('sync')
    run('reboot')
