#!/bin/bash
apt-get update && apt-get install build-essential wget -y


apt-get install -y mc
apt-get install -y wget

#Network storage installing on demand
read -p "install network mount packages? (Is your file store located on other server?) (yes, other) " INSTALLCIFS
if [[ "$INSTALLCIFS" == "yes" ]]; then
	./01-install-cifs.sh
else
    echo "skiping cifs depends on user choose"
fi


#OPENSSL installing always because this generates hashes by GOST for documents
read -p "install openssl packages? (Would it will web server or secured tunnel) (yes, other) " INSTALLOPENSSL
if [[ "$INSTALLOPENSSL" == "yes" ]]; then
	./02-install-openssl.sh
else
    echo "skiping openssl depends on user choose"
fi


#stunnel - is tool for allow gost ssl connection (nbki)
if [[ "$INSTALLOPENSSL" == "yes" ]]; then
	read -p "Do you need secured tunnel to others resources (NBKI for example)?: (yes, other)" INSTALLSTUNNEL
	if [[ "$INSTALLSTUNNEL" == "yes" ]]; then
		./03-install-stunnel.sh
	else
		echo "skiping stunnel depends on user choose";
	fi
else
	echo "skiping stunnel because no openssl";
fi


#install java
read -p "Will it server use for web application or some long operations?: (yes, other)" INSTALLJAVA
if [[ "$INSTALLJAVA" == "yes" ]]; then
    read -p "Choose java version (8 by default - ENTER): " JAVAVER
    sudo ./04-install-java.sh $JAVAVER
else
    echo "skiping java depends on user choose"
fi



#install tomcat - container web applications
if [[ "$INSTALLJAVA" == "yes" ]]; then
	read -p "Will it server use for web application?: (yes, other)" INSTALLTOMCAT
	if [[ "$INSTALLTOMCAT" == "yes" ]]; then
		sudo ./05-install-tomcat.sh
	fi
else
  echo "skiping install tomcat because no java"
fi

#install git and sources if install java
#if [[ "$INSTALLJAVA" == "yes" ]]; then
#	sudo apt-get install git
#	sudo apt-get install install-info
#	sudo apt instal maven
#	sudo apt-get install ant
#fi
# download and install git
# git clone of source files
# maven install
# maven build

# ant install for dispatcher
# ant build dispatcher...


#install postgresql
read -p "Do you need to install Database server here (yes, other?): " INSTALLDB
if [[ "$INSTALLDB" == "yes" ]]; then
  sudo apt-get install postgresql-9.6 postgresql-contrib-9.6

#$ sudo -u postgres psql

  #psql ALTER USER postgres PASSWORD 'myPassword';
  #psql create db
  #download sql-s
  #psql sql-s

#https://evileg.com/en/post/2/

else
  echo "skiping install db depends on user choose"
fi
