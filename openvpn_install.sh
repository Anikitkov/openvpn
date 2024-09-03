#!/bin/bash

cd ~
chmod +x openvpn/*

cp 
sudo apt-get install -y openvpn 
~/easy-rsa/easyrsa gen-req server nopass
 
~/easy-rsa/easyrsa sign-req server server
sudo cp pki/issued/server.crt /etc/openvpn/server/
sudo cp pki/ca.crt /etc/openvpn/server/
/usr/sbin/openvpn --genkey --secret ta.key
sudo cp ta.key /etc/openvpn/server
mkdir -p ~/clients/keys
#chmod -R 700 ~/clients 
#Нет прав на папки для не рута
#sudo ~/easy-rsa/easyrsa gen-req client-1 nopass
~/easy-rsa/easyrsa gen-req client-1 nopass

sudo cp pki/private/client-1.key ./clients/keys/
~/easy-rsa/easyrsa sign-req client client-1
sudo cp ta.key ~/clients/keys/
sudo cp pki/issued/client-1.crt ~/clients/keys/
#chown $USER:$USER ~/clients/keys/*
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/
sudo cp ~/pki/private/server.key /etc/openvpn/server/
sudo cp /etc/openvpn/server/server.conf server.bak #backup server config
sudo chmod 777 /etc/openvpn/server/server.conf
sudo sed -i 's/.*tls-auth ta.key 0.*/tls-crypt ta.key/' /etc/openvpn/server/server.conf
sudo sed -i 's/.*cipher AES-256-CBC.*/cipher AES-256-GCM/' /etc/openvpn/server/server.conf
echo "auth SHA256" >> /etc/openvpn/server/server.conf
sudo sed -i 's/.*dh dh2048.pem.*/;dh dh2048.pem/' /etc/openvpn/server/server.conf
echo "dh none" >> /etc/openvpn/server/server.conf
sudo sed -i 's/.*;user nobody.*/user nobody/' /etc/openvpn/server/server.conf
sudo sed -i 's/.*;group no.*/group nogroup/' /etc/openvpn/server/server.conf
sudo sed -i 's/.*#net.ipv4.ip_forward=1.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
i=$(ls /sys/class/net |grep en) #Retrieve the interface number
sudo ~/openvpn/iptables.sh $i udp 1194 
sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service

mkdir -p ~/clients/files

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/clients/base.conf
sudo cp ~/clients/base.conf base.bak #backup client config
ip=$(hostname -I | awk '{print $1}')

sed -i 's/.*remote my-server-1 1194.*/;remote my-server-1 1194/' ~/clients/base.conf
echo "remote $ip 1194" >> ~/clients/base.conf

sed -i 's/.*;user nobody.*/user nobody/' ~/clients/base.conf
sed -i 's/.*;group nobody.*/group nogroup/' ~/clients/base.conf

sed -i 's/.*ca ca.crt.*/;ca ca.crt/' ~/clients/base.conf
sed -i 's/.*cert client.crt.*/;cert client.crt/' ~/clients/base.conf
sed -i 's/.*key client.key.*/;key client.key/' ~/clients/base.conf
sed -i 's/.*tls-auth ta.key 1.*/;tls-crypt ta.key 1/' ~/clients/base.conf
sed -i 's/.*cipher AES-256-CBC.*/cipher AES-256-GCM/' ~/clients/base.conf
echo "auth SHA256" >> ~/clients/base.conf
echo "key-direction 1" >> ~/clients/base.conf
sudo cp ~/openvpn/make-config.sh clients
#chmod +x clients/make-config.sh

#chmod 700 ~/clients/make_config.sh
sudo cp ~/pki/ca.crt ~/clients/keys/
sudo chown $USER:$USER ~/clients/keys/*
~/clients/make-config.sh client-1








