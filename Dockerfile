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

RUN apk --no-cache add php7-bcmath apk-cron php7-pdo php7-pdo_mysql libintl
RUN apk --no-cache add --virtual build-dependencies git util-linux gettext
RUN cp /usr/bin/envsubst /usr/local/bin/envsubst
RUN export KEY=$(uuidgen)
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
RUN apk del build-dependencies

CMD envsubst < config/.config.php.tmpl > config/.config.php &&\
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf