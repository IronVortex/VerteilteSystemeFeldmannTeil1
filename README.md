# FeldmannVerSys

# 1. Kubernetes Cluster setup
Für das Erstellen des Kubernetes Clusters wurde K3s verwendet (Lightweight Kubernetes). Diese Lösung wurde gewählt, da versucht wurde, ein Raspberry Pi 3b in das Cluster aufzunehmen. (Schlussendlich hat dies für einen wesentlich größeren Aufwand gesorgt und wurde deshalb später durch eine weitere VM ersetzt. Im Verlauf der Anleitung wird allerdings in einer Info an einigen Stellen Kenntnisse zur Arbeit mit dem Raspberrry Pi erwähnt)

Die VM's in dem Cluster wurden in Hyper-V erstellt.

### 1.1 Erstellen der Host-Systeme
Zum Erstellen des Kubernetes Clusters wurden VM's mit Ubuntu-Server 20.04.4 erstellt.
> Raspberry Pi: Installation über Raspberry Pi Imager -> Ubuntu-Server 20.04

### 1.2 installation von K3s
Zum Installieren von K3s wurde das folgende Tutorial genutzt: <br>
https://computingforgeeks.com/install-kubernetes-on-ubuntu-using-k3s/

Da es sich um neu aufgesetzte Ubuntu-Server handelt, werden zuerst auf allen Geräten die folgenden Befehle ausgeführt
```bash
sudo apt update
sudo apt -y upgrade && sudo systemctl reboot
```

Nachdem alle Maschinen neu gestartet wurden, wird zunächst Docker installiert. In einigen Kubernetes Lösungen ist Docker bereits von Anfang an installiert. Da dies bei K3s nicht der Fall ist, muss dies händisch vorgenommen werden.
Dafür werden die folgenden Befehle auf allen Hosts ausgeführt. 
Zunächst wird das Repository hinzugefügt.
```bash
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```
> Raspberry Pi muss das amd64 zu arm64 geändert werden <br>
```sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable"```


Die Installation wird mit den folgenden Befehlen ausgeführt.
```bash
sudo apt update
sudo apt install docker-ce -y

# starten von docker 
sudo systemctl start docker
sudo systemctl enable docker
```

Damit nicht vor jedem Docker-Befehl sudo geschrieben werden muss, kann man die folgenden Befehle eingeben. (nicht notwendig)
```bash
sudo usermod -aG docker ${USER}
newgrp docker
```

### 1.3 Master Setup
```bash
# installation und starten von K3s
curl -sfL https://get.k3s.io | sh -s - --docker

# mit folgendem Befehl kann geprüft werden, ob K3s erfolgreich installiert wurde
systemctl status k3s

# Erlauben der Kommunikation zwischen  Worker und Master (über Ports 443 und 6443)
sudo ufw allow 6443/tcp
sudo ufw allow 443/tcp
```

Damit Worker mit dem Master verbunden werden können, muss der Node-Token des Masters ausgelesen werden. 
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

### 1.4 Worker Setup & verbindung zum Master
Für das Setup der Worker benötigen wir die IP-Adresse des Masters und den Token aus 1.3
```bash
curl -sfL http://get.k3s.io | K3S_URL=https://<IP-Adresse_Master>:6443 K3S_TOKEN=<Master_Token> sh -s - --docker
```
> Der verwendete Raspberry Pi 3b hat bei diesem Befehl eine Fehlermeldungen geworfen. <br> Zur Lösung musste
```/boot/firmware/cmdline.txt``` zu ```et.ifnames=0 dwc_otg.lpm_enable=0 console=serial0,115200 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 console=tty1 root=LABEL=writable rootfstype=ext4 elevator=deadline rootwait fixrtc``` ergänzt werden.

