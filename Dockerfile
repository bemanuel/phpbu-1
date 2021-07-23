FROM php:7.3-alpine

ARG PHPBU_VERSION=5.2.10
ARG PACKAGES="freetype-dev libmcrypt-dev libpng-dev libjpeg-turbo-dev libxslt-dev bzip2-dev\
              icu-dev postgresql-dev libc-utils libzip-dev \
              make autoconf alpine-sdk"

#####################################################################################
#                                                                                   #
#                                 Setup PHP & Extensions                            #
#                                                                                   #
#####################################################################################
RUN apk -U add --no-cache --virtual=build-deps ${PACKAGES} \
    && apk add --no-cache ca-certificates curl libxml2 libedit libzip wget zip git \
                         xz tzdata unzip bzip2 \ 

    && echo "#Installing php extensions" \
      && pecl install mcrypt \
         && docker-php-ext-enable mcrypt \
      && docker-php-ext-install bcmath zip bz2 mbstring pcntl xsl intl && \
         docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
         docker-php-ext-install gd && \
         docker-php-ext-install opcache && \
         docker-php-ext-install mbstring pdo pdo_mysql pdo_pgsql zip \
      && echo "PHP Parameters" \
        && echo "memory_limit=-1" > $PHP_INI_DIR/conf.d/memory-limit.ini \
        && echo "date.timezone=${PHP_TIMEZONE:-UTC}" > $PHP_INI_DIR/conf.d/date_timezone.ini \
      && echo "#Setup PHPBU" \
        && curl -L -o /usr/local/bin/phpbu.phar https://github.com/sebastianfeldmann/phpbu/releases/download/${PHPBU_VERSION}/phpbu-${PHPBU_VERSION}.phar \
        && ln -s /usr/local/bin/phpbu.phar /usr/local/bin/phpbu \
        && chmod +x /usr/local/bin/phpbu \
      && echo "Cleanup" \
        && apk del --purge build-deps \
        && rm -rf /tmp/*

####################################################################################
#                                                                                  #
#                               Setup workspace dir                                #
#                                                                                  #
####################################################################################

WORKDIR /workspace
VOLUME ["/workspace","/backups","/etc/phpbu"]

ENTRYPOINT ["/usr/local/bin/phpbu"]
CMD ["--configuration=/etc/phpbu/script.xml"]
