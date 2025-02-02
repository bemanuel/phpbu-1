FROM php:7.3-alpine

ARG DEV_PACKAGES="freetype-dev libmcrypt-dev libpng-dev libjpeg-turbo-dev libxslt-dev bzip2-dev \
icu-dev postgresql-dev libc-utils libzip-dev \
make autoconf alpine-sdk"
ARG PACKAGES="bzip2 ca-certificates curl git icu-libs libbz2 libedit libgd libjpeg-turbo\
              libmcrypt libpng libpq libxml2 libxslt libzip\
              python3 py3-pip tzdata unzip wget xz zip" 
# Clients for PHPBU
ARG PKG_CLI="mongodb-tools mysql-client postgresql-client redis rsync"

#####################################################################################
#                                                                                   #
#                                 Setup PHP & Extensions                            #
#                                                                                   #
#####################################################################################

#hadolint ignore=DL3018,DL3013
RUN apk -U add --no-cache --virtual=build-deps ${DEV_PACKAGES} \
    && apk add --no-cache ${PACKAGES} ${PKG_CLI} \
    && echo "TZ Tool" \
    && pip3 --no-cache-dir install tzupdate \
    && echo "#Installing php extensions" \
      && pecl install mcrypt \
         && docker-php-ext-enable mcrypt \
      && docker-php-ext-install bcmath zip bz2 mbstring pcntl xsl intl && \
         docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
         docker-php-ext-install gd && \
         docker-php-ext-install opcache && \
         docker-php-ext-install mbstring pdo pdo_mysql pdo_pgsql zip \ 
      && echo "PHP Parameters" \
        && echo "memory_limit=-1" > "$PHP_INI_DIR"/conf.d/memory-limit.ini \
        && echo "date.timezone=${PHP_TIMEZONE:-UTC}" > "$PHP_INI_DIR"/conf.d/date_timezone.ini \
      && echo "Cleanup" \
        && apk del --purge build-deps \
        && rm -rf /tmp/*
####################################################################################
#                                                                                  #
#                               Setup PHPBU                                        #
#                                                                                  #
####################################################################################

ARG PHPBU_VERSION=6.0.16

#hadolint ignore=SC2086
RUN echo "#Setup PHPBU ${PHPBU_VERSION}" \
        && curl -L -o /usr/local/bin/phpbu.phar https://phar.phpbu.de/phpbu-${PHPBU_VERSION}.phar \
        && ln -s /usr/local/bin/phpbu.phar /usr/local/bin/phpbu \
        && chmod +x /usr/local/bin/phpbu 

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
####################################################################################
#                                                                                  #
#                               Setup workspace dir                                #
#                                                                                  #
####################################################################################

WORKDIR /workspace
VOLUME ["/workspace","/backups","/etc/phpbu"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--configuration=/etc/phpbu/script.xml"]
