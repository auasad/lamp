#!/bin/bash

source utils.sh

INFO "Setting variables and saving them in LAMP_RESULT.txt"

MYSQL_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!#$%&' </dev/urandom | head -c 10 ; echo)
DEPLOY_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!#$%&' </dev/urandom | head -c 10 ; echo)


RUN "echo 'MYSQL_PASSWORD=$MYSQL_PASSWORD' >> LAMP_RESULT.txt"
RUN "echo 'DEPLOY_PASSWORD=$DEPLOY_PASSWORD' >> LAMP_RESULT.txt"


################################################################################
# Install tool
################################################################################

INFO "Installing tools : Git, Vim, Curl"
RUN "apt-get -y -qq update"
RUN "apt-get -y -qq install git vim curl"

################################################################################
# Apache install & securisation
################################################################################
INFO "Installing and securing Apache"

RUN "apt-get -y -qq install apache2"

RUN "a2dissite 000-default.conf"
RUN "a2dissite default-ssl"
RUN "sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf"
RUN "sed -i 's/^ServerSignature On/#ServerSignature On/' /etc/apache2/conf-enabled/security.conf"
RUN "sed -i 's/^#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf-enabled/security.conf"

################################################################################
# MySQL Server
################################################################################
INFO "Installing MySQL Server (password is set automatically and saved in LAMP_RESULT.txt)"

RUN "debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASSWORD'"
RUN "debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD'"
RUN "apt-get -y -qq install mysql-server"

################################################################################
# PHP 7 Repository
################################################################################
INFO "Adding DotDeb Repository to apt list"

RUN "echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list"
RUN "wget -O- https://www.dotdeb.org/dotdeb.gpg | apt-key add -"
RUN "apt-get update -qq"
################################################################################
# Remove PHP 5
################################################################################
INFO "Removing PHP from the system"

RUN "systemctl stop php5-fpm"
RUN "apt-get autoremove -y -qq --purge php5*"

################################################################################
# Install PHP7 and dependencies
################################################################################
INFO "Installing PHP7"

RUN "apt-get -y -qq install php7.0"
RUN "apt-get -y -qq install libapache2-mod-php7.0"
RUN "apt-get -y -qq install php7.0-mysql"
RUN "apt-get -y -qq install php7.0-curl"
RUN "apt-get -y -qq install php7.0-json"
RUN "apt-get -y -qq install php7.0-gd"
RUN "apt-get -y -qq install php7.0-mcrypt"
RUN "apt-get -y -qq install php7.0-msgpack"
RUN "apt-get -y -qq install php7.0-memcached"
RUN "apt-get -y -qq install php7.0-intl"
RUN "apt-get -y -qq install php7.0-sqlite"
RUN "apt-get -y -qq install php7.0-gmp"
RUN "apt-get -y -qq install php7.0-geoip"
RUN "apt-get -y -qq install php7.0-mbstring"
RUN "apt-get -y -qq install php7.0-xml"
RUN "apt-get -y -qq install php7.0-zip"

################################################################################
# Firewall
################################################################################
INFO "Installing and setting up ipTables"

RUN "apt-get -y -qq install iptables"
RUN "cd /tmp && curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer"
RUN "cd /tmp && wget -O /etc/init.d/firewall --no-check-certificate https://gist.githubusercontent.com/npotier/0c037e42ae655a8564c2/raw/"
RUN "chmod +x /etc/init.d/firewall"
RUN "/etc/init.d/firewall"
RUN "update-rc.d firewall defaults"


################################################################################
# Fail2Ban
################################################################################
INFO "Installing and setting up Fail2Ban"

RUN "apt-get -y -qq install fail2ban"
RUN "cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local"

RUN "sed -i '/^\[apache\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/' /etc/fail2ban/jail.local"
RUN "sed -i '/^\[apache-noscript\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/' /etc/fail2ban/jail.local"
RUN "sed -i '/^\[apache-overflows\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/' /etc/fail2ban/jail.local"
RUN "sed -i '/^\[apache-modsecurity\]$/,/^\[/s/enabled[[:blank:]]*=.*/enabled = true/' /etc/fail2ban/jail.local"

################################################################################
# Adding user deploy
################################################################################
INFO "Creating a user 'deploy' into the group www-data (password in LAMP_RESULT.txt)"

RUN "useradd -g www-data deploy"
RUN "echo deploy:$DEPLOY_PASSWORD | chpasswd"
RUN "mkdir -p /home/deploy"
RUN "chown -R deploy:www-data /home/deploy"
RUN "usermod -d /home/deploy deploy"
RUN "usermod -s /bin/bash deploy"
