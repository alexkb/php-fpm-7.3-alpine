FROM php:7.3-fpm-alpine

# Tip from https://github.com/docker-library/php/issues/57#issuecomment-318056930
# and https://github.com/docker-library/php/issues/279#issuecomment-236441847
RUN set -xe \
    && apk add --update icu \
    && apk add --no-cache --virtual .php-deps make \
    && apk add --no-cache --virtual .deps \
        libzip-dev \
        icu-dev \
        g++ \
        imagemagick-dev \
        libtool \
        make \
    && docker-php-ext-configure zip --with-libzip=/usr/include \
    && docker-php-ext-install zip \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install tokenizer \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-enable intl \
    && { find /usr/local/lib -type f -print0 | xargs -0r strip --strip-all -p 2>/dev/null || true; } \
    && apk del .deps \
    && rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*
# Image optimisations
# apt-get install -y --force-yes jpegoptim optipng pngquant gifsicle

# https://github.com/docker-library/php/issues/412#issuecomment-297180591
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

RUN apk add --no-cache libpng-dev \
    && docker-php-ext-install gd

# https://medium.com/@takuma.seno/install-php-extensions-on-docker-87a7b1b2531b
RUN pecl install mailparse \
    && docker-php-ext-enable mailparse

# https://stackoverflow.com/a/47673183/687274
RUN apk add --no-cache libmcrypt-dev \
    && yes | pecl install -o -f mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt

COPY ./laravel.ini  /usr/local/etc/php/conf.d
COPY ./xlaravel.pool.conf /usr/local/etc/php-fpm.d/

RUN apk --update add curl \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

USER root

# Tip from https://github.com/chrootLogin/docker-nextcloud/issues/3#issuecomment-271626117
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk --no-cache add shadow \
    && usermod -u 1000 www-data

WORKDIR /var/www

CMD ["php-fpm"]

EXPOSE 9000
