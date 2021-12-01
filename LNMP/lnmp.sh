#!/bin/bash -l

########################################
# LNMP环境搭建 centos7 centos6
# 作者：ellen
# 版本：v1
########################################

yum install -y epel-release

yum install -y gcc gcc-c++ bison ncurses-devel libxml libjpeg libjpeg-devel freetype freetype-devel libpng libpng-devel gd curl libiconv zlib-devel libxml2-devel gd-devel curl-devel pcre pcre-devel libaio libaio-devel autoconf openssl-devel wget vim lbzip2 re2c libmcrypt libmcrypt-devel patch


# close the iptable and selinux
/etc/init.d/iptables stop
setenforce 0


user="nginx"



# nginx install
function nginx_install()
{
    # 默认使用nginx用户
    useradd nginx -s /sbin/nologin -M

    NGINX_VERSION=$1
    OPENSSL_VERSION=$2
    USER=$3


    cd /usr/local/src
    # download package
    # nginx
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz

    if [ "$?" = "0" ];then
        echo "nginx download        OK"
    else
        echo "nginx download     FAILD"
    fi


    # openssl
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz

    if [ "$?" = "0" ];then
        echo "openssl download        OK"
    else
        echo "openssl download     FAILD"
    fi

    #
    tar xf /usr/local/src/nginx-${NGINX_VERSION}.tar.gz
    tar xf /usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz

    echo "nginx configure     START"

    cd /usr/local/src/nginx-${NGINX_VERSION}/
    ./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_realip_module --with-openssl=/usr/local/src/openssl-${OPENSSL_VERSION} --user=${USER} --group=${USER}

    #./configure --prefix=/usr/local/openresty --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_realip_module --with-openssl=/usr/local/src/openssl-1.1.1j --user=nginx --group=nginx

    make && make install

    cd /usr/local/nginx/conf/

    sed -i '72a \        location ~ \.php$ {\n            root           html;\n            fastcgi_pass   127.0.0.1:9000;\n            fastcgi_index  index.php;\n            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;\n            include        fastcgi_params;\n        }\n' nginx.conf

    sed -i 's#index  index.html index.htm;#index  index.php index.html index.htm;#g' nginx.conf


    /usr/local/nginx/sbin/nginx -t

    echo "nginx configure     END"
    cd /usr/local/src
}

# 判断nginx目录是否存在 不存在，则初始化数据
if [ ! -d "/usr/local/nginx/" ]; then
    cd /usr/local/src
    nginx_version="1.13.8"
    openssl_version="1.1.0g"
    #user="vagrant"
    #user="nginx"

    nginx_install ${nginx_version} ${openssl_version} ${user}
fi


# 2021-12-01
# mysql 5.7安装脚本 二进制包安装
# https://downloads.mysql.com/archives/community/
function mysql_install57()
{
    cd /usr/local/src/

    MYSQL_DATA_DIR="/usr/local/mysql/data"

    MYSQL_VERSION="mysql-5.7.35-linux-glibc2.12-x86_64"
    # mysql
    
    if [ ! -f /usr/local/src/${MYSQL_VERSION}.tar.gz ]; then
        wget https://cdn.mysql.com/archives/mysql-5.7/${MYSQL_VERSION}.tar.gz

        if [ "$?" = "0" ];then
            echo "mysql download        OK"
        else
            echo "mysql download     FAILD"
            return 0
        fi
    fi

    # add mysql user
    groupadd mysql
    useradd mysql -s /sbin/nologin -g mysql -M

    echo "mysql configure     START"

    tar xf /usr/local/src/${MYSQL_VERSION}.tar.gz
    cp -R /usr/local/src/${MYSQL_VERSION} /usr/local/mysql
    cd /usr/local/mysql/

    chown -R mysql.mysql /usr/local/mysql

    # mysql 5.7 不设置密码
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=${MYSQL_DATA_DIR} --user=mysql

    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld

    echo "[mysqld]" > /etc/my.cnf

    sed -i "s#\[mysqld\]#\[mysqld\]\nbasedir = /usr/local/mysql\ndatadir = ${MYSQL_DATA_DIR}\nport = 3306\nserver_id = 1\nsocket = /tmp/mysql.sock\nlog-bin=mysql-bin\n\nslow-query-log=1\nlong_query_time = 1\nslow-query-log-file=/usr/local/mysql/slow-query.log\n\nsql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES\n\n#g" /etc/my.cnf

    echo "mysql configure     END"

    echo "/usr/local/lib\n/usr/local/mysql/lib" > /etc/ld.so.conf.d/libc.conf
    ldconfig

    cd /usr/local/src/
}




