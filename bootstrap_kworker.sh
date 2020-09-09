#!/bin/bash

echo "****** Setting up worker node ****** "

echo "Installing sshpass"
apt-get install -y sshpass >/dev/null 2>&1
echo "Copying join script"
sshpass -p "kubeadmin" scp -o StrictHostKeyChecking=no kmaster.firefly.local:/joincluster.sh /joincluster.sh

echo "*** Joining $(hostname) to cluster ***"

bash /joincluster.sh