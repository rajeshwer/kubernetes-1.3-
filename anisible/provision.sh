#!/bin/bash

read -p 'Enter SERVICE_IP_RANGE : ' SERVICE_IP_RANGE
echo $SERVICE_IP_RANGE
if [ ! -z "$SERVICE_IP_RANGE" ]
then
   echo $SERVICE_IP_RANGE
   sed -i "" "s~SERVICE_IP_RANGE:.*~SERVICE_IP_RANGE: ${SERVICE_IP_RANGE}~" defaults/main.yaml
fi

read -p 'Enter POD_NETWORK : ' POD_NETWORK
echo $POD_NETWORK
if [ ! -z "$POD_NETWORK" ]
then
   echo $POD_NETWORK
   sed -i "" "s~POD_NETWORK:.*~POD_NETWORK: ${POD_NETWORK}~" defaults/main.yaml
fi

read -p 'Enter DNS_SERVICE_IP : ' DNS_SERVICE_IP
echo $DNS_SERVICE_IP
if [ ! -z "$DNS_SERVICE_IP" ]
then
   echo $DNS_SERVICE_IP
   sed -i "" "s~DNS_SERVICE_IP:.*~DNS_SERVICE_IP: ${DNS_SERVICE_IP}~" defaults/main.yaml
fi

read -p 'Enter K8S_SERVICE_IP : ' K8S_SERVICE_IP
echo $K8S_SERVICE_IP
if [ ! -z "$K8S_SERVICE_IP" ]
then
   echo $K8S_SERVICE_IP
   sed -i "" "s~K8S_SERVICE_IP:.*~K8S_SERVICE_IP: ${K8S_SERVICE_IP}~" defaults/main.yaml
fi

read -p 'Enter K8S_VER : ' K8S_VER
echo $K8S_VER
if [ ! -z "$K8S_VER" ]
then
   echo $K8S_SERVICE_IP
   sed -i "" "s~K8S_VER:.*~K8S_VER: ${K8S_VER}~" defaults/main.yaml
fi

read -p 'Enter MASTER_HOST : ' MASTER_HOST
echo $MASTER_HOST
if [ ! -z "$MASTER_HOST" ]
then
   echo $MASTER_HOST
   sed -i "" "s~MASTER_HOST:.*~MASTER_HOST: ${MASTER_HOST}~" defaults/main.yaml
fi

read -p 'Enter ADVERTISE_IP : ' ADVERTISE_IP
echo $ADVERTISE_IP
if [ ! -z "$ADVERTISE_IP" ]
then
   echo $ADVERTISE_IP
   sed -i "" "s~ADVERTISE_IP:.*~ADVERTISE_IP: ${ADVERTISE_IP}~" defaults/main.yaml
fi

read -p 'Enter ETCD_ENDPOINTS : ' ETCD_ENDPOINTS
echo $ETCD_ENDPOINTS
if [ ! -z "$ETCD_ENDPOINTS" ]
then
   echo $ETCD_ENDPOINTS
   sed -i "" "s~ETCD_ENDPOINTS:.*~ETCD_ENDPOINTS: ${ETCD_ENDPOINTS}~" defaults/main.yaml
fi

ansible-playbook site.yaml
