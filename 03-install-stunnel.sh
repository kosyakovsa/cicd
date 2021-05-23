cd /work/cicd
  echo "=========================== stunnel (secured connector) =========================================="
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