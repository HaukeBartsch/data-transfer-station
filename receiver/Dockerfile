FROM debian:bookworm-slim
# Build, run and test:
#   docker build --no-cache -t receiver -f Dockerfile .
#   docker run --rm -d -p 11112:11112 -v /tmp:/data/site/archive -v /tmp:/root/logs receiver
#   # docker run --rm -d -p 11112:11112 -v /tmp:/data/site/archive -v /tmp/.arrived:/data/site/.arrived -v /tmp/raw:/data/site/raw -v /tmp:/root/logs receiver
#   storescu -v -aec FIONA -aet FIONA -nh +r +sd localhost 11112 hackathon-dataset 
# Setup as a system service by (linux only):
#   cp etc_systemd_system_docker.receiver.service /etc/systemd/system/docker.receiver.service
#   systemctl enable docker.receiver.service
#   systemctl start docker.receiver.service  

RUN apt update && apt install -y procps net-tools jq dcmtk cron wget cmake gcc g++ python3 python3-pip python3-pydicom

#RUN apt install -y vim emacs less

COPY storectl.sh /root/
COPY processSingleFile3.py /root/
COPY heartbeat.sh /root/
COPY config.json /data/config/config.json
COPY classifyRules.json /root/

RUN mkdir -p /root/logs \
    && mkdir -p /root/.pids \
    && mkdir -p /data/site/archive \
    && mkdir -p /data/site/raw \
    && mkdir -p /data/site/.arrived \
    && mkdir -p /data/site/temp

RUN chmod 0744 /root/storectl.sh
RUN chmod 0744 /root/heartbeat.sh

# Lets use a default project name "PROJ". We need a corresponding entry in /data/config/config.json.
RUN crontab -l | { cat; echo "*/10 * * * * /root/storectl.sh start PROJ"; } | crontab -
RUN crontab -l | { cat; echo "@reboot /root/storectl.sh start PROJ"; } | crontab -
RUN crontab -l | { cat; echo "*/10 * * * * python3 /root/processSingleFile3.py start PROJ"; } | crontab -
RUN crontab -l | { cat; echo "@reboot python3 /root/processSingleFile3.py start PROJ"; } | crontab -
RUN crontab -l | { cat; echo "* * * * * /root/heartbeat.sh PROJ"; } | crontab -

# create the propper storescp (depends on 3.6.7)
RUN cd /opt && wget https://dicom.offis.de/download/dcmtk/dcmtk367/dcmtk-3.6.7.tar.gz \
    && tar zxvf dcmtk-3.6.7.tar.gz && \rm -f dcmtk-3.6.7.tar.gz && cd dcmtk-3.6.7 \
    && mv /opt/dcmtk-3.6.7/dcmnet/apps/storescp.cc /opt/dcmtk-3.6.7/dcmnet/apps/storescp.cc_backup 

COPY storescp.cc_new /opt/dcmtk-3.6.7/dcmnet/apps/storescp.cc

riggRUN apt install -y zlib1g-dev libtiff-dev libpng-dev libssl-dev libicu-dev libxml2-dev libopenjp2-7-dev libwrap0-dev libsndfile1-dev
RUN cd /opt/dcmtk-3.6.7/ && cmake . && make storescp && cp /opt/dcmtk-3.6.7/bin/storescp /root/storescpFIONA

RUN \rm -rf /opt/dcmtk-3.6.7 && apt-get clean && apt-get autoremove --yes

WORKDIR /root/

# we will listen to this port for incoming DICOMs (needs to match what is in /data/config/config.json)
EXPOSE 11112

CMD [ "cron", "-f" ]
