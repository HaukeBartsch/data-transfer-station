FROM debian:bookworm-slim
#
# PRODUCTION USE
# ==============
# Expects the receiver to run. Needs access to receivers .arrived and archive directories.
#
# Build, run (use docker-compose instead) and test:
#   docker build -t trigger -f Dockerfile .
#   docker run --rm -v /tmp/archive:/data/site/archive -v /tmp/.arrived:/data/site/.arrived -v /tmp:/root/logs trigger
#   storescu -v -aec FIONA -aet FIONA -nh +r +sd localhost 11112 hackathon-dataset 

# As an output this container will write into the joblist file "/data/code/workflow_joblist.jobs" (for runner).

RUN apt update && apt install -yq procps net-tools jq dcmtk cron wget cmake gcc g++ python3 python3-pip systemd apache2 python3-sqlalchemy

COPY trigger.py /trigger.py
COPY BackendLogging.py /BackendLogging.py
COPY addJob.sh /addJob.sh
COPY pullSelect.sh /pullSelect.sh
RUN chmod +x /trigger.py /addJob.sh /pullSelect.sh
# Do not use the log-viewer for now
#COPY --chown=www-data log_viewer/ /var/www/html/

RUN mkdir -p /data/logs/ && touch /data/logs/trigger.log \
    && wget -qO- https://github.com/mmiv-center/Research-Information-System/raw/master/components/Workflow-Image-AI/build/linux-amd64/ror > /usr/sbin/ror \
    && chmod +x /usr/sbin/ror;


CMD [ "/trigger.py", "/configuration/config.json" ]
