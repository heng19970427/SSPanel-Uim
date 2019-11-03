FROM trafex/alpine-nginx-php7:ba1dd422
# 从composer 镜像中获取composer二进制程序
COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app
RUN sed -i 's/\/var\/www\/html/\/app\/public/g' /etc/nginx/nginx.conf

ENV MYSQL_HOST=localhost
ENV MYSQL_DB=sspanel
ENV MYSQL_USER=root
ENV MYSQL_PASSWORD=root
ENV KEY=asdfghjkl
ENV TOKEN=sspanel
ENV BASEURL=http://localhost
ENV SITE_NAME=SSPANEL

RUN apk --no-cache add php7-bcmath apk-cron
RUN apk --no-cache add --virtual git
RUN cp config/.config.example.php config/.config.php 
RUN chmod -R 755 storage 
RUN chmod -R 777 storage/framework/smarty/compile/ 
RUN composer install 
RUN php xcat initQQWry 
RUN php xcat initdownload 
RUN crontab -l | { cat; echo "30 22 * * * php /var/www/xcat sendDiaryMail"; } | crontab - 
RUN crontab -l | { cat; echo "0 0 * * * php /var/www/xcat dailyjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat checkjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat syncnode"; } | crontab - 

CMD sed -i "/$System_Config\['key'\] =/c \$System_Config\['key'\] = '$KEY';" config/.config.php &&\
    sed -i "/$System_Config\['appName'\] =/c \$System_Config\['appName'\] = '$SITE_NAME';" config/.config.php &&\
    sed -i "/$System_Config\['baseUrl'\] =/c \$System_Config\['baseUrl'\] = '$BASEURL';" config/.config.php &&\
    sed -i "/$System_Config\['muKey'\] =/c \$System_Config\['muKey'\] = '$TOKEN';" config/.config.php &&\
    sed -i "/$System_Config\['db_host'\] =/c \$System_Config\['db_host'\] = '$MYSQL_HOST';" config/.config.php &&\
    sed -i "/$System_Config\['db_database'\] =/c \$System_Config\['db_database'\] = '$MYSQL_DB';" config/.config.php &&\
    sed -i "/$System_Config\['db_username'\] =/c \$System_Config\['db_username'\] = '$MYSQL_USER';" config/.config.php &&\
    sed -i "/$System_Config\['db_password'\] =/c \$System_Config\['db_password'\] = '$MYSQL_PASSWORD';" config/.config.php &&\
    php -S 0000:9000 -t /var/www/public 