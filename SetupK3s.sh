#!/bin/bash
RED='\033[0;31m'
NC='\033[0m'

while getopts "hdi" opt; do
case $opt in
	h)
	  echo -e "-h = help \n -d deinstall \n -i install"
	  ;;
	i)
	echo -e  "${RED}apt Update${NC}"
	apt update
	echo -e "${RED}get Docker Repository${NC}"
	apt install apt-transport-https ca-certificates curl software-properties-common -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
	echo -e "${RED}apt Update${NC}"
	apt update
	echo -e "${RED}install docker${NC}"
	apt install docker-ce -y
	systemctl start docker
	echo -e "${RED}Docker Started${NC}"
	systemctl enable docker
	echo -e "${RED}Docker enabled${NC}"

	read -n1 -p "Install Master or Worker [m, w]" input
	case $input in 
    	    m|M)
        	echo -e "${RED}\nStarting Master Node${NC}"
        	curl -sfL https://get.k3s.io | sh -s - --docker --write-kubeconfig-mode 644 
        	ufw allow 6443/tcp
        	ufw allow 443/tcp
        	echo -e "${RED}Master Node Token${NC}"
        	cat /var/lib/rancher/k3s/server/node-token
		exit
        	;;
    	    w|W)
		read -p "\n Master-IP: " m_ip
		read -p "Master-Token: " m_token
		curl -sfL http://get.k3s.io | K3S_URL=https://${m_ip}:6443 K3S_TOKEN=${m_token} sh -s - --docker
		exit
		;;
   	    esac
	    ;;
	d)
	read -n1 -p "Install Master or Worker [m, w]" input
	case $input in 
    	    m|M)
		echo -e "${RED}\n dockeruninstall K3s Master${NC}"
	  	sudo /usr/local/bin/k3s-uninstall.sh
	  	sudo rm -rf /var/lib/rancher
		sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli		
		sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
		exit
		;;
	    w|W)
		echo -e "${RED}uninstall K3s Worker${NC}"
		sudo /usr/local/bin/k3s-agent-uninstall.sh
		sudo rm -rf /var/lib/rancher
		sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli		
		sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce
		exit
		;;
	     esac
	     ;;
	?)
	  echo -e "Wrong Input, see -h for help"
	  exit 1
	  ;;
    esac
done
echo -e "Need Input, see -h for help"




