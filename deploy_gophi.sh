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
        "hostname"
        "date"
        )

# Boucle sur la liste des commandes et exécution via
for command in "${commands[@]}"; do
        ssh ubuntu@$ipadd -o StrictHostKeyChecking=no "$command"
        sleep 1
done

echo -e "All commands have been run"
echo -e "Le lien permettant d'accéder au serveur est le suivant : http://$randomstring.cloud.rt-cas-cyber.ch/"

sleep 1

# Connexion à la machine et execution du phishing

 ssh ubuntu@$ipadd -o StrictHostKeyChecking=no