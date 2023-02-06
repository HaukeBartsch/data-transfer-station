FROM debian:bookworm-slim
# Build, run and test:
#   docker build -t trigger -f Dockerfile .
#   docker run --rm -d -p 11112:11112 -v /tmp:/data/site/archive -v /tmp/.arrived:/data/site/.arrived -v /tmp:/root/logs receiver
#   storescu -v -aec FIONA -aet FIONA -nh +r +sd localhost 11112 hackathon-dataset 

RUN apt update && apt install -y procps net-tools jq dcmtk cron wget cmake gcc g++ python3 python3-pip


# we will listen to this port for incoming DICOMs (needs to match what is in /data/config/config.json)
EXPOSE 11112

CMD [ "cron", "-f" ]
