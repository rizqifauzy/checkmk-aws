#!/bin/bash

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
  sleep 1
done

#enable root login
sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
sudo chown root:root /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys
sudo echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
sudo systemctl restart sshd

#change hostname
sudo hostnamectl set-hostname checkmk-server
sudo systemctl restart rsyslog

# create fs /opt
sudo printf 'o\nn\np\n1\n\n\nt\n8e\nw' | fdisk /dev/nvme1n1
sudo pvcreate /dev/nvme1n1 -y
sudo vgcreate vg_opt /dev/nvme1n1
sudo lvcreate -l 100%FREE -n lv_opt vg_opt
sudo mkfs.ext4 /dev/mapper/vg_opt-lv_opt
sudo mount /dev/mapper/vg_opt-lv_opt /opt
sudo echo -e "/dev/mapper/vg_opt-lv_opt\t/opt\text4\tdefaults 0 0" >> /etc/fstab

# install checkmk
sudo apt-get update
sudo apt-get upgrade -y
wget https://download.checkmk.com/checkmk/2.1.0p15/check-mk-free-2.1.0p15_0.focal_amd64.deb
sudo apt install ./check-mk-free-2.1.0p15_0.focal_amd64.deb -y
sudo omd create vibi_site >> /opt/checkmk-passwd

#start site
sudo omd start vibi_site

#securing with https
sudo a2enmod ssl
sudo a2enmod headers

# import cert
sudo mkdir /etc/apache2/cert
sudo mv /tmp/monitoring1.vibicloud.id.crt /etc/apache2/cert/monitoring1.vibicloud.id.crt
sudo mv /tmp/monitoring1.vibicloud.id.key /etc/apache2/cert/monitoring1.vibicloud.id.key
sudo mv /tmp/CACert.crt /etc/apache2/cert/CACert.crt
sudo chown root:root -R /etc/apache2/cert
sudo chmod 644 /etc/apache2/cert/*

#import config
sudo mv -f /tmp/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf
sudo mv -f /tmp/000-default.conf /etc/apache2/sites-enabled/000-default.conf
sudo chown root:root /etc/apache2/sites-enabled/*
sudo chmod 644 /etc/apache2/sites-enabled/*

# restart apache
sudo systemctl restart apache2
sudo cat /opt/checkmk-passwd
sudo rm -rf /opt/checkmk-passwd
