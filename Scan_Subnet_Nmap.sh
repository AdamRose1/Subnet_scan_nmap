#!/bin/bash
# Created this script to automate and organize nmap subnet scanning
# If concerned about causing disruptions on a target, then remove --min-rate=5000 

# nmap Host Discovery 
mkdir step1_host-discovery && cd step1_host-discovery
nmap -sn 10.13.38.0/24 --min-rate=5000 -oN nmap_host-discovery

# nmap scan all 65k ports on every host discovered in the previous command
mkdir step2_65k-find-open-ports && cd step2_65k-find-open-ports
for ip in $(cat ../nmap_host-discovery|grep 'scan report'|awk '{print $5}');do nmap -Pn -p- $ip --min-rate=5000 -oN nmap_65k-ports_$ip;done

# nmap version and script scanning on every open port for each host discovered
mkdir step3_sCV && cd step3_sCV
for ip in $(cat ../../nmap_host-discovery|grep 'scan report'|awk '{print $5}');do for ports in $(cat ../nmap_65k-ports_$ip|grep open|awk -F '/' '{print $1}'|sed -z 's/\n/,/g'|sed 's/,$//');do nmap -Pn $ip -p $ports -sCV -oN nmap_sCV_$ip;done;done

# Create a directory for each host discovered with open ports, and then move each nmap file output to the target directory.  This is helpful for organizing notes on large subnets
mkdir all_targets && cd all_targets
for ip in $(ls ../nmap*|awk -F '_' '{print $3}');do mkdir $ip && cp ../nmap_sCV_$ip $ip;done

# Clean up
cd ../ && mv all_targets ../../../ && cd ../../../ && rm -rf step1_host-discovery
