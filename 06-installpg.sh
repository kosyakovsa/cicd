#cd /work/cicd
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install postgresql-9.6 postgresql-contrib-9.6

#set pgpassword and apply russian coding
#export PGPASSWORD="K33u2%t"

OUTPUT="`hostname -I`"
echo "${OUTPUT}"

rm $PWD/basesettings.sql
rm $PWD/defaultdb.backup

#read -p "what address(site or ip) of sprint (settings)" SITEADDRESS
touch $PWD/basesettings.sql
echo "UPDATE settings.sys_settings set syssetvalue = trim('http://${OUTPUT}') WHERE syssetname like 'mainUrl%';" >> $PWD/basesettings.sql
echo "INSERT INTO settings.sys_settings (syssetname, syssetvalue) VALUES('signUrlBank', 'banksign');" >> $PWD/basesettings.sql
echo "INSERT INTO users_product (user_id, product_id) values(1, 1);"
#echo "${OUTPUT}" >> $PWD/basesettings.sql
#echo /b >> $PWD/basesettings.sql
#echo >> $PWD/basesettings.sql

wget --no-check-certificate http://demo.premierb.ru/sign/defaultdb.backup
echo "SET DEFAULT PASSWORD FOR USER POSTGRES"

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'K33u2%t';"
echo "Enter the password for postgres user of DB for init SQL"

sudo -u postgres psql -h localhost -U postgres -p 5432 -a -f $PWD/pginit.sql
echo "Enter the password for postgres user of DB for restore db from file"

/usr/bin/pg_restore $PWD/defaultdb.backup -d bg -U postgres -h localhost -p 5432

echo "Enter the password for postgres user of DB for init some environment settings"

psql -h localhost -U postgres -p 5432 -d bg -a -f $PWD/basesettings.sql
rm $PWD/basesettings.sql
rm $PWD/defaultdb.backup





#$ sudo -u postgres psql

  #psql create db
  #download sql-s
  #psql sql-s

#https://evileg.com/en/post/2/
