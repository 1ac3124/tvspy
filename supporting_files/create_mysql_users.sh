#!/bin/bash

/usr/bin/mysqld_safe > /dev/null 2>&1 &

RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

PASS="tvspy"
_word="tvspy"
echo "=> Creating MySQL tvspy user with ${_word} password and database"

mysql -uroot -e "CREATE USER 'tvspy'@'%' IDENTIFIED BY '$PASS'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'tvspy'@'%' WITH GRANT OPTION"
#mysql -uroot -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO  'pma'@'localhost' IDENTIFIED BY ''"
mysql -uroot < /var/www/html/bd/bd_inicial.sql
mysql -uroot -e "GRANT ALL PRIVILEGES ON tvspy.* TO 'tvspy'@'%' IDENTIFIED BY 'tvspy'"

file=/var/www/html/bd_backup/backup.sql
if [ -e "$file" ]; then
	mysql -uroot tvspy < $file
	echo "Backup importado"
fi 

CREATE_MYSQL_USER=false

if [ -n "$CREATE_MYSQL_BASIC_USER_AND_DB" ] || \
   [ -n "$MYSQL_USER_NAME" ] || \
   [ -n "$MYSQL_USER_DB" ] || \
   [ -n "$MYSQL_USER_PASS" ]; then
      CREATE_MYSQL_USER=true
fi

if [ "$CREATE_MYSQL_USER" = true ]; then
    _user=${MYSQL_USER_NAME:-user}
    _userdb=${MYSQL_USER_DB:-db}
    _userpass=${MYSQL_USER_PASS:-password}

    mysql -uroot -e "CREATE USER '${_user}'@'%' IDENTIFIED BY  '${_userpass}'"
    mysql -uroot -e "GRANT USAGE ON *.* TO  '${_user}'@'%' IDENTIFIED BY '${_userpass}'"
    mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${_userdb}"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON ${_userdb}.* TO '${_user}'@'%'"
fi

echo "=> Done!"

echo "========================================================================"
echo "You can now connect to this MySQL Server with $PASS"
echo ""
echo "    mysql -uadmin -p$PASS -h<host> -P<port>"
echo ""
echo "MySQL user 'root' has no password but only allows local connections"
echo ""

if [ "$CREATE_MYSQL_USER" = true ]; then
    echo "We also created"
    echo "A database called '${_userdb}' and"
    echo "a user called '${_user}' with password '${_userpass}'"
    echo "'${_user}' has full access on '${_userdb}'"
fi

echo "enjoy!"
echo "========================================================================"

mysqladmin -uroot shutdown
