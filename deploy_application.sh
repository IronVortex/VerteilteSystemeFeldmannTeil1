#!/bin/bash

RED='\033[0;31m'
NC='\033[0m'

while getopts "h" opt; do
case $opt in
	h)
	  echo -e "-h = help"
	  ;;
	?)
	  echo -e "Wrong Input, see -h for help"
	  exit 1
	  ;;
    esac
done
sudo kubectl create deployment versys --image=ironvortex/app:v0.1
sudo kubectl get deployments
sudo kubectl get rs
sudo kubectl scale deployments/versys --replicas=3
sudo kubectl get pods -o wide


