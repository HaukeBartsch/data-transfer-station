FROM httpd:2.4
#
# PRODUCTION USE
# ==============
# Expects the receiver to run. Needs access to the logs.
#
# Build, run (use docker-compose instead) and test:
#   docker build -t log_viewer -f Dockerfile .

# As an output this container will accept incoming web connections at 443 (https).

COPY ./index.html /var/www/html/
COPY ./css/ /var/www/html/css/
COPY ./js/ /var/www/html/js/

# Access to log files


EXPOSE 443
