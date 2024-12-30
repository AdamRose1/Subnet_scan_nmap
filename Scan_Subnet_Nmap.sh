#!/bin/bash
# Created this script to automate and organize nmap subnet scanning

# Get user input for the target subnet/IP
printf "What is the target subnet/IP address that you want to scan? "
read target
printf "Scan will run on $target \n\n"

# Get user input for speed option
printf "Do you want to add --min-rate=5000 to the nmap scans? (y/n)
If you are concerned about causing disruptions on a target, then do not use --min-rate=5000. "
read speed
speed=$(printf "$speed" | tr '[:upper:]' '[:lower:]')

# Check if the user wants to use --min-rate=5000
if [[ "$speed" == "y" || "$speed" == "yes" ]]; then
    speed="--min-rate=5000"
    printf "Nmap will scan with --min-rate=5000\n\n"
else
    speed=""
    printf "Nmap will use default speed scan, it will not add --min-rate=5000\n\n"
fi

# Get user input for protocol option
printf "Do you want to scan UDP or TCP? "
read protocol
protocol=$(printf "$protocol" | tr '[:upper:]' '[:lower:]')

# Check what protocol user wants to use
if [[ "$protocol" == "udp" || "$protocol" == "u" ]]; then
    protocol= "-sU"
    printf "Starting UDP scan\n\n"
else:
    protocol= ""
    printf "Starting TCP scan\n\n"
fi

# nmap host discovery 
mkdir step1_host-discovery && cd step1_host-discovery
nmap -sn $target $speed $protocol -oN nmap_host-discovery 

# nmap scan all 65k ports on every host discovered in the previous command
mkdir step2_65k-find-open-ports && cd step2_65k-find-open-ports
for ip in $(cat ../nmap_host-discovery|grep 'scan report'|awk '{print $5}');do nmap -Pn -p- $ip $speed $protocol -oN nmap_65k-ports_$ip;done

# nmap version and script scanning on every open port for each host discovered
mkdir step3_sCV && cd step3_sCV
for ip in $(cat ../../nmap_host-discovery|grep 'scan report'|awk '{print $5}');do for ports in $(cat ../nmap_65k-ports_$ip|grep open|awk -F '/' '{print $1}'|sed -z 's/\n/,/g'|sed 's/,$//');do nmap -Pn $ip $speed $protocol -p $ports -sCV -oN nmap_sCV_$ip;done;done

# Create a directory for each host discovered with open ports, and then move each nmap file output to the target directory.  This is helpful for organizing notes on large subnets
mkdir all_targets && cd all_targets
for ip in $(ls ../nmap*|awk -F '_' '{print $3}');do mkdir $ip && cp ../nmap_sCV_$ip $ip;done

# Clean up
cd ../ && mv all_targets ../../../ && cd ../../../ && rm -rf step1_host-discovery

# To create files in each target IP uncomment the line below
for ip in $(ls all_targets);do touch all_targets/$ip/enumeration.txt all_targets/$ip/exploit_path.txt all_targets/$ip/creds.txt;done
