#!/bin/bash
# 
# @author Yuri Timofeev <tim4dev@gmail.com>
# @package webacula
# @license http://www.gnu.org/licenses/gpl-3.0.html GNU Public License 
#

BACULADIR="etc/bacula"
TMPDIR="/tmp/webacula"
BASEDIR=`pwd`
INSTALL_DIR="../../install/"
LINE1="*********************************************************************************************"

if [ "$UID" -ne 0 ]
then
        echo -e "\nYou must be root to run this test.\nExit.\n"
        exit
fi

#echo -e "\n\n*** WARNING!!! Postgresql, Sqlite  Bacula database will be dropped!!!\n"
#echo -e "\n*** Press Enter to continue ...\n\n"
# read


#########################################################
# Function
#
my_log() {
   echo -e "\n\n${LINE1}"
   echo "${1}"
   echo -e "${LINE1}\n\n"
}







#########################################################
# Main program
#########################################################


/usr/bin/psql -l
if test $? -ne 0; then
  echo "Can't connect to postgresql."
  /sbin/service postgresql start
fi

/usr/bin/mysqlshow mysql
if test $? -ne 0; then
	echo "Can't connect to mysqld."
	/sbin/service mysqld start
fi

echo -e "\n\n"

rm -r -f /tmp/webacula/sqlite/bacula.db
echo "Drop Sqlite bacula database succeeded."

if dropdb bacula
then
   echo "Drop PGSQL bacula database succeeded."
else
   echo "Drop PGSQL bacula database failed."
fi


createdb -T template0 -E SQL_ASCII bacula
if test $? -ne 0; then
   echo "PGSQL : Creation of bacula database failed."
   exit 2
fi

if psql -q -f - -d bacula <<END-OF-DATA
ALTER DATABASE bacula SET datestyle TO 'ISO, YMD';
END-OF-DATA
then
   echo "Creation of bacula database succeeded."
else
   echo "Creation of bacula database failed."
   exit 2
fi

cd ${BASEDIR}
sh ./PostgreSql/10_bacula_make_tables
sh ./PostgreSql/20_bacula_grant_privileges
cd ${INSTALL_DIR}/PostgreSql
sh ./10_make_tables.sh
cd ${BASEDIR}
sh ./PostgreSql/30_webacula_fill_logbook
sh ./PostgreSql/40_webacula_fill_acl

##-- sh ./bacula_sqlite_make_tables

my_log "Copy DB from MySQL to PGSQL ..."
cd ${BASEDIR}
php ./bacula_DBcopy_MySQL2PGSQL.php

##-- my_log "Copy DB from MySQL to Sqlite ..."
##-- cd ${BASEDIR}
##-- php ./bacula_DBcopy_MySQL2sqlite.php

##-- chmod -R a+rwx /tmp/webacula/sqlite