# 2 Deployment der Anwendung
### 2.1 Die Anwendung
Für die Anwendung wurde das folgende Tutorial: https://docs.docker.com/get-started/ genutzt. <br>
Nach dem Durchführen des Tutorial wurde an Stelle der MySQL-Datenbank mithilfe eines Docker-Compose-Files ein MariaDB-Galer1a-Container (https://hub.docker.com/r/bitnami/mariadb-galera/) angebunden. 

Das Image wurde in dockerhub hochgeladen. <br>
Repository: https://hub.docker.com/repository/docker/ironvortex/app

Im Git ist die Anwendung als "app" zu finden.

### 2.2 die Anwendung in Kubernetes 
Unter Zuhilfenahme von:
https://kubernetes.io/docs/tutorials/kubernetes-basics/deploy-app/deploy-interactive/
```bash
# Installation des Anwendungs-Image von DockerHub auf dem Kubernetes-Netz
sudo kubectl create deployment <Deployment_Name> --image=ironvortex/app:v0.1

# Prüfung ob Deployment ready
sudo kubectl get deployments
```
> An der Stelle wurde aufgegeben einen Raspberry Pi im Kubernetes-Netz zu betreiben, da die gebaute Anwendung auf diesem nicht lief. 

### 2.3 Skalieren der Anwendung
Unter Zuhilfenahme von:
https://kubernetes.io/docs/tutorials/kubernetes-basics/scale/scale-interactive/
```bash
# Anzeigen der replika sets
sudo kubectl get rs

# Erstellen der 3 Replikationen 
sudo kubectl scale deployments/<Deployment_Name> --replica=3

# Überprüfen der Pods mit laudenden Replikationen
sudo kubectl get pods -o wide
```

# 3 Einrichtung Galera-Cluster & HAProxy
### 3.1 Installation Helm 
Helm wird installiert um den Loadbalancer zu installieren und um das Galera-Cluster einzurichten 
Helm download von https://github.com/helm/helm/releases

```bash
# Entpacken von Helm
tar -xvcf <downloaded-file>

# Verschieben der entpackten Datei
sudo mv linux-amd64/helm /usr/local/bin/helm

# Überprüfung der Version
helm version
```
  
### 3.2 installation HAPRoxy als Loadbalancer 
Zur Installation genutze Dokumentation:
https://www.haproxy.com/documentation/kubernetes/latest/installation/community/kubernetes/

```bash
# hinzufügen des HAProxy repository und aktualisieren der Repository-Liste
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm repo update

# Installation von HAProxy, erstellen neuen Namespace und freigeben von NodePorts
helm install kubernetes-ingress haproxytech/kubernetes-ingress --create-namespace --namespace haproxy-controller --set controller.service.nodePorts.http=30000 --set controller.service.nodePorts.https=30001 --set controller.service.nodePorts.stat=30002
```

### 3.3 Einrichtung der Galera-Clusters

!Ab hier ist es nicht mehr umgesetzt!
> Deployment-Skript geht nur bis zum Schritt 2.3

# 4 Automatisierungsskripte 
Zum Vereinfachen des Setups wurden Shellskripte erstellt. "SetupK3s.sh" und "deploy_application.sh"

### 4.1 Verwendung
Zum Ausführen der Skripte müssen die passenden Rechte mit Chmod gesetzt werden. Aufgrund der enthaltenden Befehle benötigen die Skripte zum ausführen Sudo. Das "SetupK3s.sh" muss mit einer flag gestartet werden. ```-h = help``` ```-i = installation``` ```-d = deinstallation``` Beim Wählen von Installation und Deinstallation wird das Sktipt fragen, ob es sich um eine Master oder eine Worker-Node handelt. Das Skript ist das zuerst auszuführende. Es installiert alle notwendigen Programme und stellt die Funktionen ein. Auch die Deinstallation kann mit der Hilfe des Skriptes erfolgen. <br>
Das "deploy_application.sh" besitzt die ```-h = help``` flag, aber wird im Allgemeinen ohne diese aufgerufen. Dieses Skript ist für die Masternode bestimmt und führt automatisch, insofern vorerst das "SetupK3s.sh" ausgeführt wurde, das Erstellen eines Deployment und das Replizieren durch (so das 3 replicate vorhanden sind).
