FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute

#Apache
RUN apt-get install -y apache2
RUN a2enmod rewrite

#MySql
RUN apt-get install -y mysql-server mysql-client

#PHP
RUN apt-get install -y php libapache2-mod-php php-mcrypt php-mysql php-gd php-curl php-ssh2 php-simplexml php-mbstring php-zip php-imagick php-intl php-soap

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php

#Magento
RUN rm /var/www/html/index.html
RUN git clone --depth=1 https://github.com/magento/magento2.git /var/www/html
RUN cd /var/www/html && \
    composer install
RUN chown -R www-data:www-data /var/www/html

#Sample Data
RUN cd /var/www/html && \
    git clone --depth=1 https://github.com/magento/magento2-sample-data && \
    php -f magento2-sample-data/dev/tools/build-sample-data.php -- --ce-source="/var/www/html" && \
    chown -R :www-data . && \
    find . -type d -exec chmod g+ws {} \;

COPY php.ini /etc/php/7.0/apache2/
COPY 000-default.conf /etc/apache2/sites-enabled/

#Configure MySql
COPY mysql.ddl /
RUN mysqld_safe & mysqladmin --wait=5 ping && \
    mysql < mysql.ddl && \
    mysqladmin shutdown

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO

