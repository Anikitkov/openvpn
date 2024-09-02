#!/bin/bash

sudo apt-get install -y openvpn 
echo $?
~/easy-rsa/easyrsa gen-req server nopass
 
~/easy-rsa/easyrsa sign-req server server
echo $?
sudo cp pki/issued/server.crt /etc/openvpn/server/
echo $?

sudo cp pki/ca.crt /etc/openvpn/server/
echo $?

/usr/sbin/openvpn --genkey --secret ta.key
echo $?

sudo cp ta.key /etc/openvpn/server
echo $?

mkdir -p ~/clients/keys
echo $?

#chmod -R 700 ~/clients 
#Нет прав на папки для не рута
echo $?

#sudo ~/easy-rsa/easyrsa gen-req client-1 nopass
~/easy-rsa/easyrsa gen-req client-1 nopass

echo $?
sudo cp pki/private/client-1.key ./clients/keys/
echo $?
~/easy-rsa/easyrsa sign-req client client-1
echo $?
sudo cp ta.key ~/clients/keys/
echo $?
sudo cp pki/issued/client-1.crt ~/clients/keys/
echo $?
#chown $USER:$USER ~/clients/keys/*
echo $?

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/
echo $?
sudo cp ~/pki/private/server.key /etc/openvpn/server/
echo $?
sudo cp /etc/openvpn/server/server.conf server.bak
sudo chmod 777 /etc/openvpn/server/server.conf

sudo sed -i 's/.*tls-auth ta.key 0.*/tls-crypt ta.key/' /etc/openvpn/server/server.conf
echo $?

sudo sed -i 's/.*cipher AES-256-CBC.*/cipher AES-256-GCM/' /etc/openvpn/server/server.conf
echo $?


sudo sed -i 's/.*dh.*/;dh/' /etc/openvpn/server/server.conf
echo "dh none" >> /etc/openvpn/server/server.conf
echo $?

sudo sed -i 's/.*;user nobody.*/user nobody/' /etc/openvpn/server/server.conf
echo $?

sudo sed -i 's/.*;group no.*/group nogroup/' /etc/openvpn/server/server.conf
echo $?

sudo sed -i 's/.*#net.ipv4.ip_forward=1.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
echo $?
sysctl -p
i=$(ls /sys/class/net |grep enp) #Retrieve the interface number

sudo ~/iptables.sh i udp 1194

echo $?


mkdir -p ~/clients/files

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/clients/base.conf
echo $?
ip=$(hostname -I)
sed -i 's/.*remote my-server 1194.*/remote $ip 1194/' ~/clients/base.conf

sed -i 's/.*user no.*/user nobody/' ~/clients/base.conf
sed -i 's/.*group no.*/group nogroup/' ~/clients/base.conf

sed -i 's/.*ca ca.crt.*/;ca ca.crt./' ~/clients/base.conf
sed -i 's/.*cert client.crt.*/;cert client.crt./' ~/clients/base.conf
sed -i 's/.*key client.key.*/;key client.key./' ~/clients/base.conf
sed -i 's/.*tls-auth ta.key 1.*/;tls-crypt ta.key 1./' ~/clients/base.conf
sed -i 's/.*cipher.*/cipher AES-256-GCM./' ~/clients/base.conf
echo "auth SHA256" >> ~/clients/base.conf
echo "key-direction 1" >> ~/clients/base.conf
#chmod 700 ~/clients/make_config.sh
sudo cp ~/pki/ca.crt ~/client/keys
sudo chown $USER:$USER ~/client/keys/ca.crt
~/make_config.sh /client-1

echo $?







