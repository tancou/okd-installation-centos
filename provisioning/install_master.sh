#!/bin/bash

export PATH="/usr/local/bin:$PATH"

source settings.sh

envsubst < /root/okd-installation-centos/inventory.download > /root/okd-installation-centos/inventory.ini

# # install the packages for Ansible
# yum -y --enablerepo=epel install ansible pyOpenSSL
# curl -o ansible.rpm https://releases.ansible.com/ansible/rpm/release/epel-7-x86_64/ansible-2.6.5-1.el7.ans.noarch.rpm
# yum -y --enablerepo=epel install ansible.rpm

# # checkout openshift-ansible repository
# [ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git
# cd openshift-ansible && git fetch && git checkout release-${OKD_VERSION} && cd ..

yum install -y centos-release-openshift-origin311
yum install -y openshift-ansible

yum install python3 -y

wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py
pip install pip --upgrade
pip install ansible==2.6.20
pip install -U pyopenssl

mkdir -p /etc/origin/master/
touch /etc/origin/master/htpasswd

# check pre-requisites
ansible-playbook -i /root/okd-installation-centos/provisioning/inventory.ini /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

# deploy cluster
ansible-playbook -i /root/okd-installation-centos/provisioning/inventory.ini /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

htpasswd -b /etc/origin/master/htpasswd $OKD_USERNAME ${OKD_PASSWORD}
oc adm policy add-cluster-role-to-user cluster-admin $OKD_USERNAME


curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod +x get_helm.sh
./get_helm.sh

kubectl --namespace kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --upgrade


echo "#####################################################################"
echo "* Your console is https://console.$DOMAIN:$API_PORT"
echo "* Your username is $OKD_USERNAME "
echo "* Your password is $OKD_PASSWORD "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${OKD_USERNAME} -p ${OKD_PASSWORD} https://console.$DOMAIN:$API_PORT/"
echo "#####################################################################"

oc login -u ${OKD_USERNAME} -p ${OKD_PASSWORD} https://console.$DOMAIN:$API_PORT/