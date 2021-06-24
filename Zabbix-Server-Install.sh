
# Instalando os repositórios atuais:
apt update
apt-get install sudo -y 

set -e

#==========================================configurando repositorio de mysql==============================================
wget https://dev.mysql.com/get/mysql-apt-config_0.8.16-1_all.deb 
apt -y install ./mysql-apt-config_0.8.16-1_all.deb

#==========================================configurando repositorio do zabbix==============================================
wget https://repo.zabbix.com/zabbix/5.0/debian/pool/main/z/zabbix-release/zabbix-release_5.0-1+buster_all.deb
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent

apt update

# Versão 8.0 do MySQL
MYSQL_VERSION=8.0
MYSQL_PASSWD=suportekggg # ALTERE ESSA SENHA!!
ZABBIX_PASSWD=suportekggg #!!
[ -z "${MYSQL_PASSWD}" ] && MYSQL_PASSWD=mysql
[ -z "${ZABBIX_PASSWD}" ] && ZABBIX_PASSWD=zabbix

# Bloco de instalação do Zabbix 4.0 com MySQL 8.x
zabbix_server_install()
{

   apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
       
    systemctl reload apache2
       
    apt -y install mysql-server

  cat <<EOF | mysql -uroot -p${MYSQL_PASSWD}
create database zabbix character set utf8 collate utf8_bin;
create user 'zabbix'@'localhost' identified by '${ZABBIX_PASSWD}';
create user 'zabbix'@'%' identified by '${ZABBIX_PASSWD}';
GRANT ALL ON zabbix.* to 'zabbix'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'zabbix'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'zabbix'@'%' WITH GRANT OPTION;
ALTER USER 'zabbix'@'localhost' IDENTIFIED WITH mysql_native_password BY '${ZABBIX_PASSWD}';
ALTER USER 'zabbix'@'%' IDENTIFIED WITH mysql_native_password BY '${ZABBIX_PASSWD}';
flush privileges;
exit
EOF

  zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | mysql -uzabbix -p${MYSQL_PASSWD} zabbix;
  
  sed -e "s/# DBPassword=.*/DBPassword=${ZABBIX_PASSWD}/g" \
       -i /etc/zabbix/zabbix_server.conf

   systemctl enable apache2 zabbix-server
   systemctl restart apache2 zabbix-server
}

zabbix_main()
{
  zabbix_server_install
  
}

zabbix_main
