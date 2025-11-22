#!/bin/bash

BOLD='\e[1m'
UNDERLINE='\e[4m'
BLINK='\e[5m'
INVERSE='\e[7m'
RED='\e[31m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
B_GREEN='\e[42m'
B_BLUE='\e[44m'
RESET='\e[0m'
echo -e "\n\t${CYAN}#########################################\n\t##ROUTE CONFIGURATION BY GURKIRAT SINGH##\n\t#########################################${RESET}\n\t"
read -p "Please share <ipsubnet>/<subnet> : " -e ip_subnet
gateway="<Gateway IP adress>"
echo -e "Provided subnet \e[35;4m$ip_subnet${RESET} will be routed to Gateway ${BLUE}($gateway)${RESET}"
nmcli connection modify <INTERFACE NAME> +ipv4.routes "$ip_subnet $gateway"
echo -e "${B_GREEN}\nConfiguration update!!${RESET}\n\nPlease find below routes configured:\n$(cat /etc/NetworkManager/system-connections/<INTERFACE>.nmconnection | grep route)"
nmcli connection reload
nmcli connection up <INTERFACE NAME>
