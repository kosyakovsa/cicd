apt-get update && apt-get install build-essential wget -y


apt-get install -y mc
apt-get install -y wget

#apt-get install -y curl
echo "???????????????????????????????????????"
read -p "install network mount packages? (Is your file store located on other server?) (yes, other) " INSTALLCIFS
if [[ "$INSTALLCIFS" == "yes" ]]; then
	apt-get install -y samba samba-common python-glade2 system-confi-samba samba-client
	apt-get install -y cifs-utils
else
    echo "skiping cifs depends on user choose"
fi



# Build openssl no ask for version because troubles with compile
export OPENSSL_VERSION=1.1.0g
export OPENSSL_SHA256="de4d501267da39310905cb6dc8c6121f7a2cad45a7707f76df828fe1b85073af"

echo "========================== start openssl ===================================="
#read

# Build openssl no ask for version because troubles with compile
cd /usr/local/src \
  && wget --no-check-certificate "https://www.openssl.org/source/old/1.1.0/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath,/usr/local/ssl/lib \
  && make && make install \
  && mv /usr/bin/openssl /root/ \
  && ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl \
  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" "/usr/local/src/openssl-${OPENSSL_VERSION}" 

echo "============================ update openssl paths ==============================="
#read

 Update path of shared libraries
echo "/usr/local/ssl/lib" >> /etc/ld.so.conf.d/ssl.conf && ldconfig

echo "======================================== GOST ENGINE =================================="
# Build GOST-engine for OpenSSL
export GOST_ENGINE_VERSION=3bd506dcbb835c644bd15a58f0073ae41f76cb06
export GOST_ENGINE_SHA256="4777b1dcb32f8d06abd5e04a9a2b5fe9877c018db0fc02f5f178f8a66b562025"
apt-get update && apt-get install cmake unzip -y \
  && cd /usr/local/src \
  && wget --no-check-certificate "https://github.com/gost-engine/engine/archive/${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
  && echo "$GOST_ENGINE_SHA256" gost-engine.zip | sha256sum -c - \
  && unzip gost-engine.zip -d ./ \
  && cd "engine-${GOST_ENGINE_VERSION}" \
  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-I/usr/local/ssl/include -L/usr/local/ssl/lib' \
   -DOPENSSL_ROOT_DIR=/usr/local/ssl  -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/include -DOPENSSL_LIBRARIES=/usr/local/ssl/lib .. \
  && cmake --build . --config Release \
  && cd ../bin \
  && cp gostsum gost12sum /usr/local/bin \
  && cd .. \
  && cp bin/gost.so /usr/local/ssl/lib/engines-1.1 \
  && rm -rf "/usr/local/src/gost-engine.zip" "/usr/local/src/engine-${GOST_ENGINE_VERSION}" 


echo "=================================== enabling GOST ENGINE (ssl conf) ========================"
# Enable engine
sed -i '6i openssl_conf=openssl_def' /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# OpenSSL default section" >> /usr/local/ssl/openssl.cnf \
  && echo "[openssl_def]" >> /usr/local/ssl/openssl.cnf \
  && echo "engines = engine_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine scetion" >> /usr/local/ssl/openssl.cnf \
  && echo "[engine_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "gost = gost_section" >> /usr/local/ssl/openssl.cnf \
  && echo "" >> /usr/local/ssl/openssl.cnf \
  && echo "# Engine gost section" >> /usr/local/ssl/openssl.cnf \
  && echo "[gost_section]" >> /usr/local/ssl/openssl.cnf \
  && echo "engine_id = gost" >> /usr/local/ssl/openssl.cnf \
  && echo "dynamic_path = /usr/local/ssl/lib/engines-1.1/gost.so" >> /usr/local/ssl/openssl.cnf \
  && echo "default_algorithms = ALL" >> /usr/local/ssl/openssl.cnf \
  && echo "CRYPT_PARAMS = id-Gost28147-89-CryptoPro-A-ParamSet" >> /usr/local/ssl/openssl.cnf


echo "=========================== stunnel (secured connector) =========================================="

