#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   April 2024, created by Robin Tauxe                                            #
#   For HES-SO CAS in Cybersecurity                                               #
#   Deploy a GoPhish server in an Infomaniak Public Cloud Open Stack environment  #
#   Everything made on this script are made for educational purposes              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo -e "\nWelcome to this automated script to deploy a complete installation of GoPhish framework. It make it quick & easy."

# Find the current location
current_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Define the server name by using a random function
randomstring=$(printf '%s' $(echo "$RANDOM" | md5sum) | cut -c 1-10)
defname="cas-cyber-""$randomstring"

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

echo -e "DNS record created/n"

# Delete if exist the IP address of the server on knows_hosts
ssh-keygen -f "/home/rt/.ssh/known_hosts" -R "$ipadd"

# Some echo to give informations about the current server
# The first echo will overwrite the existing file
echo -e "The server name is : $defname" > server_info.txt
echo -e "The admin URL of Gophish is : https://$randomstring.cloud.rt-cas-cyber.ch:3333/" >> server_info.txt
echo -e "To connect with SSH on the server, please use : ssh ubuntu@$ipadd with the certificate used on Openstack" >> server_info.txt

# Copy of the config file on the destination server 
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$current_location"/config.json ubuntu@$ipadd:/home/ubuntu/config.json > /dev/null 2>&1

# Array of commands that will be run on the server. These commands will deploy GoPhish.
echo -e "\nInstallation and configuration of Gophish on destination server with IP $ipadd"
echo -e "Once done, current output will display GoPhish logs and provide username and password. Please refer to server_info.txt file to get admin URL."
echo -e "Please note that when you close or CTRL+C this terminal, GoPhish server will stop. You'll be still able to SSH to it and run it manually.\n"

sleep 5

commands=(
        "sudo apt install unzip -y > /dev/null 2>&1"
        "mkdir /home/ubuntu/server > /dev/null 2>&1"
        "cd /home/ubuntu/server && wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip > /dev/null 2>&1"
        "sudo unzip /home/ubuntu/server/gophish-v0.12.1-linux-64bit.zip -d /home/ubuntu/server/ && sudo rm /home/ubuntu/server/gophish-v0.12.1-linux-64bit.zip > /dev/null 2>&1"
        "sudo chmod +x /home/ubuntu/server/gophish > /dev/null 2>&1"
        "sudo rm /home/ubuntu/server/config.json && sudo mv /home/ubuntu/config.json /home/ubuntu/server/ > /dev/null 2>&1"
        "sudo snap install --classic certbot"
        "cd /home/ubuntu/server && sudo ./gophish > gophish.log"
        )

        #sudo certbot certonly -n --standalone --register-unsafely-without-email -d dcece22318.cloud.rt-cas-cyber.ch --agree-tos 

# For boucle to execute the commands defined above
for command in "${commands[@]}"; do
        ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
        sleep 3
done