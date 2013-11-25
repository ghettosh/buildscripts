Example DHCP Server
===================

This example assumes you have a router running flashrd (openbsd)

or

You have a server running ISC DHCPD

    # cat /etc/dhcpd.conf
    option  domain-name-servers 8.8.8.8, 75.75.75.76;
    subnet 172.16.0.0 netmask 255.255.255.0 {
        range 172.16.0.150 172.16.0.250;
        option routers 172.16.0.1;
    
        host r2a {
            hardware ethernet 00:0d:b9:2f:9c:3c;
            fixed-address 172.16.0.2;
        }

        host r2b {
            hardware ethernet 00:0d:b9:2f:a2:d0;
            fixed-address 172.16.0.3;
        }
    
       ############### BMC
        host bmc-054 {
            hardware ethernet 00:25:90:cd:5c:df;
            fixed-address 172.16.0.54;
        }
       ############### Other Infrastructure
        host sw01 {
            hardware ethernet A0:F3:C1:BC:A2:7D;
            fixed-address 172.16.0.254;
        }
       ############## Hypervisors
        host sys-00 {
            hardware ethernet 00:0f:20:d7:c5:dc;
            fixed-address 172.16.0.100;
            filename "/pxelinux/pxelinux.0";
            next-server 172.16.0.17;
        }
    
        host sys-01 {
            hardware ethernet 00:0f:20:d7:c5:db;
            fixed-address 172.16.0.101;
            filename "/pxelinux/pxelinux.0";
            next-server 172.16.0.17;
        }
    
        host sys-02 {
            hardware ethernet 00:25:90:c6:31:44;
            fixed-address 172.16.0.102;
            filename "/pxelinux/pxelinux.0";
            next-server 172.16.0.17;
        }
    
        host sys-03 {
            hardware ethernet 00:25:90:c7:3d:f0;
            fixed-address 172.16.0.103;
            filename "/pxelinux/pxelinux.0";
            next-server 172.16.0.17;
        }
    }