# 由于mysql 版本配置差异大  先使用5.6作为默认mysql
function mysql_install()
{
    cd /usr/local/src/

    MYSQL_VERSION="mysql-5.6.38-linux-glibc2.12-x86_64"
    # mysql
    wget https://cdn.mysql.com//Downloads/MySQL-5.6/${MYSQL_VERSION}.tar.gz

    if [ "$?" = "0" ];then
        echo "mysql download        OK"
    else
        echo "mysql download     FAILD"
    fi

    # add mysql user
    groupadd mysql
    useradd mysql -s /sbin/nologin -g mysql -M


    echo "mysql configure     START"

    tar xf /usr/local/src/${MYSQL_VERSION}.tar.gz
    cp -R /usr/local/src/${MYSQL_VERSION} /usr/local/mysql
    cd /usr/local/mysql/

    chown -R mysql.mysql /usr/local/mysql

    /usr/local/mysql/scripts/mysql_install_db --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql

    # mysql 5.7
    #/usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql

    cp /usr/local/mysql/support-files/my-default.cnf /etc/my.cnf
    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld

    sed -i 's#\[mysqld\]#\[mysqld\]\nbasedir = /usr/local/mysql\ndatadir = /usr/local/mysql/data\nport = 3306\nserver_id = 1\nsocket = /tmp/mysql.sock\nlog-bin=mysql-bin\n\nslow-query-log=1\nlong_query_time = 1\nslow-query-log-file=/usr/local/mysql/slow-query.log\n#g' /etc/my.cnf

    echo "mysql configure     END"

    echo "/usr/local/lib\n/usr/local/mysql/lib" > /etc/ld.so.conf.d/libc.conf
    ldconfig

    cd /usr/local/src/
}

if [ ! -d "/usr/local/mysql/" ]; then
    mysql_install
fi



