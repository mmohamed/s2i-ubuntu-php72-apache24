FROM ubuntu

EXPOSE 8080

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_CACHE_DIR=/tmp \
    COMPOSER_HASH=48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5 \
    SUMMARY="Platform for building and running PHP applications" \
    DESCRIPTION="PHP 7.2, Apache 2.4, Git and Composer are available at this container"

LABEL summary="${SUMMARY}" \
      description="${DESCRIPTION}" \
      io.k8s.description="${DESCRIPTION}" \
      io.k8s.display-name="Apache 2.4 with PHP 7.2" \
      io.openshift.expose-services="8080:http" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      io.s2i.scripts-url="image:///usr/libexec/s2i" \
      name="ubuntu/php-72" \
      version="7.2" \
      help="For more information visit https://github.com/mmohamed/s2i-ubuntu-php72-apache24" \
      maintainer="MedInvention <medmarouen@gmail.com>"

RUN apt-get -y update && apt-get -y upgrade

RUN apt-get -y install php

RUN apt-get install -y php php-mysqlnd php-pgsql php-bcmath php-gd php-intl php-ldap \
    php-mbstring php-curl php-soap php-opcache php-xml php-memcached \
    php-gmp libapache2-mod-php php-sqlite3 zip unzip php-zip

RUN php -v

RUN apt-get install -y apache2 curl git-core

RUN curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php && \
    php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$COMPOSER_HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;" && \
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('/tmp/composer-setup.php');"

COPY conf-http/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY conf-http/000-default.conf /etc/apache2/sites-available/000-default.conf

RUN sed -i 's/${APP_PATH}/\/opt\/app-root\/src/g' /etc/apache2/sites-enabled/000-default.conf && \
    sed -i 's/^Listen 80/Listen 0.0.0.0:8080/' /etc/apache2/ports.conf && \
    sed -i 's/${APACHE_RUN_USER}/default/' /etc/apache2/apache2.conf && \
    sed -i 's/${APACHE_RUN_GROUP}/root/' /etc/apache2/apache2.conf && \
    sed -i '170s%AllowOverride None%AllowOverride All%' /etc/apache2/apache2.conf && \
    sed -i 's/var\/www/opt\/app-root\/src\/public/' /etc/apache2/apache2.conf

COPY ./s2i/bin/ /usr/libexec/s2i

COPY ./public /opt/app-root/src/public

RUN useradd -u 1001 -r -g 0 -d /default -s /sbin/nologin \
   -c "Default Application User" default && \
   chown -R default:root /var/log/apache2 /opt/app-root/src /var/run/apache2

RUN rm -rf /opt/app-root/src/*

USER 1001

CMD echo $SUMMARY
