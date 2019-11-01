FROM php:7.2-fpm

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY . /var/www
WORKDIR /var/www

ENV MYSQL_HOST=localhost
ENV MYSQL_DB=sspanel
ENV MYSQL_USER=root
ENV MYSQL_PASSWORD=root
ENV KEY=asdfghjkl
ENV TOKEN=sspanel
ENV BASEURL=http://localhost
ENV SITE_NAME=SSPANEL

RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    git \
    zip \
    cron \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) bcmath 
RUN cp config/.config.example.php config/.config.php 
RUN chmod -R 755 storage 
RUN chmod -R 777 /var/www/storage/framework/smarty/compile/ 
RUN composer install 
RUN php xcat initQQWry 
RUN php xcat initdownload 
RUN crontab -l | { cat; echo "30 22 * * * php /var/www/xcat sendDiaryMail"; } | crontab - 
RUN crontab -l | { cat; echo "0 0 * * * php /var/www/xcat dailyjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat checkjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat syncnode"; } | crontab - 
EXPOSE 9000

CMD sed -i "/_ENV\['key'\] =/c \$_ENV\['key'\] = '$KEY';" config/.config.php &&\
    sed -i "/_ENV\['appName'\] =/c \$_ENV\['appName'\] = '$SITE_NAME';/g" config/.config.php &&\
    sed -i "/_ENV\['baseUrl'\] =/c \$_ENV\['baseUrl'\] = '$BASEURL';/g" config/.config.php &&\
    sed -i "/_ENV\['muKey'\] =/c \$_ENV\['muKey'\] = '$TOKEN';/g" config/.config.php &&\
    sed -i "/_ENV\['db_host'\] =/c \$_ENV\['db_host'\] = '$MYSQL_HOST';/g" config/.config.php &&\
    sed -i "/_ENV\['db_database'\] =/c \$_ENV\['db_database'\] = '$MYSQL_DB';/g" config/.config.php &&\
    sed -i "/_ENV\['db_username'\] =/c \$_ENV\['db_username'\] = '$MYSQL_USER';/g" config/.config.php &&\
    sed -i "/_ENV\['db_password'\] =/c \$_ENV\['db_password'\] = '$MYSQL_PASSWORD';/g" config/.config.php &&\
    php -S 0000:9000 -t /sspanel/public 