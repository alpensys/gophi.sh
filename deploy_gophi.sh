#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   April 2024, created by Robin Tauxe                                            #
#   For HES-SO CAS in Cybersecurity                                               #
#   Deploy a GoPhish server in an Infomaniak Public Cloud Open Stack environment  #
#   Everything made on this script are made for educational purposes              #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Welcome on this automated script to deploy a complete installation of GoPhish framework. It make it quick & easy."

# Définition du nom du serveur à l'aide de la fonction RANDOM

randomstring=$(printf '%s' $(echo "$RANDOM" | md5sum) | cut -c 1-10)
defname="cas-cyber-""$randomstring"

echo -e "The finale server name will be : $defname"

# Création du serveur

echo -e "Server creation has been requested. Please wait..."

openstack server create --image "Ubuntu 22.04 LTS Jammy Jellyfish" --flavor a2-ram4-disk20-perf1 --key-name rt-rsa --network ext-net1 $defname --wait

# Récupération de l'adresse IP (le package "jq" doit être installé)

ipadd=$(openstack server show $defname -f json | jq -r '.addresses'| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")

# Création d'un record de type A sur l'IP du serveur pour le nom généré

openstack recordset create --type A --record $ipadd cloud.rt-cas-cyber.ch. $randomstring

sleep 15

commands=(
        "sudo apt install unzip -y"
        "mkdir /home/ubuntu/server"
        "cd /home/ubuntu/server && wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip"
        "sudo unzip /home/ubuntu/server/gophish-v0.12.1-linux-64bit.zip -d /home/ubuntu/server/"
        "sudo chmod +x /home/ubuntu/server/gophish"
        "cd /home/ubuntu/server && sudo ./gophish"
        )

        #Il reste a modifier le fichier de config de gophish avant de lancer le serveur !

# Boucle sur la liste des commandes et exécution via
for command in "${commands[@]}"; do
        ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
        sleep 1
done

echo -e "All commands have been run"
echo -e "Le lien permettant d'accéder au serveur est le suivant : https://$randomstring.cloud.rt-cas-cyber.ch:3333/"
echo -e "Pour se connecter en SSH, il suffit de faire : ssh ubuntu@$ipadd depuis le WSL en utilisant la paire de clé SSH préconfigurée dans Openstack"
sleep 1

# Connexion à la machine et execution du phishing
 # ssh ubuntu@$ipadd -o StrictHostKeyChecking=no