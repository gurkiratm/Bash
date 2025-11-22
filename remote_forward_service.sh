#!/bin/bash

#####################################################################################
#NOTE:Run below commands on terminal for script to work properly
#       setenforce 0
#       ausearch -m avc -ts recent
#       setenforce 1 ##reset after completion
#                                       OR
#       chcon -t bin_t <Path to the Script>/remote_forward_service.sh // change the SELinux context
#       ls -Z <Path to the Script>/remote_forward_service.sh //check the SELinux context
####################################################################################

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "[ERROR]You are not running as the root user.  Please try again with root privileges.";
    logger -t "[ERROR]You are not running as the root user.  Please try again with root privileges.";
    exit 1;
elif [ $(getenforce) == "Enforcing" ] ; then
    echo "[ERROR] SElinux is enabled" ;
    exit 1;
fi;

export SSHPASS=<Remote Server Password>  # can export in bashrc as well

#/usr/bin/sshpass -p $SSH_RDP_IOT_PASS /usr/bin/autossh -M 0 -N -o StrictHostKeyChecking=no \
/usr/bin/sshpass -e /usr/bin/autossh -M 0 -N -o StrictHostKeyChecking=no \
-R <Remote Server Port1>:<Destination Server1 IP>:<Dst Port> \
-R <Remote Server Port2>:<Destination Server2 IP>:<Dst Port> \
-R <Remote Server Port2>:<Destination Server2 IP>:<Dst Port> \
-R 9090:10.10.10.1:9090 \  ## Example1
-R 9443:10.10.10.2:9443 \ ## Example2
-R 65080:10.10.10.3:443 \ ## Example3
-R 65090:10.10.10.4:3389 \  ## Example4
<Remote Server Username>@<Remote Server IP address>
