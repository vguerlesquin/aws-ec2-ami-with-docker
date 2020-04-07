#!/bin/bash

terraform init
terraform apply --auto-approve
#récupere la clé
touch ssh-key
chmod u+w ssh-key*
terraform output private_key > ssh-key
chmod 400 ssh-key

#récupere l'ip du serveur
instance_ip=`terraform output instance_ip`
echo $instance_ip
ssh -o "StrictHostKeyChecking=no" -l ec2-user -i ssh-key $instance_ip 'uname -a'
while test $? -gt 0
do
   sleep 5 # highly recommended - if it's in your local network, it can try an awful lot pretty quick...
   echo "Trying again..."
   ssh -o "StrictHostKeyChecking=no" -l ec2-user -i ssh-key $instance_ip 'uname -a'
done

#transfere les fichiers

ansible-playbook ./playbook.yml -i "$instance_ip," --timeout 300 -u ec2-user --private-key=./ssh-key --extra-vars "instances=$instance_ip"
intance_id=`terraform output instance_id`

cd create-ami

terraform init
terraform apply --auto-approve -var "instance_id=$intance_id"

cd ..
terraform destroy --auto-approve
