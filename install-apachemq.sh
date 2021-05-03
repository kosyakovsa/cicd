echo ">>>>>>>>>>>> apache mq >>>>>>>>>>>>>>>>"

echo $1

export APACHEMQ="$1"

if [ -z "$APACHEMQ" ]; then
	echo "apachemq parameter is not defined. will use default 5.15.8 version"
	export APACHEMQ="5.15.8"
fi


# check if java installed

cd /tmp
wget http://archive.apache.org/dist/activemq/$APACHEMQ/apache-activemq-$APACHEMQ-bin.tar.gz
tar -xvzf apache-activemq-$APACHEMQ-bin.tar.gz
sudo mv apache-activemq-$APACHEMQ /opt/activemq
sudo addgroup --quiet --system activemq
sudo adduser --quiet --system --ingroup activemq --no-create-home --disabled-password activemq
sudo chown -R activemq:activemq /opt/activemq


echo "======================== apachemq configs ========================"
touch /etc/systemd/system/activemq.service
echo "[Unit]" >> /etc/systemd/system/activemq.service
echo "Description=Apache ActiveMQ" >> /etc/systemd/system/activemq.service
echo "After=network.target" >> /etc/systemd/system/activemq.service
echo "[Service]" >> /etc/systemd/system/activemq.service
echo "Type=forking" >> /etc/systemd/system/activemq.service

#echo "Environment=JAVA_HOME=/usr/lib/jvm/java-1.$JAVAVER.0-openjdk-amd64/jre" >> /etc/systemd/system/tomcat.service

echo "User=activemq" >> /etc/systemd/system/activemq.service
echo "Group=activemq" >> /etc/systemd/system/activemq.service
echo "" >> /etc/systemd/system/activemq.service
echo "ExecStart=/opt/activemq/bin/activemq start" >> /etc/systemd/system/activemq.service
echo "ExecStop=/opt/activemq/bin/activemq stop" >> /etc/systemd/system/activemq.service
echo "" >> /etc/systemd/system/activemq.service
echo "[Install]" >> /etc/systemd/system/activemq.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/activemq.service

sudo chown -R activemq:activemq /etc/systemd/system/tomcat.service
#chmod 777 /etc/systemd/system/tomcat.service

sudo systemctl daemon-reload
sudo systemctl start activemq
sudo systemctl enable activemq

echo "<<<<<<<<<<<<<<<<<<< apache mq <<<<<<<<<<<<<<<<<<<<<<"