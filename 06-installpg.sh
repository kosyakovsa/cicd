cd /work/cicd
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install postgresql-9.6 postgresql-contrib-9.6

#set pgpassword and apply russian coding
export PGPASSWORD=K33u2$%t
psql -h localhost -U postgres -p 5432 -a -w -f ./pginit.sql
wget --no-check-certificate http://demo.premierb.ru/sign/defaultdb.backup
/usr/bin/pg_restore /work/cicd/defaultdb.backup -d bg -U postgres -h localhost -p 5432

#$ sudo -u postgres psql

  #psql create db
  #download sql-s
  #psql sql-s

#https://evileg.com/en/post/2/
