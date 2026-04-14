FROM php:8.4-apache
#FROM httpd:2.4
#
# PRODUCTION USE
# ==============
# Expects the receiver to run. Needs access to the logs.
#
# Build, run (use docker-compose instead) and test:
#   docker build -t log_viewer -f Dockerfile .

# As an output this container will accept incoming web connections at 443 (https).

RUN apt update \
    && apt install -yq openssl ssl-cert libapache2-mod-security2 libapache2-mod-evasive \
    && a2enmod security2 proxy_fcgi setenvif rewrite \
    && a2enmod ssl \
    && a2ensite default-ssl

RUN make-ssl-cert generate-default-snakeoil --force-overwrite

COPY ./index.html /var/www/html/
COPY ./css/ /var/www/html/css/
COPY ./js/ /var/www/html/js/
COPY ./php/ /var/www/html/php/
COPY ./images/ /var/www/html/images/
#COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
#COPY ./certs/server.key /etc/ssl/private/ssl-cert-snakeoil.key
#COPY ./certs/server.crt /etc/ssl/certs/ssl-cert-snakeoil.crt

# add some hardening of apache2
RUN chown -R www-data:www-data /var/www/html/ && chmod -R 750 /var/www/html/

# Access to log files


EXPOSE 443