echo "???????????????????????????????????????"
read -p "Do you need secured tunnel to others resources (NBKI for example)?: (yes, other)" STUN
if [[ "$STUN" == "yes" ]]; then
  read -p "Enter stunnel version (5.56 default - ENTER): " STUNVER
  if [ -z "$STUNVER" ]; then
	export STUNVER="5.56"
  fi
  
  # Rebuild stunnel
  export STUNNEL_VERSION=$STUNVER
  export STUNNEL_SHA256="951d92502908b852a297bd9308568f7c36598670b84286d3e05d4a3a550c0149"
  cd /usr/local/src \
    && wget --no-check-certificate "https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz" -O "stunnel-${STUNNEL_VERSION}.tar.gz" \
    && tar -zxvf "stunnel-${STUNNEL_VERSION}.tar.gz" \
    && cd "stunnel-${STUNNEL_VERSION}" \
    && CPPFLAGS="-I/usr/local/ssl/include" LDFLAGS="-L/usr/local/ssl/lib -Wl,-rpath,/usr/local/ssl/lib" LD_LIBRARY_PATH=/usr/local/ssl/lib \
     ./configure --prefix=/usr/local/stunnel --with-ssl=/usr/local/ssl \
    && make \
    && make install \
    && ln -s /usr/local/stunnel/bin/stunnel /usr/bin/stunnel \
  && rm -rf "/usr/local/src/stunnel-${STUNNEL_VERSION}.tar.gz" "/usr/local/src/stunnel-${STUNNEL_VERSION}"


  echo "============================ stunnel conf (secured connector) ======================"
  echo "starting by file /etc/init.d/startstunnel"
  echo "samples in file /etc/stunnel/stunnel.conf. uncomment/add configurations to start working. Only demo NBKI is allowed by default"
  echo "PRESS ENTER........................."
  read

  mkdir /etc/stunnel
  touch /etc/stunnel/stunnel.conf
  echo "foreground = yes" >> /etc/stunnel/stunnel.conf
  echo "debug = 7" >> /etc/stunnel/stunnel.conf
  echo "output = /var/log/stunnel.log" >> /etc/stunnel/stunnel.conf
  echo "socket=l:TCP_NODELAY=1" >> /etc/stunnel/stunnel.conf
  echo "socket=r:TCP_NODELAY=1" >> /etc/stunnel/stunnel.conf

  echo "" >> /etc/stunnel/stunnel.conf

  echo "[nbki-direct]" >> /etc/stunnel/stunnel.conf
  echo "client = yes" >> /etc/stunnel/stunnel.conf
  echo "accept = 8000" >> /etc/stunnel/stunnel.conf
  echo "connect = icrs.nbki.ru:443" >> /etc/stunnel/stunnel.conf
  echo ";protocol = connect" >> /etc/stunnel/stunnel.conf
  echo "protocolHost = icrs.nbki.ru:443" >> /etc/stunnel/stunnel.conf
  echo "verify=0" >> /etc/stunnel/stunnel.conf

  echo "" >> /etc/stunnel/stunnel.conf

  echo ";[nbki-proxy]" >> /etc/stunnel/stunnel.conf
  echo ";client = yes" >> /etc/stunnel/stunnel.conf
  echo ";accept = 8001" >> /etc/stunnel/stunnel.conf
  echo ";connect = proxyaddr:proxyport" >> /etc/stunnel/stunnel.conf
  echo ";protocol = connect" >> /etc/stunnel/stunnel.conf
  echo ";protocolHost = icrs.nbki.ru:443" >> /etc/stunnel/stunnel.conf
  echo ";verify=0" >> /etc/stunnel/stunnel.conf

  echo "" >> /etc/stunnel/stunnel.conf

  echo "[demo-direct]" >> /etc/stunnel/stunnel.conf
  echo "client = yes" >> /etc/stunnel/stunnel.conf
  echo "accept = 8002" >> /etc/stunnel/stunnel.conf
  echo "connect = icrs.demo.nbki.ru:443" >> /etc/stunnel/stunnel.conf
  echo ";protocol = connect" >> /etc/stunnel/stunnel.conf
  echo "protocolHost = icrs.demo.nbki.ru:443" >> /etc/stunnel/stunnel.conf
  echo "verify=0" >> /etc/stunnel/stunnel.conf

  echo "" >> /etc/stunnel/stunnel.conf

  echo ";[demo-proxy]" >> /etc/stunnel/stunnel.conf
  echo ";client = yes" >> /etc/stunnel/stunnel.conf
  echo ";accept = 8003" >> /etc/stunnel/stunnel.conf
  echo ";connect = proxyaddr:proxyport" >> /etc/stunnel/stunnel.conf
  echo ";protocol = connect" >> /etc/stunnel/stunnel.conf
  echo ";protocolHost = icrs.demo.nbki.ru:443" >> /etc/stunnel/stunnel.conf
  echo ";verify=0" >> /etc/stunnel/stunnel.conf

  touch /etc/init.d/startstunnel
  echo "#!/bin/bash" >> /etc/init.d/startstunnel
  echo "### BEGIN INIT INFO" >> /etc/init.d/startstunnel
  echo "# Provides: startstunnel" >> /etc/init.d/startstunnel
  echo "# Required-Start: $all" >> /etc/init.d/startstunnel
  echo "# Required-Stop: " >> /etc/init.d/startstunnel
  echo "# Default-Start: 2 3 4 5" >> /etc/init.d/startstunnel
  echo "# Default-Stop:" >> /etc/init.d/startstunnel
  echo "# Short-Description: run stunnel" >> /etc/init.d/startstunnel
  echo "### END INIT INFO" >> /etc/init.d/startstunnel
  echo "sudo /usr/bin/stunnel /etc/stunnel/stunnel.conf" >> /etc/init.d/startstunnel

  chmod 777 /etc/init.d/startstunnel

  #autostart on boot of stunnel
  update-rc.d -f startstunnel defaults 1000 

