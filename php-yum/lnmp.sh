#!/bin/bash -l

########################################
# LNMP环境搭建yum方式 centos7
# 作者：ellen
# 版本：v1
########################################
# install LNMP use yum

# 关闭防火墙
systemctl stop firewalld
setenforce 0

# install epel
yum -y install epel-release

# install libiconv
rpm -ivh https://forensics.cert.org/cert-forensics-tools-release-el7.rpm
# mysql
rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm

# install nginx mysql php redis
# mysql mysql-devel mysql-server is for centos6
yum install -y gcc gcc-c++ bison pcre-devel ncurses-devel autoconf automake nginx mysql-community-server redis libxml2 libxml2-devel libjpeg libjpeg-devel freetype freetype-devel libpng libpng-devel gd gd-devel curl curl-devel libiconv libiconv-devel zlib-devel openssl-devel php php-cli php-common php-devel php-bcmath php-fpm php-gd php-mysql php-pdo php-ldap php-mbstring php-mcrypt php-pecl-redis php-xcache php-xml php-xmlrpc php-pear


# 启动mysql，查看密码
#systemctl start mysqld
#cat /var/log/mysqld.log | grep password
# 使用
#mysql -uroot -p

# 我只是想设置一个简单的密码做测试
#mysql> set global validate_password_policy=0;
#mysql> set global validate_password_length=6;
#mysql> set password for 'root'@'localhost'=password('123456'); 


