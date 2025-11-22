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
#set -x
if [[ $EUID -ne 0 ]]; then
   echo "!!!This script must be run as root!!!"
   exit 1
fi
choose_option(){
	echo -n "Choose option"
	local x=1
	local z=$1
	while (( x < z )); do
	    if (( x == z - 1 )); then
	      echo -n " $x"
	    else
	      echo -n " $x or"
	    fi
	    (( x++ ))
	  done
	echo -e "\n"

	read -e option
	if (( option < 1 || option >= x )); then
		echo -e "\t\t\t\e${BLINK}${BOLD}${RED}!!!Invalid Input!!!${RESET}\n"
		exit 1
	fi
}
select_route_file(){
	routefl=()
	while read file; do
	    routefl+=("$file")
	done <<< "$(grep -Eli $1 /etc/sysconfig/network-scripts/route*)"

	select routefile in "${routefl[@]}"; do
	#echo -e "${BOLD}${BLUE}Selected route file is $routefile${RESET}"
	break
	done
}

route_update(){
	routefile=$1
	echo -e "\nEditing ***${INVERSE}$routefile${RESET}***\n"
	if grep -qi "route6" <<< "$routefile"; then
		gateway=$(awk '{print $3}' "$routefile" | awk "NR == 1")
		echo -e "Gateway in ${UNDERLINE}route${RESET} file is ${B_GREEN}$gateway${RESET}\n"
		read -e -p "Enter <address>/<subnet>  -> " address
		read -ei "$gateway" -p "<gateway>  -> " gateway
		echo "$address via $gateway" >> $routefile
		echo -e "\nLast two entries added :\n" ; tail -2 $routefile
		exit 0
	elif grep -qi "route-" <<< "$routefile"; then
		gateway=$(grep -i "GATEWAY" "$routefile" | cut -d "=" -f2 | awk "NR == 1")
		echo -e "Gateway in ${UNDERLINE}route${RESET} file is ${B_GREEN}$gateway${RESET}\n"
		read -e -p "<address>(eg. 10.10.10.10): " address
		read -p "<netmask>(eg. 255.255.255.255): " -ei "255.255.255.255" netmask
		read -ei "$gateway" -p "<gateway>: " gateway
		# Find an available index for the new route entry
		index=0
		while grep -q "ADDRESS${index}=" $routefile; do
			((index++))
		done
		# Add the new route entry to the file
		echo "ADDRESS${index}=$address" >> $routefile #/root/experiments/myscripts/testfile
		echo "NETMASK${index}=$netmask" >> $routefile #/root/experiments/myscripts/testfile
		echo "GATEWAY${index}=$gateway" >> $routefile #/root/experiments/myscripts/testfile
		echo -e "\nLast two entries added :\n" ; tail -6 $routefile
		exit 0
	else
		echo -e "Invalid Input\n"
	fi
}
#Look for available interface
count=1
while read -r int; do
	echo -e "($count) is $int:\n$(ip addr show $int | grep -Ei "inet|inet6")\n"
	((count++))
done <<< "$(ifconfig | egrep "ens|eno|bond" | cut -d ':' -f 1)"

choose_option $count #Function Call

#Interface selected as per user input
ifg=$(ifconfig | egrep "ens|eno|bond" | cut -d ':' -f 1 | awk "NR == $option")
echo -e "\n###Seleted interface is \e[100m${BOLD}$ifg${RESET}###\n"

#Identify interface config file
ifgfile=$(grep -Eli device=$ifg /etc/sysconfig/network-scripts/ifcfg-*)

#Identify GW in config files
gw=$(egrep -i "gateway|gw" $ifgfile | cut -d "=" -f2)

#echo -e "Select (Y) if what to search using file name \nSelect (N) if what to search using Gateways\n"
echo -e "Do you want to continue search using filename or Gateways (Y/N): \n"
#select slt in "Y" "N" ; do
#	break
#done
read -e slt
slt=$(echo "$slt" | tr 'a-z' 'A-Z')
#if [ "$slt" == "Y" ] ; then
#	unset ifgfile
#elif [ "$slt" == "N" ]; then
#	echo
#else
#	echo -e "${BOLD}${RED}${BLINK}!!!INVALID INPUT!!!${RESET}\n"
#	exit 1
#fi
if [ "$slt" == "Y" ] ; then
#if [ -n $ifgfile ] ; then
	#echo -e "###${YELLOW}GW not present in ifg file, finding route file using name ${BLINK}...${RESET}"###
	echo -e "\nFinding using Interface name\n"
	rname=$(cut -d "/" -f5 <<<"$ifgfile" | cut -d "-" -f2)
	#routefile=$(ls /etc/sysconfig/network-scripts/route* | grep -i $rname)
	routefile=$(grep -i $rname <<< $(ls /etc/sysconfig/network-scripts/route*))
	if [ -n "$routefile" ] ; then
		select routefile in $routefile ; do
			break
		done
		route_update $routefile
	else
		#echo -e  "\t\t\t\e${BOLD}${RED}${BLINK}!!!Unable to find route file!!!${RESET}"
		echo -e "###${YELLOW}Unable to find file by name, finding by Gateway now${BLINK}.....${RESET}"###
	fi
fi
if [ "$slt" == "N" ] ; then
#if [ -n "$gw" ]; then #if GW exist in config file
        gw=$(echo $gw | sed 's/ /|/') #combining v4 and v6 gateway
        echo -e "\n###Gateway found in ${UNDERLINE}interface${RESET} file is ${B_GREEN}$gw${RESET}###\n"
        if grep -Eqi $gw /etc/sysconfig/network-scripts/route* ; then
                select_route_file $gw
                route_update $routefile
        else
                echo -e  "\n\t\t\t\e${BOLD}${RED}${BLINK}!!!Unable to find route file!!!${RESET}\n"
                exit 1
        fi
else
	echo -e  "\n\t\t\t\e${BOLD}${RED}${BLINK}!!!Unable to find route file!!!${RESET}\n"
	exit 1
fi
exit 0