else
    echo "skiping stunnel depends on user choose";
fi


#install java and tomcat

echo "========================= java ================================="

echo ""
echo "?????????????????????????????????????"
read -p "Choose java version (8 by default - ENTER: " JAVAVER

if [ -z "$JAVAVER" ]; then
	export JAVAVER="8"
fi

sudo apt-get install -y openjdk-$JAVAVER-jdk




echo "============================= tomcat =========================="

groupadd tomcat
useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
cd /tmp

echo ""
echo "?????????????????????????????????????"
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

echo ""
echo "?????????????????????????????????????"
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

echo "============================= tomcat settings =========================="
echo "?????????????????????????????????????"
read -p "Enter tomcat admin name: " TOMCATADMIN
read -p "Enter tomcat admin password ((you may always change it into /opt/tomcat/conf/tomcat-users.xml file): " TOMCATPASS


rm /opt/tomcat/conf/tomcat-users.xml
touch /opt/tomcat/conf/tomcat-users.xml
chmod 666 /opt/tomcat/conf/tomcat-users.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/tomcat-users.xml
echo "<tomcat-users xmlns=\"http://tomcat.apache.org/xml\"" >> /opt/tomcat/conf/tomcat-users.xml
echo "xmln:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" >> /opt/tomcat/conf/tomcat-users.xml
echo "xsi:schemaLocation=\"http://tomcat.apache.org/xml tomcat-users.xsd\"" >> /opt/tomcat/conf/tomcat-users.xml
echo "version=\"1.0\">" >> /opt/tomcat/conf/tomcat-users.xml
echo "<user username=\""${TOMCATADMIN}"\" password=\""${TOMCATPASS}"\" roles=\"admin,admin-gui,manager,manager-gui,script,script-gui\"/>" >> /opt/tomcat/conf/tomcat-users.xml
echo "</tomcat-users>" >> /opt/tomcat/conf/tomcat-users.xml

iptables -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
#iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

echo ""
echo "?????????????????????????????????????"
read -p "Do you need to load certificate for enabling SSL(yes, other?): " ENABLESSL
if [[ "$ENABLESSL" == "yes" ]]; then
  read -p "What is your internet domain name for platform (f.e. bg.yourbank.com): " DOMNAME

  echo "============================= writing ports ====================="

  iptables -A INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
  iptables -A INPUT -i eth0 -p tcp --dport 8443 -j ACCEPT
