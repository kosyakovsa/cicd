groupadd tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
cd /tmp

read -p "Choose tomcat version (8.5.57 by default - ENTER): " TOMCATVER
if [ -z "$TOMCATVER" ]; then
	export TOMCATVER="8.5.57"
fi


wget --no-check-certificate "http://apache.mirrors.ionfish.org/tomcat/tomcat-8/v$TOMCATVER/bin/apache-tomcat-$TOMCATVER.tar.gz" -O "apache-tomcat-$TOMCATVER.tar.gz"

mkdir /opt/tomcat
sudo tar xzvf apache-tomcat-$TOMCATVER.tar.gz -C /opt/tomcat --strip-components=1
cd /opt/tomcat
chgrp -R tomcat /opt/tomcat
chmod -R g+r conf
chmod g+x conf
chown -R tomcat webapps/ work/ temp/ logs/


read -p "Enter memory of java|tomcat settings (at least 256, 512 - by default - ENTER): " JAVAMEMORY
if [ -z "$JAVAMEMORY" ]; then
	export JAVAMEMORY="512"
fi


echo "======================== tomcat configs ========================"
touch /etc/systemd/system/tomcat.service
echo "[Unit]" >> /etc/systemd/system/tomcat.service
echo "Description=Apache Tomcat Web App Container" >> /etc/systemd/system/tomcat.service
echo "After=network.target" >> /etc/systemd/system/tomcat.service
echo "" >> /etc/systemd/system/tomcat.service
echo "[Service]" >> /etc/systemd/system/tomcat.service
echo "Type=forking" >> /etc/systemd/system/tomcat.service
echo "" >> /etc/systemd/system/tomcat.service
echo "Environment=JAVA_HOME=/usr/lib/jvm/java-1.$JAVAVER.0-openjdk-amd64/jre" >> /etc/systemd/system/tomcat.service
echo "Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid" >> /etc/systemd/system/tomcat.service
echo "Environment=CATALINA_HOME=/opt/tomcat" >> /etc/systemd/system/tomcat.service
echo "Environment=CATALINA_BASE=/opt/tomcat" >> /etc/systemd/system/tomcat.service
echo "Environment='CATALINA_OPTS=-Xms256M -Xmx$JAVAMEMORY""M -server -XX:+UseParallelGC'" >> /etc/systemd/system/tomcat.service
echo "Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'" >> /etc/systemd/system/tomcat.service
echo "" >> /etc/systemd/system/tomcat.service
echo "ExecStart=/opt/tomcat/bin/startup.sh" >> /etc/systemd/system/tomcat.service
echo "ExecStop=/opt/tomcat/bin/shutdown.sh" >> /etc/systemd/system/tomcat.service
echo "" >> /etc/systemd/system/tomcat.service
echo "User=tomcat" >> /etc/systemd/system/tomcat.service
echo "Group=tomcat" >> /etc/systemd/system/tomcat.service
echo "UMask=0007" >> /etc/systemd/system/tomcat.service
echo "RestartSec=10" >> /etc/systemd/system/tomcat.service
echo "Restart=always" >> /etc/systemd/system/tomcat.service
echo "" >> /etc/systemd/system/tomcat.service
echo "[Install]" >> /etc/systemd/system/tomcat.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/tomcat.service

chmod 777 /etc/systemd/system/tomcat.service

#echo "============================= tomcat settings =========================="
#read -p "Enter tomcat admin name: " TOMCATADMIN
#read -p "Enter tomcat admin password ((you may always change it into /opt/tomcat/conf/tomcat-users.xml file): " TOMCATPASS


#rm /opt/tomcat/conf/tomcat-users.xml
#touch /opt/tomcat/conf/tomcat-users.xml

#echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/tomcat-users.xml
#echo "<tomcat-users xmlns=\"http://tomcat.apache.org/xml\"" >> /opt/tomcat/conf/tomcat-users.xml
#echo "xmln:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" >> /opt/tomcat/conf/tomcat-users.xml
#echo "xsi:schemaLocation=\"http://tomcat.apache.org/xml tomcat-users.xsd\"" >> /opt/tomcat/conf/tomcat-users.xml
#echo "version=\"1.0\">" >> /opt/tomcat/conf/tomcat-users.xml
#echo "<user username=\""${TOMCATADMIN}"\" password=\""${TOMCATPASS}"\" roles=\"admin,admin-gui,manager,manager-gui,script,script-gui\"/>" >> /opt/tomcat/conf/tomcat-users.xml
#echo "</tomcat-users>" >> /opt/tomcat/conf/tomcat-users.xml

#chmod 777 /opt/tomcat/conf/tomcat-users.xml
#chown tomcat /opt/tomcat/conf/tomcat-users.xml



#rm /opt/tomcat/conf/server.xml
#touch /opt/tomcat/conf/server.xml


#for certificate and usability at work we should accept web connection on 80 port
iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

read -p "Do you need to load certificate for enabling SSL(yes, other?): " ENABLESSL
if [[ "$ENABLESSL" == "yes" ]]; then
  read -p "What is your internet domain name for platform (f.e. bg.yourbank.com): " DOMNAME

  echo "=================== starting tomcat with default settings to download certificate=================="
  systemctl daemon-reload
  systemctl start tomcat
#  systemctl status tomcat

  #robot for download and update certificates
  sudo apt-get install software-properties-common
  sudo add-apt-repository universe
  sudo add-apt-repository ppa:certbot/certbot
  sudo apt-get update

  sudo apt-get install certbot

  echo ""
  echo "Enter settings for certbot (press ENTER)"
  read
  sudo certbot certonly --webroot

  echo
  echo "Don't forget to add command {sudo certbot renew --dry-run} into crontab (press ENTER)"
  read
#sudo certbot renew --dry-run

  echo "================ copy new certificate to tomcat path ==============================="
  mkdir /opt/tomcat/conf/cert
  cp /etc/letsencrypt/archive/$DOMNAME/cert1.pem /opt/tomcat/conf/cert/cert.pem
  cp /etc/letsencrypt/archive/$DOMNAME/privkey1.pem /opt/tomcat/conf/cert/privkey.pem
  chown tomcat /opt/tomcat/conf/cert
  chown tomcat /opt/tomcat/conf/cert/cert.pem



  systemctl stop tomcat



#  echo "writing server.conf with SSL"
#  rm /opt/tomcat/conf/server.xml
#  touch /opt/tomcat/conf/server.xml

#  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/server.xml
#  echo "<Server port=\"8005\" shutdown=\"SHUTDOWN\">" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.startup.VersionLoggerListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.core.AprLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.mbeans.GlobalResourcesLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.core.ThreadLocalLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
#  echo "<Resource name=\"UserDatabase\" auth=\"Container\" type=\"org.apache.catalina.UserDatabase\" description=\"User database that can be updated and saved\" factory=\"org.apache.catalina.users.MemoryUserDatabaseFactory\" pathname=\"conf/tomcat-users.xml\" />" >> /opt/tomcat/conf/server.xml
#  echo "</GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
#  echo "<Service name=\"Catalina\">" >> /opt/tomcat/conf/server.xml
#  echo "<Connector port=\"8080\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Connector port=\"8443\" maxHttpHeaderSize=\"8192\" maxThreads=\"500\" enableLookups=\"false\" disableUploadTimeout=\"true\" acceptCount=\"500\" scheme=\"https\" secure=\"true\" SSLEnabled=\"true\" sslProtocol=\"TLS\" sslEnabledProtocols=\"TLSv1.2\" SSLCetificateFile=\"/opt/tomcat/conf/cert/certificate.crt\" SSLCertificateKeyFile=\"/opt/tomcat/conf/cert/private.key\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Connector port=\"8009\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Engine name=\"Catalina\" defaultHost=\"localhost\">" >> /opt/tomcat/conf/server.xml
#  echo "<Realm className=\"org.apache.catalina.realm.LockOutRealm\">" >> /opt/tomcat/conf/server.xml
#  echo "<Realm className=\"org.apache.catalina.realm.UserDatabaseRealm\" resourceName=\"UserDatabase\" />" >> /opt/tomcat/conf/server.xml
#  echo "</Realm>" >> /opt/tomcat/conf/server.xml
#  echo "<Host name=\"localhost\" appBase=\"webapps\" unpackWARs=\"true\" autoDeploy=\"true\" >" >> /opt/tomcat/conf/server.xml
#  echo "<Valve className=\"org.apache.catalina.valves.AccessLogValue\" directory=\"logs\" prefix=\"localhost_access_log\" suffix=\".txt\" pattern=\"%h %l %u %t &quot;%r&quot; %s %b\" />" >> /opt/tomcat/conf/server.xml
#  echo "</Host>" >> /opt/tomcat/conf/server.xml
#  echo "</Engine>" >> /opt/tomcat/conf/server.xml
#  echo "</Service>" >> /opt/tomcat/conf/server.xml
#  echo "</Server>" >> /opt/tomcat/conf/server.xml

  echo "============================= writing ports ====================="

  iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 8443 -j ACCEPT
  iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443
  iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443

