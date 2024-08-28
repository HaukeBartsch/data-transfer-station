FROM debian:bookworm-slim
# Build, run and test:
#   docker build -t trigger -f Dockerfile .
#   docker run --rm -v /tmp/archive:/data/site/archive -v /tmp/.arrived:/data/site/.arrived -v /tmp:/root/logs trigger
#   storescu -v -aec FIONA -aet FIONA -nh +r +sd localhost 11112 hackathon-dataset 

RUN apt update && apt install -y procps net-tools jq dcmtk cron wget cmake gcc g++ python3 python3-pip systemd apache2

COPY trigger.py /trigger.py
COPY config.json /config.json
COPY --chown=www-data log_viewer/ /var/www/html/

RUN mkdir -p /data/logs/ && touch /data/logs/trigger.log

CMD [ "/trigger.py", "config.json" ]