# php 7.0.26
function php_install7()
{
    PHP_VERSION=$1
    FPM_USER=$2
    FPM_PORT=$3

    cd /usr/local/src/

    # redis
    wget http://download.redis.io/releases/redis-4.0.6.tar.gz

    if [ "$?" = "0" ];then
        echo "redis download        OK"
    else
        echo "redis download     FAILD"
    fi


    # php redis module
    wget http://pecl.php.net/get/redis-3.1.5.tgz

    if [ "$?" = "0" ];then
        echo "php redis module download        OK"
    else
        echo "php redis module download     FAILD"
    fi

    wget http://cn.php.net/distributions/php-${PHP_VERSION}.tar.bz2

    if [ $? != 0 ] ;then
        wget http://museum.php.net/php7/php-${PHP_VERSION}.tar.bz2
    fi

    tar xf /usr/local/src/php-${PHP_VERSION}.tar.bz2
    cd /usr/local/src/php-${PHP_VERSION}/
    ./configure --prefix=/usr/local/php-${PHP_VERSION} --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-freetype-dir --with-gd --with-zlib --with-libxml-dir --with-jpeg-dir --with-png-dir --with-curl --with-mhash --enable-mbstring --enable-xml --enable-shmop --enable-sysvsem --enable-bcmath --enable-fpm --enable-gd-native-ttf --enable-sockets --enable-zip --enable-soap --with-fpm-user=${FPM_USER} --with-fpm-group=${FPM_USER} --enable-ftp --enable-shared --with-openssl --with-mcrypt

    make && make install

    cp php.ini-development /usr/local/php-${PHP_VERSION}/lib/php.ini

    cd /usr/local/php-${PHP_VERSION}/lib/

    sed -i 's#;date.timezone =#date.timezone = PRC#g' php.ini

    cd /usr/local/php-${PHP_VERSION}/etc/
    cp php-fpm.conf.default php-fpm.conf

    cd /usr/local/php-${PHP_VERSION}/etc/php-fpm.d
    cp www.conf.default www.conf

    cp /usr/local/src/php-${PHP_VERSION}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm

    sed -i "s#prefix=/usr/local/php#prefix=/usr/local/php-${PHP_VERSION}#g" /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm


    echo "php7 configure     END"


    echo "redis configure     START"
    cd /usr/local/src/
    tar xf /usr/local/src/redis-4.0.6.tar.gz

    cd redis-4.0.6/
    make MALLOC=libc PREFIX=/usr/local/redis install

    cp redis.conf /usr/local/redis/


    sed -i 's#daemonize no#daemonize yes#g' /usr/local/redis/redis.conf

    echo "redis configure     END"


    echo "php redis module configure     START"
    cd /usr/local/src/
    tar xf /usr/local/src/redis-3.1.5.tgz


    cd /usr/local/src/
    cd redis-3.1.5/
    /usr/local/php-${PHP_VERSION}/bin/phpize
    /usr/local/php-${PHP_VERSION}/bin/phpize
    ./configure --enable-redis --with-php-config=/usr/local/php-${PHP_VERSION}/bin/php-config
    make && make install


    echo -e '<?php\n    phpinfo();\n\n?>' > /usr/local/nginx/html/index.php

    echo -e '\n\n\n[redis]\nextension=redis.so\n\n' >> /usr/local/php-${PHP_VERSION}/lib/php.ini

    echo "php redis module configure     END"
    cd /usr/local/src/

    # the path
    echo "PATH=/usr/local/php-${PHP_VERSION}/bin:/usr/local/mysql/bin:/usr/local/redis/bin:$PATH" > /etc/profile.d/lnmp.sh
    source /etc/profile
}


/usr/local/php-${version}
cd /usr/local/src
version="7.0.26"
#user="vagrant"
#user="nginx"
php_port="0"

if [ ! -d "/usr/local/php-${version}" ]; then
    php_install7 ${version} ${user} ${php_port}
fi



# php 5.6   5.5   5.4   5.3   5.2
function php_install()
{
    PHP_VERSION=$1
    FPM_USER=$2
    FPM_PORT=$3

    cd /usr/local/src

    wget http://cn.php.net/distributions/php-${PHP_VERSION}.tar.bz2

    if [ $? != 0 ] ;then
        wget http://museum.php.net/php5/php-${PHP_VERSION}.tar.bz2
    fi
    tar xf /usr/local/src/php-${PHP_VERSION}.tar.bz2

    cd /usr/local/src/php-${PHP_VERSION}/
    ./configure --prefix=/usr/local/php-${PHP_VERSION} --with-mysql=mysqlnd --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-freetype-dir --with-gd --with-zlib --with-libxml-dir --with-jpeg-dir --with-png-dir --with-curl --with-mhash --enable-mbstring --enable-xml --enable-shmop --enable-sysvsem --enable-bcmath --enable-fpm --enable-gd-native-ttf --enable-sockets --enable-zip --enable-soap --enable-ftp --enable-shared --with-openssl --with-mcrypt --with-fpm-user=${FPM_USER} --with-fpm-group=${FPM_USER}

    make && make install

    cp php.ini-development /usr/local/php-${PHP_VERSION}/lib/php.ini

    cd /usr/local/php-${PHP_VERSION}/lib/

    sed -i 's#;date.timezone =#date.timezone = PRC#g' php.ini

    cd /usr/local/php-${PHP_VERSION}/etc/
    cp php-fpm.conf.default php-fpm.conf
    sed -i "s#listen = 127.0.0.1:9000#listen = 127.0.0.1:900${FPM_PORT}#g" php-fpm.conf
    cd /usr/local/src
}


