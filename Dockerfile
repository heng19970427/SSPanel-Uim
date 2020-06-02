FROM trafex/alpine-nginx-php7:ba1dd422
# 从composer 镜像中获取composer二进制程序
COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app
RUN sed -i 's/\/var\/www\/html/\/app\/public/g' /etc/nginx/nginx.conf

ENV UIM_db_host=localhost
ENV UIM_db_database=sspanel
ENV UIM_db_username=root
ENV UIM_db_password=root
ENV UIM_key=asdfghjkl
ENV UIM_muKey=sspanel
ENV UIM_baseUrl=http://localhost
ENV UIM_appName=SSPANEL

RUN apk --no-cache add php7-bcmath apk-cron php7-pdo php7-pdo_mysql
RUN apk --no-cache add --virtual build-dependencies git util-linux
RUN export UIM_key=$(uuidgen)
RUN cp config/.config.example.php config/.config.php 
RUN chmod -R 755 storage 
RUN chmod -R 777 storage/framework/smarty/compile/ 
RUN composer install 
RUN php xcat initdownload 
RUN crontab -l | { cat; echo "30 22 * * * php /var/www/xcat sendDiaryMail"; } | crontab - 
RUN crontab -l | { cat; echo "0 0 * * * php /var/www/xcat dailyjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat checkjob"; } | crontab - 
RUN crontab -l | { cat; echo "*/1 * * * * php /var/www/xcat syncnode"; } | crontab - 
RUN apk del build-dependencies

CMD /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