else
  echo "writing server.conf without SSL"
#  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/server.xml
#  echo "<Server port=\"8005\" shutdown=\"SHUTDOWN\">" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.startup.VersionLoggerListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.core.AprLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.mbeans.GlobalResourcesLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Listener className=\"org.apache.catalina.core.ThreadLocalLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
#  echo "<GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
#  echo "<Resource name=\"UserDatabase\" auth=\"Container\" type=\"org.apache.catalina.UserDatabase\" description=\"User database that can be updated and saved\" factory=\"org.apache.catalina.users.MemoryUserDatabaseFactory\" pathname=\"conf/tomcat-users.xml\" />" >> /opt/tomcat/conf/server.xml
#  echo "</GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
#  echo "<Service name=\"Catalina\">" >> /opt/tomcat/conf/server.xml
#  echo "<Connector port=\"8080\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
#  #echo "<Connector port=\"8443\" maxHttpHeaderSize=\"8192\" maxThreads=\"500\" enableLookups=\"false\" disableUploadTimeout=\"true\" acceptCount=\"500\" scheme=\"https\" secure=\"true\" SSLEnabled=\"true\" SSLCetificateFile=\"/opt/tomcat/conf/cert/certificate.crt\" SSLCertificateKeyFile=\"/opt/tomcat/conf/cert/private.key\" />" >> /opt/tomcat/conf/server.xml#
#  echo "<Connector port=\"8009\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
#  echo "<Engine name=\"Catalina\" defaultHost=\"localhost\">" >> /opt/tomcat/conf/server.xml
#  echo "<Realm className=\"org.apache.catalina.realm.LockOutRealm\">" >> /opt/tomcat/conf/server.xml
#  echo "<Realm className=\"org.apache.catalina.realm.UserDatabaseRealm\" resourceName=\"UserDatabase\" />" >> /opt/tomcat/conf/server.xml
#  echo "</Realm>" >> /opt/tomcat/conf/server.xml
#  echo "<Host name=\"localhost\" appBase=\"webapps\" unpackWARs=\"true\" autoDeploy=\"true\" >" >> /opt/tomcat/conf/server.xml
#  echo "<Valve className=\"org.apache.catalina.valves.AccessLogValue\" directory=\"logs\" prefix=\"localhost_access_log\" suffix=\".txt\" pattern=\"%h %l %u %t &quot;%r&quot; %s %b\" />" >> /opt/tomcat/conf/server.xml
#  echo "</Host>" >> /opt/tomcat/conf/server.xml
#  echo "</Engine>" >> /opt/tomcat/conf/server.xml
#  echo "</Service>" >> /opt/tomcat/conf/server.xml
#  echo "</Server>" >> /opt/tomcat/conf/server.xml
fi


#chmod 777 /opt/tomcat/conf/server.xml
#chown tomcat /opt/tomcat/conf/server.xml

echo "================== saving port forwarding settings ============================"
sudo apt-get install iptables-persistent

echo "===================final starting tomcat =================="
systemctl daemon-reload
systemctl start tomcat
#systemctl status tomcat
sudo systemctl enable tomcat