#  iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 8443
  iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443

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
  


  echo "writing server.conf with SSL"
  rm /opt/tomcat/conf/server.xml
  touch /opt/tomcat/conf/server.xml
  chmod 666 /opt/tomcat/conf/server.xml
  #echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/server.xml
  #echo "<Server port=\"8005\" shutdown=\"SHUTDOWN\">" >> /opt/tomcat/conf/server.xml
  #echo "<Listener className=\"org.apache.catalina.startup.VersionLoggerListener\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Listener className=\"org.apache.catalina.core.AprLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Listener className=\"org.apache.catalina.mbeans.GlobalResourcesLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Listener className=\"org.apache.catalina.core.ThreadLocalLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
  #echo "<GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
  #echo "<Resource name=\"UserDatabase\" auth=\"Container\" type=\"org.apache.catalina.UserDatabase\" description=\"User database that can be updated and saved\" factory=\"org.apache.catalina.users.MemoryUserDatabaseFactory\" pathname=\"conf/tomcat-users.xml\" />" >> /opt/tomcat/conf/server.xml
  #echo "</GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
  #echo "<Service name=\"Catalina\">" >> /opt/tomcat/conf/server.xml
  #echo "<Connector port=\"8080\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Connector port=\"8443\" maxHttpHeaderSize=\"8192\" maxThreads=\"500\" enableLookups=\"false\" disableUploadTimeout=\"true\" acceptCount=\"500\" scheme=\"https\" secure=\"true\" SSLEnabled=\"true\" SSLCetificateFile=\"/opt/tomcat/conf/cert/certificate.crt\" SSLCertificateKeyFile=\"/opt/tomcat/conf/cert/private.key\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Connector port=\"8009\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Engine name=\"Catalina\" defaultHost=\"localhost\">" >> /opt/tomcat/conf/server.xml
  #echo "<Realm className=\"org.apache.catalina.realm.LockOutRealm\">" >> /opt/tomcat/conf/server.xml
  #echo "<Realm className=\"org.apache.catalina.realm.UserDatabaseRealm\" resourceName=\"UserDatabase\" />" >> /opt/tomcat/conf/server.xml
  #echo "</Realm>" >> /opt/tomcat/conf/server.xml
  #echo "<Host name=\"localhost\" appBase=\"webapps\" unpackWARs=\"true\" autoDeploy=\"true\" >" >> /opt/tomcat/conf/server.xml
  #echo "<Valve className=\"org.apache.catalina.valves.AccessLogValue\" directory=\"logs\" prefix=\"localhost_access_log\" suffix=\".txt\" pattern=\"%h %l %u %t &quot;%r&quot; %s %b\" />" >> /opt/tomcat/conf/server.xml
  #echo "</Host>" >> /opt/tomcat/conf/server.xml
  #echo "</Engine>" >> /opt/tomcat/conf/server.xml
  #echo "</Service>" >> /opt/tomcat/conf/server.xml
  #echo "</Server>" >> /opt/tomcat/conf/server.xml



echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/server.xml
echo "<!--" >> /opt/tomcat/conf/server.xml
echo "  Licensed to the Apache Software Foundation (ASF) under one or more" >> /opt/tomcat/conf/server.xml
echo "  contributor license agreements.  See the NOTICE file distributed with" >> /opt/tomcat/conf/server.xml
echo "  this work for additional information regarding copyright ownership." >> /opt/tomcat/conf/server.xml
echo "  The ASF licenses this file to You under the Apache License, Version 2.0" >> /opt/tomcat/conf/server.xml
echo "  (the "License"); you may not use this file except in compliance with" >> /opt/tomcat/conf/server.xml
echo "  the License.  You may obtain a copy of the License at" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "      http://www.apache.org/licenses/LICENSE-2.0" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "  Unless required by applicable law or agreed to in writing, software" >> /opt/tomcat/conf/server.xml
echo "  distributed under the License is distributed on an \"AS IS\" BASIS," >> /opt/tomcat/conf/server.xml
echo "  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied." >> /opt/tomcat/conf/server.xml
echo "  See the License for the specific language governing permissions and" >> /opt/tomcat/conf/server.xml
echo "  limitations under the License." >> /opt/tomcat/conf/server.xml
echo "-->" >> /opt/tomcat/conf/server.xml
echo "<!-- Note:  A \"Server\" is not itself a \"Container\", so you may not" >> /opt/tomcat/conf/server.xml
echo "     define subcomponents such as \"Valves\" at this level." >> /opt/tomcat/conf/server.xml
echo "     Documentation at /docs/config/server.html" >> /opt/tomcat/conf/server.xml
echo " -->" >> /opt/tomcat/conf/server.xml
echo "<Server port=\"8005\" shutdown=\"SHUTDOWN\">" >> /opt/tomcat/conf/server.xml
echo "  <Listener className=\"org.apache.catalina.startup.VersionLoggerListener\" />" >> /opt/tomcat/conf/server.xml
echo "  <!-- Security listener. Documentation at /docs/config/listeners.html" >> /opt/tomcat/conf/server.xml
echo "  <Listener className=\"org.apache.catalina.security.SecurityListener\" />" >> /opt/tomcat/conf/server.xml
echo "  -->" >> /opt/tomcat/conf/server.xml
echo "  <!--APR library loader. Documentation at /docs/apr.html -->" >> /opt/tomcat/conf/server.xml
echo "  <Listener className=\"org.apache.catalina.core.AprLifecycleListener\" SSLEngine=\"on\" />" >> /opt/tomcat/conf/server.xml
echo "  <!-- Prevent memory leaks due to use of particular java/javax APIs-->" >> /opt/tomcat/conf/server.xml
echo "  <Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
echo "  <Listener className=\"org.apache.catalina.mbeans.GlobalResourcesLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
echo "  <Listener className=\"org.apache.catalina.core.ThreadLocalLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "  <!-- Global JNDI resources" >> /opt/tomcat/conf/server.xml
echo "       Documentation at /docs/jndi-resources-howto.html" >> /opt/tomcat/conf/server.xml
echo "  -->" >> /opt/tomcat/conf/server.xml
echo "  <GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
echo "    <!-- Editable user database that can also be used by" >> /opt/tomcat/conf/server.xml
echo "         UserDatabaseRealm to authenticate users" >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "    <Resource name=\"UserDatabase\" auth=\"Container\"" >> /opt/tomcat/conf/server.xml
echo "              type=\"org.apache.catalina.UserDatabase\"" >> /opt/tomcat/conf/server.xml
echo "              description=\"User database that can be updated and saved\"" >> /opt/tomcat/conf/server.xml
echo "              factory=\"org.apache.catalina.users.MemoryUserDatabaseFactory\"" >> /opt/tomcat/conf/server.xml
echo "              pathname=\"conf/tomcat-users.xml\" />" >> /opt/tomcat/conf/server.xml
echo "  </GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "  <!-- A \"Service\" is a collection of one or more \"Connectors\" that share" >> /opt/tomcat/conf/server.xml
echo "       a single \"Container\" Note:  A \"Service\" is not itself a \"Container\"," >> /opt/tomcat/conf/server.xml
echo "       so you may not define subcomponents such as \"Valves\" at this level." >> /opt/tomcat/conf/server.xml
echo "       Documentation at /docs/config/service.html" >> /opt/tomcat/conf/server.xml
echo "   -->" >> /opt/tomcat/conf/server.xml
echo "  <Service name=\"Catalina\">" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "    <!--The connectors can use a shared executor, you can define one or more named thread pools-->" >> /opt/tomcat/conf/server.xml
echo "    <!--" >> /opt/tomcat/conf/server.xml
echo "    <Executor name=\"tomcatThreadPool\" namePrefix=\"catalina-exec-\"" >> /opt/tomcat/conf/server.xml
echo "        maxThreads=\"150\" minSpareThreads=\"4\"/>" >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "    <!-- A \"Connector\" represents an endpoint by which requests are received" >> /opt/tomcat/conf/server.xml
echo "         and responses are returned. Documentation at :" >> /opt/tomcat/conf/server.xml
echo "         Java HTTP Connector: /docs/config/http.html" >> /opt/tomcat/conf/server.xml
echo "         Java AJP  Connector: /docs/config/ajp.html" >> /opt/tomcat/conf/server.xml
echo "         APR (HTTP/AJP) Connector: /docs/apr.html" >> /opt/tomcat/conf/server.xml
echo "         Define a non-SSL/TLS HTTP/1.1 Connector on port 8080" >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "    <Connector port=\"8080\" protocol=\"HTTP/1.1\"" >> /opt/tomcat/conf/server.xml
echo "               connectionTimeout=\"20000\"" >> /opt/tomcat/conf/server.xml
echo "               redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
echo "    <!-- A \"Connector\" using the shared thread pool-->" >> /opt/tomcat/conf/server.xml
echo "    <!--" >> /opt/tomcat/conf/server.xml
echo "    <Connector executor=\"tomcatThreadPool\"" >> /opt/tomcat/conf/server.xml
echo "               port=\"8080\" protocol=\"HTTP/1.1\"" >> /opt/tomcat/conf/server.xml
echo "               connectionTimeout=\"20000\"" >> /opt/tomcat/conf/server.xml
echo "               redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "    <!-- Define a SSL/TLS HTTP/1.1 Connector on port 8443" >> /opt/tomcat/conf/server.xml
echo "         This connector uses the NIO implementation. The default" >> /opt/tomcat/conf/server.xml
echo "         SSLImplementation will depend on the presence of the APR/native" >> /opt/tomcat/conf/server.xml
echo "         library and the useOpenSSL attribute of the" >> /opt/tomcat/conf/server.xml
echo "         AprLifecycleListener." >> /opt/tomcat/conf/server.xml
echo "         Either JSSE or OpenSSL style configuration may be used regardless of" >> /opt/tomcat/conf/server.xml
echo "         the SSLImplementation selected. JSSE style configuration is used below." >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "    <!--" >> /opt/tomcat/conf/server.xml
echo "    <Connector port=\"8443\" protocol=\"org.apache.coyote.http11.Http11NioProtocol\"" >> /opt/tomcat/conf/server.xml
echo "               maxThreads=\"150\" SSLEnabled=\"true\">" >> /opt/tomcat/conf/server.xml
echo "        <SSLHostConfig>" >> /opt/tomcat/conf/server.xml
echo "            <Certificate certificateKeystoreFile=\"conf/localhost-rsa.jks\"" >> /opt/tomcat/conf/server.xml
echo "                         type=\"RSA\" />" >> /opt/tomcat/conf/server.xml
echo "        </SSLHostConfig>" >> /opt/tomcat/conf/server.xml
echo "    </Connector>" >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "    <!-- Define a SSL/TLS HTTP/1.1 Connector on port 8443 with HTTP/2" >> /opt/tomcat/conf/server.xml
echo "         This connector uses the APR/native implementation which always uses" >> /opt/tomcat/conf/server.xml
echo "         OpenSSL for TLS." >> /opt/tomcat/conf/server.xml
echo "         Either JSSE or OpenSSL style configuration may be used. OpenSSL style" >> /opt/tomcat/conf/server.xml
echo "         configuration is used below." >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "    <Connector " >> /opt/tomcat/conf/server.xml
echo "         port=\"8443\"" >> /opt/tomcat/conf/server.xml
echo "         maxHttpHeaderSize=\"8192\"" >> /opt/tomcat/conf/server.xml
echo "         maxThreads=\"200\"" >> /opt/tomcat/conf/server.xml
echo "         enableLookups=\"false\"" >> /opt/tomcat/conf/server.xml
echo "         disableUploadTimeout=\"true\"" >> /opt/tomcat/conf/server.xml
echo "         acceptCount=\"200\"" >> /opt/tomcat/conf/server.xml
echo "         scheme=\"https\"" >> /opt/tomcat/conf/server.xml
echo "         secure=\"true\"" >> /opt/tomcat/conf/server.xml
echo "         SSLEnabled=\"true\"" >> /opt/tomcat/conf/server.xml
echo "         SSLCertificateFile=\"/opt/tomcat/conf/cert/cert.pem\"" >> /opt/tomcat/conf/server.xml
echo "         SSLCertificateKeyFile=\"/opt/tomcat/conf/cert/privkey.pem\"" >> /opt/tomcat/conf/server.xml
echo "     />" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo " " >> /opt/tomcat/conf/server.xml
echo "  "   >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "    <!-- Define an AJP 1.3 Connector on port 8009 -->" >> /opt/tomcat/conf/server.xml
echo "    <Connector port=\"8009\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "    <!-- An Engine represents the entry point (within Catalina) that processes" >> /opt/tomcat/conf/server.xml
echo "         every request.  The Engine implementation for Tomcat stand alone" >> /opt/tomcat/conf/server.xml
echo "         analyzes the HTTP headers included with the request, and passes them" >> /opt/tomcat/conf/server.xml
echo "         on to the appropriate Host (virtual host)." >> /opt/tomcat/conf/server.xml
echo "         Documentation at /docs/config/engine.html -->" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "    <!-- You should set jvmRoute to support load-balancing via AJP ie :" >> /opt/tomcat/conf/server.xml
echo "    <Engine name=\"Catalina\" defaultHost=\"localhost\" jvmRoute=\"jvm1\">" >> /opt/tomcat/conf/server.xml
echo "    -->" >> /opt/tomcat/conf/server.xml
echo "    <Engine name=\"Catalina\" defaultHost=\"localhost\">" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "      <!--For clustering, please take a look at documentation at:" >> /opt/tomcat/conf/server.xml
echo "          /docs/cluster-howto.html  (simple how to)" >> /opt/tomcat/conf/server.xml
echo "          /docs/config/cluster.html (reference documentation) -->" >> /opt/tomcat/conf/server.xml
echo "      <!--" >> /opt/tomcat/conf/server.xml
echo "      <Cluster className=\"org.apache.catalina.ha.tcp.SimpleTcpCluster\"/>" >> /opt/tomcat/conf/server.xml
echo "      -->" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "      <!-- Use the LockOutRealm to prevent attempts to guess user passwords" >> /opt/tomcat/conf/server.xml
echo "           via a brute-force attack -->" >> /opt/tomcat/conf/server.xml
echo "      <Realm className=\"org.apache.catalina.realm.LockOutRealm\">" >> /opt/tomcat/conf/server.xml
echo "        <!-- This Realm uses the UserDatabase configured in the global JNDI" >> /opt/tomcat/conf/server.xml
echo "             resources under the key \"UserDatabase\".  Any edits" >> /opt/tomcat/conf/server.xml
echo "             that are performed against this UserDatabase are immediately" >> /opt/tomcat/conf/server.xml
echo "             available for use by the Realm.  -->" >> /opt/tomcat/conf/server.xml
echo "        <Realm className=\"org.apache.catalina.realm.UserDatabaseRealm\"" >> /opt/tomcat/conf/server.xml
echo "               resourceName=\"UserDatabase\"/>" >> /opt/tomcat/conf/server.xml
echo "      </Realm>" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "      <Host name=\"localhost\"  appBase=\"webapps\"" >> /opt/tomcat/conf/server.xml
echo "            unpackWARs=\"true\" autoDeploy=\"true\">" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "        <!-- SingleSignOn valve, share authentication between web applications" >> /opt/tomcat/conf/server.xml
echo "             Documentation at: /docs/config/valve.html -->" >> /opt/tomcat/conf/server.xml
echo "        <!--" >> /opt/tomcat/conf/server.xml
echo "        <Valve className=\"org.apache.catalina.authenticator.SingleSignOn\" />" >> /opt/tomcat/conf/server.xml
echo "        -->" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "        <!-- Access log processes all example." >> /opt/tomcat/conf/server.xml
echo "             Documentation at: /docs/config/valve.html" >> /opt/tomcat/conf/server.xml
echo "             Note: The pattern used is equivalent to using pattern=\"common\" -->" >> /opt/tomcat/conf/server.xml
echo "        <Valve className=\"org.apache.catalina.valves.AccessLogValve\" directory=\"logs\"" >> /opt/tomcat/conf/server.xml
echo "               prefix=\"localhost_access_log\" suffix=\".txt\"" >> /opt/tomcat/conf/server.xml
echo "               pattern=\"%h %l %u %t &quot;%r&quot; %s %b\" />" >> /opt/tomcat/conf/server.xml
echo "" >> /opt/tomcat/conf/server.xml
echo "      </Host>" >> /opt/tomcat/conf/server.xml
echo "    </Engine>" >> /opt/tomcat/conf/server.xml
echo "  </Service>" >> /opt/tomcat/conf/server.xml
echo "</Server>" >> /opt/tomcat/conf/server.xml



  systemctl stop tomcat