cd /usr/local/src
version="5.6.32"
#user="vagrant"
#user="nginx"
php_port="6"


if [ ! -d "/usr/local/php-${version}" ]; then
    php_install ${version} ${user} ${php_port}
fi


cd /usr/local/src
version="5.5.38"
#user="vagrant"
user="nginx"
php_port="5"

if [ ! -d "/usr/local/php-${version}" ]; then
    php_install ${version} ${user} ${php_port}
fi



cd /usr/local/src
version="5.4.45"
#user="vagrant"
#user="nginx"
php_port="4"

if [ ! -d "/usr/local/php-${version}" ]; then
    php_install ${version} ${user} ${php_port}
fi



cd /usr/local/src
version="5.3.29"
#user="vagrant"
#user="nginx"
php_port="3"

if [ ! -d "/usr/local/php-${version}" ]; then
    php_install ${version} ${user} ${php_port}
fi




# 由于5.2没有fpm 需要打补丁
function php_install52()
{
    PHP_VERSION=$1
    FPM_USER=$2
    FPM_PORT=$3

    ln -s /usr/lib64/libjpeg.so /usr/lib/libjpeg.so
    ln -s /usr/lib64/libpng.so /usr/lib/libpng.so

    cd /usr/local/src

    wget http://cn.php.net/distributions/php-${PHP_VERSION}.tar.bz2

    if [ $? != 0 ] ;then
        wget http://museum.php.net/php5/php-${PHP_VERSION}.tar.bz2
    fi

    wget https://php-fpm.org/downloads/php-5.2.17-fpm-0.5.14.diff.gz

    tar xf /usr/local/src/php-${PHP_VERSION}.tar.bz2

    gzip -cd /usr/local/src/php-5.2.17-fpm-0.5.14.diff.gz | sudo patch -d php-${PHP_VERSION} -p1

    cd /usr/local/src/php-${PHP_VERSION}/
    ./configure --prefix=/usr/local/php-${PHP_VERSION} --with-mysql=/usr/local/mysql --with-pdo-mysql=/usr/local/mysql/bin/mysql_config --with-mysqli=/usr/local/mysql/bin/mysql_config --with-freetype-dir --with-gd --with-zlib --with-libxml-dir --with-jpeg-dir --with-png-dir --with-curl --with-mhash --enable-mbstring --enable-xml --enable-shmop --enable-sysvsem --enable-bcmath --enable-gd-native-ttf --enable-sockets --enable-zip --enable-soap --enable-ftp --enable-shared --with-openssl --with-mcrypt --with-fpm-user=${FPM_USER} --with-fpm-group=${FPM_USER} --enable-fastcgi --enable-fpm --enable-force-cgi-redirect

    make && make install

    cp php.ini-dist /usr/local/php-${PHP_VERSION}/lib/php.ini

    cd /usr/local/php-${PHP_VERSION}/lib/

    sed -i 's#;date.timezone =#date.timezone = PRC#g' php.ini

    cd /usr/local/php-${PHP_VERSION}/etc/
    sed -i "s#127.0.0.1:9000#127.0.0.1:900${FPM_PORT}#g" php-fpm.conf

    sed -i "s#Unix user of processes#Unix user of processes\n                        <value name=\"user\">${USER}</value>\n                        <value name=\"group\">${USER}</value>#g" php-fpm.conf
    cd /usr/local/src
}


cd /usr/local/src
version="5.2.17"
#user="vagrant"
#user="nginx"
php_port="2"

if [ ! -d "/usr/local/php-${version}" ]; then
    php_install52 ${version} ${user} ${php_port}
fi

