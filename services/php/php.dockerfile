FROM php:7.2-fpm
MAINTAINER hok "hokhyk@aliyun.com"
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
        git \
        curl \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        zlib1g-dev libicu-dev g++ \
        libmcrypt-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install \
    # curl \
    # bz2 \
    # exif \
    # gettext \
    # ldap \
    # pdo_dblib \
    pdo_mysql \
    mysqli \
    # pdo_pgsql \
    # xmlrpc \
    # zip \
    # pdo \
    mbstring \
    # fileinfo \
    # redis \
    # opcache \
    # && pecl install mcrypt-1.0.2 \
    # && docker-php-ext-enable mcrypt \
    && apt-get purge -y --auto-remove \
    && rm -rf /var/cache/apt/* \
    && rm -r /var/lib/apt/lists/*

# Install composer
RUN cd /tmp && php -r "readfile('https://getcomposer.org/installer');" | php && \
    mv composer.phar /usr/bin/composer && \
    chmod +x /usr/bin/composer
RUN echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> ~/.bashrc \
  && . ~/.bashrc

# COPY ./config/php.ini /usr/local/etc/php/conf.d/

# WORKDIR /data
# Write Permission
# RUN usermod -u 1000 www-data
