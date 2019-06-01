## Hok's LNMPA docker stack

I'll use docker-compose and Dockerfile to setup a multi-virtual host php environment under LNMPA stack. 

There are 3 main steps:

1. create LNMPA folders on host.
2. Compose Nginx, mysql, php and php-fpm configuration files.
3. Setting up Nginx, mysql, php-fpm, phpmyadmin, redis and angular Dockerfile.
4. Organize Dockerfile, configuration files with docker-compose.yml.

It is assumed that you have installed docker-desktop and docker-compose tools. No matter you're using  linux, mac or windows OS.

My setup is as below:

```shell
hokhykdeMacBook-Pro:summary hok$ docker -v
Docker version 18.09.2, build 6247962

hokhykdeMacBook-Pro:summary hok$ docker-compose -v
docker-compose version 1.23.2, build 1110ad01
```

# 1. LNMPA directory structure on the host

```shell
mkdir lnmpa
cd lnmpa
touch .gitignore

mkdir -p data/wwwroot
mkdir -p data/mysql
touch data/mysql/.gitignore

mkdir -p data/redis
mkdir -p logs

mkdir -p services/nginx
touch services/nginx/nginx.dockerfile
mkdir -p services/nginx/conf/vhost
touch services/nginx/conf/nginx.conf
touch services/nginx/conf/vhost/example.com.conf
cp services/nginx/conf/vhost/example.com.conf services/nginx/conf/vhost/yourdomain.com.conf

mkdir -p services/php
touch services/php/php.dockerfile
mkdir -p services/php/conf
touch services/php/conf/php.ini
touch services/php/conf/php-fpm.conf

mkdir -p services/mysql
touch services/mysql/mysql.dockerfile
mkdir -p services/mysql/conf
touch services/mysql/conf/mysql.cnf

mkdir -p services/phpmyadmin
touch services/phpmyadmin/phpmyadmin.dockerfile

mkdir -p services/redis
touch services/redis/redis.dockerfile

mkdir -p services/angular
touch services/angular/angular.dockerfile

touch services/docker-compose.yml
```

# 2. Compose Nginx, mysql and php configuration files.



## 

# 3. Setting up Nginx, mysql and php Dockerfile

## 3.1 Nginx Dockerfile(nginx.dockerfile)

```dockerfile
FROM nginx:1.16
ENV TZ=Asia/Beijing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ> /etc/timezone
```

## 3.2 Mysql Dockerfile(mysql.dockerfile)

```dockerfile
FROM mysql:8.0
ENV TZ=Asia/Beijing
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ> /etc/timezone
```

## 3.3 PHP Dockerfile (php.dockerfile)

```dockerfile
FROM php:7.2-fpm
MAINTAINER hok "hokhyk@aliyun.com"
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
        git \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) intl \

    && docker-php-ext-install \
    curl \
    # bz2 \
    # exif \
    # gettext \
    intl \
    # ldap \
    # pdo_dblib \
    pdo_mysql \
    mysqli \
    pdo_pgsql \
    # xmlrpc \
    # zip \
    # pdo \
    mbstring \
    mcrypt \
    fileinfo \
    # redis \
    # opcache \

    && apt-get purge -y --auto-remove \
    && rm -rf /var/cache/apt/* \
    && rm -r /var/lib/apt/lists/*

# Install composer
RUN cd /tmp && php -r "readfile('https://getcomposer.org/installer');" | php && \
    mv composer.phar /usr/bin/composer && \
    chmod +x /usr/bin/composer
RUN echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> ~/.bashrc \
  && . ~/.bashrc


COPY ./config/php.ini /usr/local/etc/php/conf.d/

# WORKDIR /data
# Write Permission
# RUN usermod -u 1000 www-data
```

## 3.4 Redis(redis.dockerfile)

```dockerfile
FROM redis:3.2
# set timezome
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```

## 3.5 Angular(angular.dockerfile)

```dockerfile
FROM angular/ngcontainer
# set timezome
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```

## 3.6 PhpMyadmin(phpmyadmin.dockerfile)

```dockerfile
FROM phpmyadmin/phpmyadmin
# set timezome
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
```



# 4. Docker-compose.yml

```yaml
version: '3.1'
services:
  # The nginx Web Server
  nginx:
    container_name:nginx
    build:
      context: ./nginx
      dockerfile: nginx.dockerfile
    volumes:
      # mounted for static resources/frontend under frontend/backend separated deployment.
      - /nginx/wwwroot:/var/www
      
    volumes:
      - ../data/wwwroot:/data/www:rw
      - ./nginx/conf/vhost:/etc/nginx/conf.d
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ../logs/nginx:/var/log/nginx
    networks:
      - app
      - phpmyadmin
    ports:
      - 80:80
      - 8080:8080
      - 443:443
    restart: always
    command: nginx -g 'daemon off;'

  # The Application (laravel, django and so on...) 
  php:
      container_name:php
    build:
      context: ./php
      dockerfile: php.dockerfile
    working_dir: /var/www
    volumes:
      - ./:/var/www
    environment:
      - "DB_PORT=3306"
      - "DB_HOST=database"
    depends_on:
      - database
      - phpmyadmin



  # The Database
  mysql:
      container_name:mysql
    build:
      context: ./mysql
      dockerfile: mysql.dockerfile
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    volumes:
      - dbdata:/var/lib/mysql
    environment:
      - "MYSQL_DATABASE=homestead"
      - "MYSQL_USER=homestead"
      - "MYSQL_PASSWORD=secret"
      - "MYSQL_ROOT_PASSWORD=secret"
    ports:
        - "33061:3306"
  
  phpmyadmin:
    build:
      context: ./phpmyadmin
      dockerfile: phpmyadmin.dockerfile
    restart: always
    ports:
      - "8081:80"
    environment:
      PMA_HOST: "mysql"
      PMA_USER: "root"
      PMA_PASSWORD: "admin"
 
   angular:
      container_name:angular
    build:
      context: ./angular
      dockerfile: angular.dockerfile
    restart: always
 
  redis:
      container_name:redis-server
    build:
      context: ./
      dockerfile: redis.dockerfile
    restart: always

```





