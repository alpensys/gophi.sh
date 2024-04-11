#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   April 2024, created by Robin Tauxe                                            #
#   HES-SO CAS in Cybersecurity                                                   #
#   Deploy a GoPhish server in an Infomaniak Public Cloud Open Stack environment  #
#   Everything made on this script are made for educational purposes              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo -e "\nWelcome to this automated script to deploy a complete installation of GoPhish framework."
echo -e "It will automatically deploy a server in the Openstack environment defined on your system. Please read the prerequisites at : https://docs.cloud.rt-cas-cyber.ch/books/2-mise-en-place-prerequis.\n"

# Ask confirmation before running the script
 read -r -p "Are you sure you want to continue? [Y/n] " response
 response=${response,,} 
 if [[ $response =~ ^(y| ) ]] || [[ -z $response ]]; then

	# Find the current location
	current_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

	# Define the server name by using a random function
	randomstring=$(printf '%s' $(echo "$RANDOM" | md5sum) | cut -c 1-3)
	defname="cas-cyber-""$randomstring"

	# Give actual hour of the day
	now=date
	echo -e "Time : $now"
	# Create the server in the Openstack environment
	echo -e "\nServer creation has been requested. Please wait..."
	openstack server create --image "Ubuntu 22.04 LTS Jammy Jellyfish" --flavor a2-ram4-disk20-perf1 --key-name rt-rsa --network ext-net1 $defname --wait > /dev/null 2>&1

	# Getting the IP address of the server. "jq" package must be installed.
	ipadd=$(openstack server show $defname -f json | jq -r '.addresses'| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b") 

	echo -e "Server created with name $defname and IP $ipadd"

	# Creation of a A record on the delegated DNS zone
	echo -e "\nCreation of an A record on the delegated DNS zone for FQDN $randomstring.cloud.rt-cas-cyber.ch"

	openstack recordset create --type A --record $ipadd cloud.rt-cas-cyber.ch. $randomstring > /dev/null 2>&1
	sleep 15

	echo -e "DNS record created\n"

	# Delete if exist the IP address of the server on knows_hosts
	ssh-keygen -f "/home/rt/.ssh/known_hosts" -R "$ipadd"

	# Some echo to give informations about the current server on a text file
	# The first echo will overwrite the existing file
	echo -e "The server name is : $defname" > server_info.txt
	echo -e "The admin URL of Gophish is : https://$randomstring.cloud.rt-cas-cyber.ch:3333/" >> server_info.txt
	echo -e "To connect with SSH on the server, please use : ssh ubuntu@$ipadd with the certificate used on Openstack" >> server_info.txt

	sleep 10

	# Copy of the config file on the destination server 
	scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$current_location"/config.json ubuntu@$ipadd:/home/ubuntu/config.json > /dev/null 2>&1

	# Some echo to give general informations
	echo -e "\nInstallation and configuration of Gophish on destination server with IP $ipadd"
	echo -e "Once done, current output will display GoPhish logs and provide username and password. Please refer to server_info.txt file to get admin URL."
	echo -e "Please note that when you close or CTRL+C this terminal, GoPhish server will stop. You'll be still able to SSH to it and run gophish server manually.\n"
	echo -e "The admin URL of Gophish is : https://$randomstring.cloud.rt-cas-cyber.ch:3333/\n"
	sleep 10

	# Array of commands that will be run on the server. These commands will deploy GoPhish.
	commands=(
	        "sudo timedatectl set-timezone Europe/Zurich"
			"sudo apt install unzip -y > /dev/null 2>&1"
	        "mkdir /home/ubuntu/server > /dev/null 2>&1"
	        "cd /home/ubuntu/server && wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip > /dev/null 2>&1"
	        "sudo unzip /home/ubuntu/server/gophish-v0.12.1-linux-64bit.zip -d /home/ubuntu/server/ > /dev/null 2>&1"
	        "sudo rm /home/ubuntu/server/gophish-v0.12.1-linux-64bit.zip > /dev/null 2>&1"
	        "sudo chmod +x /home/ubuntu/server/gophish > /dev/null 2>&1"
	        "sudo rm /home/ubuntu/server/config.json"
	        "sudo cp /home/ubuntu/config.json /home/ubuntu/server/ > /dev/null 2>&1"
	        "sudo snap install --classic certbot > /dev/null 2>&1"
	        "sudo ln -s /snap/bin/certbot /usr/bin/certbot > /dev/null 2>&1"
	        "sudo certbot certonly -n --standalone --register-unsafely-without-email -d $randomstring.cloud.rt-cas-cyber.ch --agree-tos > /dev/null 2>&1"
	        "sudo cp /etc/letsencrypt/live/$randomstring.cloud.rt-cas-cyber.ch/fullchain.pem /home/ubuntu/server/gophish.crt > /dev/null 2>&1"
	        "sudo cp /etc/letsencrypt/live/$randomstring.cloud.rt-cas-cyber.ch/privkey.pem /home/ubuntu/server/gophish.key > /dev/null 2>&1"
	        "sudo chown ubuntu:ubuntu /home/ubuntu/server/gophish.crt > /dev/null 2>&1"
	        "sudo chown ubuntu:ubuntu /home/ubuntu/server/gophish.key > /dev/null 2>&1"
	        "cd /home/ubuntu/server && sudo ./gophish > gophish.log"
	        )

	# For boucle to execute the commands defined above
	for command in "${commands[@]}"; do
        	ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
        	sleep 5
	done
fi