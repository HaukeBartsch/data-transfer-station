FROM debian:bookworm-slim
#
# A logrotate container for data-transfer-station.
#
# Build, run and test:
#   docker build --no-cache -t logrotate -f Dockerfile .

RUN apt update && apt install -yq cron logrotate

COPY logrotate.conf /etc/logrotate.d/data-transfer-station

RUN crontab -l | { cat; echo "*/10 * * * * /usr/sbin/logrotate -v /etc/logrotate.conf"; } | crontab -

CMD [ "cron", "-f" ]
