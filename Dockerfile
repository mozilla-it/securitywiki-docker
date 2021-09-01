FROM php:7.2-cli AS composer

RUN set -ex; \
	EXPECTED_SIGNATURE=$(curl https://composer.github.io/installer.sig); \
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"\
	php -r "if (hash_file('SHA384', 'composer-setup.php') === ${EXPECTED_SIGNATURE}){ echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"; \
	php composer-setup.php --install-dir=/bin --filename=composer; \
	php -r "unlink('composer-setup.php');";

FROM mediawiki:1.31.5

ENV MEDIAWIKI_MAJOR_VERSION 1.31
ENV MEDIAWIKI_BRANCH REL1_31
ENV MEDIAWIKI_VERSION 1.31.5
ENV MOD_OPENOIDC_VERSION 2.4.0
ENV LIBJOSE_VERSION 0.6.1.5

# Install openoidc package
RUN set -eux; \
	apt-get update && \
	apt-get install -y --no-install-recommends \
			libjansson4 \
			libhiredis0.14 && \
	curl -Lfs -o /tmp/libjose.deb https://github.com/zmartzone/mod_auth_openidc/releases/download/v${MOD_OPENOIDC_VERSION}/libcjose0_${LIBJOSE_VERSION}-1.buster+1_amd64.deb && \
	curl -Lfs -o /tmp/libapache-mod-auth-openidc.deb https://github.com/zmartzone/mod_auth_openidc/releases/download/v${MOD_OPENOIDC_VERSION}/libapache2-mod-auth-openidc_${MOD_OPENOIDC_VERSION}-1.buster+1_amd64.deb && \
	dpkg -i /tmp/libjose.deb && \
	dpkg -i /tmp/libapache-mod-auth-openidc.deb && \
    # Install mediawiki packages
	apt-get install -y --no-install-recommends \
			libxml2-dev \
			zip \
			libzip-dev \
			libz-dev \
			libmemcached-dev && \
	docker-php-ext-configure zip --with-libzip && \
	docker-php-ext-install -j "$(nproc)" zip && \
	docker-php-ext-install -j "$(nproc)" mbstring xml && \
	pecl install memcached && \
	docker-php-ext-enable memcached && \
	echo "extension=memcache.so" >> /usr/local/etc/php/conf.d/memcached.ini && \
	apt-get purge -y --auto-remove && \
	apt-get clean -y && \
	apt-get autoclean -y && \
	rm -rf /var/lib/apt/lists/* /var/lib/{apt,dpkg,cache,log}/ /var/tmp/* /tmp/*.deb

# Setup securitywiki config
RUN set -eux; \
	mkdir -p /etc/securitywiki && \
	chown www-data:www-data /etc/securitywiki && \
	chmod 0744 /etc/securitywiki

WORKDIR /var/www/html

# Get Skins and extensions
RUN git clone https://gerrit.wikimedia.org/r/mediawiki/skins/CologneBlue  --branch ${MEDIAWIKI_BRANCH} skins/CologneBlue && \
	git clone https://gerrit.wikimedia.org/r/mediawiki/skins/Modern  --branch ${MEDIAWIKI_BRANCH} skins/Modern  && \
	git clone https://github.com/DaSchTour/Cavendish.git skins/Cavendish && \
	git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/Auth_remoteuser --branch ${MEDIAWIKI_BRANCH} extensions/Auth_remoteuser

# Copy settings
COPY --from=composer /bin/composer /bin/composer
COPY build/mediawiki/LocalSettings.php /var/www/html/
COPY build/mediawiki/securitywiki.php /etc/securitywiki/
COPY build/mediawiki/health.php /var/www/html
COPY build/apache/000-securitywiki.conf /etc/apache2/sites-enabled/000-default.conf
COPY build/apache/openidc.conf /etc/apache2/conf-enabled/openidc.conf
COPY build/apache/apache.sh /etc/profile.d/apache.sh
COPY build/wiki_header_logo.gif /var/www/html/skins/wiki_header_logo.gif
COPY build/php.ini /usr/local/etc/php/conf.d/php.ini

# Misc
RUN set -eux; \
	echo ". /etc/profile.d/apache.sh" >> /etc/apache2/envvars; \
	chmod 0644 /etc/securitywiki/securitywiki.php; \
	mkdir -p /data/securitywiki; \
	chown -R www-data:www-data /var/www/html /data/securitywiki; \
	a2enmod headers rewrite expires auth_openidc; \
	composer self-update --1; \
	composer install --no-dev --verbose;
