#!/bin/bash
sudo apt-get update && sudo apt-get dist-upgrade -y 

sudo ufw default deny incoming
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 53
sudo ufw allow 1194
sudo ufw enable

if [ $? -eq 0 ];
then

        echo "configuring firewall has been completed"
else
        echo "configuring firewall has fall"
        exit 1
fi

sudo apt-get install -y openvpn 
if [ $? -eq 0 ];
then

        echo "install openvpn has been completed"
else
        echo "install openvpn hasn't been completed"
        exit 1
fi

#Need copied certificate from easyrsa. pki: ca.crt pki/issued server.crt,client-1.crt. pki/private:server.key, client-1.key, ca.key
#mkdir -p /home/$USER/certificates
#mkdir /home/$USER/certificates/server
#mkdir /home/$USER/certificates/client
mkdir -p /home/$USER/clients/keys

sudo cp -r /home/$USER/ca.crt /etc/openvpn/server
echo $?
sudo cp -r /home/$USER/ca.key /etc/openvpn/server

echo $?

sudo cp -r /home/$USER/server.crt /etc/openvpn/server

echo $?

sudo cp -r /home/$USER/server.key /etc/openvpn/server

echo $?


cp -r /home/$USER/ca.crt /home/$USER/clients/keys
echo $?
cp -r /home/$USER/ca.key /home/$USER/clients/keys
echo $?

cp -r /home/$USER/client-1.crt /home/$USER/clients/keys
echo $?

cp -r /home/$USER/client-1.key /home/$USER/clients/keys
echo $?


#cp -r /home/$USER/*.crt /etc/certificates/server 
#mkdir -p ~/clients/keys
/usr/sbin/openvpn --genkey --secret ta.key

if [ $? -eq 0 ];
then

        echo "ta.key has been issuded"
else
        echo "ta.key hasn't been issuded"
        exit 1
fi
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/
#sudo cp /etc/openvpn/server/client-1.crt ~/clients/keys
#chown $USER:$USER /home/$USER/clients/keys/ca.crt 
sudo cp /home/$USER/ta.key /etc/openvpn/server
cp /home/$USER/ta.key /home/$USER/clients/keys
echo $?
#sudo cp server.key /etc/openvpn/server
#sudo cp client-1.key ~/clients/keys/
sudo cp /etc/openvpn/server/server.conf /etc/openvpn/server/server.bak #backup server config
sudo chown $USER:$USER /etc/openvpn/server/server.conf
#sudo chmod 777 /etc/openvpn/server/server.conf
# change config auto
sudo sed -i 's/.*tls-auth ta.key 0.*/tls-crypt ta.key/' /etc/openvpn/server/server.conf
sudo sed -i 's/.*cipher AES-256-CBC.*/cipher AES-256-GCM/' /etc/openvpn/server/server.conf
echo"" >> /etc/openvpn/server/server.conf
echo "auth SHA256" >> /etc/openvpn/server/server.conf #Накладывается на предыдущую строку 
sudo sed -i 's/.*dh dh2048.pem.*/;dh dh2048.pem/' /etc/openvpn/server/server.conf
echo "dh none" >> /etc/openvpn/server/server.conf 
sudo sed -i 's/.*;user nobody.*/user nobody/' /etc/openvpn/server/server.conf
sudo sed -i 's/.*;group no.*/group nogroup/' /etc/openvpn/server/server.conf
sudo sed -i 's/.*#net.ipv4.ip_forward=1.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf 
sudo sysctl -p
i=$(ls /sys/class/net |grep en) #Retrieve the interface number
sudo /home/$USER/openvpn/iptables.sh $i udp 1194 
sudo systemctl -f enable openvpn-server@server.service
sudo systemctl start openvpn-server@server.service

if [ $? -eq 0 ];
then

        echo "Openvpn server.service start"
else
        echo "Openvpn server.service hasn't start"
        exit 1  
fi

mkdir -p /home/$USER/clients/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /home/$USER/clients/base.conf
cp  /home/$USER/clients/base.conf  /home/$USER/clients/base.bak #backup client config
ip=$(hostname -I | awk '{print $1}')

#change client config auto
sed -i 's/.*remote my-server-1 1194.*/;remote my-server-1 1194/'  /home/$USER/clients/base.conf
echo "remote $ip 1194" >>  /home/$USER/clients/base.conf
sed -i 's/.*;user nobody.*/user nobody/' /home/$USER/clients/base.conf
sed -i 's/.*;group nobody.*/group nogroup/' /home/$USER/clients/base.conf
sed -i 's/.*ca ca.crt.*/;ca ca.crt/' /home/$USER/clients/base.conf
sed -i 's/.*cert client.crt.*/;cert client.crt/' /home/$USER/clients/base.conf
sed -i 's/.*key client.key.*/;key client.key/' /home/$USER/clients/base.conf
sed -i 's/.*tls-auth ta.key 1.*/;tls-crypt ta.key 1/' /home/$USER/clients/base.conf
sed -i 's/.*cipher AES-256-CBC.*/cipher AES-256-GCM/' /home/$USER/clients/base.conf
echo "auth SHA256" >> /home/$USER/clients/base.conf
echo "key-direction 1" >> /home/$USER/clients/base.conf
sudo cp /home/$USER/openvpn/make-config.sh /home/$USER/clients
#sudo chmod 777  ~/clients/make-config.sh
sudo chown $USER:$USER /home/$USER/clients/make-config.sh
/home/$USER/clients/make-config.sh client-1
#sudo cp ca.crt ~/clients/keys/
#/home/alex/clients/make-config.sh

cp /home/$USER/clients/files/*.ovpn /home/$USER
