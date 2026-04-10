FROM httpd:2.4
#
# PRODUCTION USE
# ==============
# Expects the receiver to run. Needs access to the logs.
#
# Build, run (use docker-compose instead) and test:
#   docker build -t log_viewer -f Dockerfile .

# As an output this container will accept incoming web connections at 443 (https).

RUN apt update && apt install -yq php-fpm libapache2-mod-php && a2enconf php8.4-fpm

COPY ./index.html /usr/local/apache2/htdocs/
COPY ./css/ /usr/local/apache2/htdocs/css/
COPY ./js/ /usr/local/apache2/htdocs/js/
COPY ./php/ /usr/local/apache2/htdocs/php/
COPY ./images/ /usr/local/apache2/htdocs/images/
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./certs/server.crt /usr/local/apache2/conf/server.crt
COPY ./certs/server.key /usr/local/apache2/conf/server.key


# Access to log files


EXPOSE 443
