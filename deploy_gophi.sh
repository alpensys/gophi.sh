#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   April 2024, created by Robin Tauxe                                            #
#   For HES-SO CAS in Cybersecurity                                               #
#   Deploy a GoPhish server in an Infomaniak Public Cloud Open Stack environment  #
#   Everything made on this script are made for educational purposes              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Welcome to this automated script to deploy a complete installation of GoPhish framework. It make it quick & easy."

# Define the server name by using a random function

randomstring=$(printf '%s' $(echo "$RANDOM" | md5sum) | cut -c 1-10)
defname="cas-cyber-""$randomstring"

# Create the server in the Openstack environment

echo -e "Server creation has been requested. Please wait..."

openstack server create --image "Ubuntu 22.04 LTS Jammy Jellyfish" --flavor a2-ram4-disk20-perf1 --key-name rt-rsa --network ext-net1 $defname --wait

# Getting the IP address of the server. "jq" package must be installed.

ipadd=$(openstack server show $defname -f json | jq -r '.addresses'| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

# Creation of a A record on the delegated DNS zone

openstack recordset create --type A --record $ipadd cloud.rt-cas-cyber.ch. $randomstring

sleep 15

# Some echo to give informations about the current server

echo -e "The server name is : $defname" > server_info.txt
echo -e "The admin URL of Gophish is : https://$randomstring.cloud.rt-cas-cyber.ch:3333/" >> server_info.txt
echo -e "To connect with SSH on the server, please use : ssh ubuntu@$ipadd with the certificate used on Openstack" >> server_info.txt

# Copy of the config file on the destination server 

#scp /home/rt/openstack/config.json ubuntu@$ipadd:/home/ubuntu/config.json

# Array of commands that will be run on the server. These commands will deploy GoPhish.

commands=(
        "sudo apt install unzip -y"
        "mkdir /home/ubuntu/server"
        "cd /home/ubuntu/server && wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip"
        "sudo unzip /home/ubuntu/server/gophish-v0.12.1-linux-64bit.zip -d /home/ubuntu/server/"
        "sudo chmod +x /home/ubuntu/server/gophish"
        "sudo rm /home/ubuntu/server/config.json && sudo cp /home/ubuntu/config.json /home/ubuntu/server/"
        "cd /home/ubuntu/server && sudo ./gophish"
        )

        #Il reste a modifier le fichier de config de gophish avant de lancer le serveur !

# For boucle to execute the commands defined above

for command in "${commands[@]}"; do
        ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
        sleep 1
done