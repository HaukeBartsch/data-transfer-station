FROM php:8.4-apache-bookworm

# Add company CA certificates
# Each certificate must be PEM format and have .crt extension
COPY ./hvicertificates/company-ca-issuing-02-hvn.crt /usr/local/share/ca-certificates/company-ca-issuing-02-hvn.crt
COPY ./hvicertificates/company-ca-root-hvn.crt /usr/local/share/ca-certificates/company-ca-root-hvn.crt

# Upgrade Apache packages to patched Debian version, install required modules/tools,
# register company CA certificates, and enable Apache modules/sites.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --only-upgrade \
        apache2 \
        apache2-bin \
        apache2-data \
        apache2-utils; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        openssl \
        ssl-cert \
        libapache2-mod-security2 \
        libapache2-mod-evasive; \
    update-ca-certificates; \
    a2enmod security2 proxy_fcgi setenvif rewrite ssl; \
    a2dismod http2 proxy_http2 || true; \
    a2ensite default-ssl; \
    apache2 -v; \
    dpkg -l | grep -E 'apache2|apache2-bin|apache2-data|apache2-utils'; \
    rm -rf /var/lib/apt/lists/*

RUN make-ssl-cert generate-default-snakeoil --force-overwrite

COPY ./index.html /var/www/html/
COPY ./css/ /var/www/html/css/
COPY ./js/ /var/www/html/js/
COPY ./php/ /var/www/html/php/
COPY ./images/ /var/www/html/images/

# Add some hardening of apache2 document root
RUN chown -R www-data:www-data /var/www/html/ \
    && chmod -R 750 /var/www/html/

EXPOSE 443

