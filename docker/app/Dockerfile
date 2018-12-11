FROM php:7.2-fpm-stretch
RUN apt-get update && \
    apt-get --no-install-recommends --no-install-suggests --yes --quiet install \
        bash-completion \
        ca-certificates \
        curl \
        git \
        imagemagick \
        less \
        make \
        mysql-client \
        perceptualdiff \
        procps \
        ssh-client \
        sudo \
        vim \
        wget \
        libicu-dev \
        g++ \
        zlib1g-dev \
        libpng-dev \
        && apt-get clean && apt-get --yes --quiet autoremove --purge && \
        rm -rf  /var/lib/apt/lists/* /tmp/* /var/tmp/* \
            /usr/share/doc/* /usr/share/groff/* /usr/share/info/* /usr/share/linda/* \
            /usr/share/lintian/* /usr/share/locale/* /usr/share/man/*

RUN docker-php-ext-install \
		intl \
		pdo_mysql \
		mysqli \
		zip \
        gd

RUN useradd docker --shell /bin/bash --create-home \
  && usermod --append --groups sudo docker \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'docker:secret' | chpasswd

# Install composer
RUN curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN chmod +x /usr/local/bin/composer

RUN ln -s /var/www/formation/vendor/drush/drush/drush /usr/bin/drush

# Dev only
RUN pecl install xdebug-2.6.0 \
	&& docker-php-ext-enable xdebug

USER docker
WORKDIR /var/www/formation
