#!/bin/bash
# April 2024, created by Robin Tauxe
# for CAS Cybersecurity
# everything made on this script are made for educational purposes

echo "Welcome on this automated script to perform a complete phishing attack quickly"

randomstring=$(printf '%s' $(echo "$RANDOM" | md5sum) | cut -c 1-10)
defname="cas-cyber-""$randomstring"

echo -e "The finale server name will be : $defname"
echo -e "Server creation has been requested. Please wait 2 minutes"

openstack server create --image "Ubuntu 22.04 LTS Jammy Jellyfish" --flavor a2-ram4-disk20-perf1 --key-name rt-rsa --network ext-net1 $defname --wait

ipadd=$(openstack server show $defname -f json | jq -r '.addresses'| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

sleep 30

commands=(
	   "git clone --depth=1 https://github.com/htr-tech/zphisher.git"
	  )

# Boucle sur la liste des commandes et exécution via
for command in "${commands[@]}"; do
           ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
   	   done

sleep 5

ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "cd /home/ubuntu/zphisher && bash zphisher.sh"
