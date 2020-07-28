#!/bin/sh

set -euxo pipefail

echo "This script can be used to install Prometheus. This script has been tested with CentOS 7"

#################### run package update ##################

sudo yum update -y
sudo yum install wget nvme-cli -y

############ Create Prometheus system group and user  #############
sudo useradd --no-create-home -s /bin/false prometheus

######## Create data and config directory for Prometheus  ##########
sudo mkdir /var/lib/prometheus
sudo mkdir /etc/prometheus

######## Change owner and group for data and config directory to Prometheus  ##########
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

################## Download Prometheus ##################
sudo yum -y install wget
cd /tmp
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64 \
  | cut -d '"' -f 4 \
  | wget -qi -
tar xvf prometheus*.tar.gz

#Move Prometheus files to /var/lib/prometheus directory
mv prometheus*/* /var/lib/prometheus/
#Adjust owner and group of /var/lib/prometheus directories.
chown -R prometheus:prometheus /var/lib/prometheus
# Move Prometheus configuration file in /etc/prometheus directory.
cd ~/
sudo mv /var/lib/prometheus/prometheus.yml /etc/prometheus/
# Create a soft link of prometheus command file, so we can execute the prometheus command from CLI.
sudo ln -s /var/lib/prometheus/prometheus /usr/local/bin/prometheus

############### Create prometheus service ###############
tee -a /etc/systemd/system/prometheus.service << END
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/var/lib/prometheus/consoles \
  --web.console.libraries=/var/lib/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
END


################## enable prometheus service #########################
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

################## configure firewalld #########################
sudo yum install firewalld -y
sudo systemctl daemon-reload
sudo systemctl start firewalld
sudo systemctl enable firewalld
firewall-cmd --add-port=9090/tcp --permanent
firewall-cmd --reload


############## stop prometheus #################
sudo systemctl stop prometheus
sudo systemctl stop firewalld