else
  echo "writing server.conf without SSL"
  rm /opt/tomcat/conf/server.xml
  touch /opt/tomcat/conf/server.xml
  chmod 666 /opt/tomcat/conf/server.xml
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/conf/server.xml
  echo "<Server port=\"8005\" shutdown=\"SHUTDOWN\">" >> /opt/tomcat/conf/server.xml
  echo "<Listener className=\"org.apache.catalina.startup.VersionLoggerListener\" />" >> /opt/tomcat/conf/server.xml
  echo "<Listener className=\"org.apache.catalina.core.AprLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
  echo "<Listener className=\"org.apache.catalina.core.JreMemoryLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
  echo "<Listener className=\"org.apache.catalina.mbeans.GlobalResourcesLifecycleListener\" />" >> /opt/tomcat/conf/server.xml
  echo "<Listener className=\"org.apache.catalina.core.ThreadLocalLeakPreventionListener\" />" >> /opt/tomcat/conf/server.xml
  echo "<GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
  echo "<Resource name=\"UserDatabase\" auth=\"Container\" type=\"org.apache.catalina.UserDatabase\" description=\"User database that can be updated and saved\" factory=\"org.apache.catalina.users.MemoryUserDatabaseFactory\" pathname=\"conf/tomcat-users.xml\" />" >> /opt/tomcat/conf/server.xml
  echo "</GlobalNamingResources>" >> /opt/tomcat/conf/server.xml
  echo "<Service name=\"Catalina\">" >> /opt/tomcat/conf/server.xml
  echo "<Connector port=\"8080\" protocol=\"HTTP/1.1\" connectionTimeout=\"20000\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
  #echo "<Connector port=\"8443\" maxHttpHeaderSize=\"8192\" maxThreads=\"500\" enableLookups=\"false\" disableUploadTimeout=\"true\" acceptCount=\"500\" scheme=\"https\" secure=\"true\" SSLEnabled=\"true\" SSLCetificateFile=\"/opt/tomcat/conf/cert/certificate.crt\" SSLCertificateKeyFile=\"/opt/tomcat/conf/cert/private.key\" />" >> /opt/tomcat/conf/server.xml
  echo "<Connector port=\"8009\" protocol=\"AJP/1.3\" redirectPort=\"8443\" />" >> /opt/tomcat/conf/server.xml
  echo "<Engine name=\"Catalina\" defaultHost=\"localhost\">" >> /opt/tomcat/conf/server.xml
  echo "<Realm className=\"org.apache.catalina.realm.LockOutRealm\">" >> /opt/tomcat/conf/server.xml
  echo "<Realm className=\"org.apache.catalina.realm.UserDatabaseRealm\" resourceName=\"UserDatabase\" />" >> /opt/tomcat/conf/server.xml
  echo "</Realm>" >> /opt/tomcat/conf/server.xml
  echo "<Host name=\"localhost\" appBase=\"webapps\" unpackWARs=\"true\" autoDeploy=\"true\" >" >> /opt/tomcat/conf/server.xml
  echo "<Valve className=\"org.apache.catalina.valves.AccessLogValue\" directory=\"logs\" prefix=\"localhost_access_log\" suffix=\".txt\" pattern=\"%h %l %u %t &quot;%r&quot; %s %b\" />" >> /opt/tomcat/conf/server.xml
  echo "</Host>" >> /opt/tomcat/conf/server.xml
  echo "</Engine>" >> /opt/tomcat/conf/server.xml
  echo "</Service>" >> /opt/tomcat/conf/server.xml
  echo "</Server>" >> /opt/tomcat/conf/server.xml
fi


echo "================== saving port forwarding settings ============================"
sudo apt-get install iptables-persistent

echo "===================final starting tomcat =================="
systemctl daemon-reload
systemctl start tomcat
#systemctl status tomcat
sudo systemctl enable tomcat

# download and install git
# git clone of source files
# maven install
# maven build

# ant install for dispatcher
# ant build dispatcher...


#install postgresql
echo""
read -p "Do you need to install Database server here (yes, other?): " INSTALLDB
if [[ "$INSTALLDB" == "yes" ]]; then
  sudo apt-get install postgresql postgresql-contrib

  #psql alter user postgres set password
  #psql create db
  #download sql-s
  #psql sql-s


else
  echo "skiping install db depends on user choose"
fi
