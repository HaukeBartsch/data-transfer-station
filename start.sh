#!/usr/bin/env bash

# create the directories required to run
test -d /data/site/archive || sudo mkdir -m 755 -p /data/site/archive
test -d /data/site/raw || sudo mkdir -m 755 -p /data/site/raw
test -d /data/site/.arrived || sudo mkdir -m 755 -p /data/site/.arrived
test -d /data/code || sudo mkdir -m 755 -p /data/code
test -d /data/logs || sudo mkdir -m 777 -p /data/logs
test -d /data/proc || sudo mkdir -m 755 -p /data/proc

# copy over the runner code
sudo mkdir -m 755 -p /data/code/trigger;
sudo cp runner/runOneJob.sh runner/BackendLogging.py /data/code/trigger/;
sudo chmod +x /data/code/trigger/runOneJob.sh;
sudo chmod +x /data/code/trigger/BackendLogging.py;
if ! crontab -l | grep -qs "runOneJob.sh"; then
    sudo ( crontab -l; echo '*/1 * * * * /usr/bin/flock -n /data/logs/runOneJob.pid /data/code/trigger/runOneJob.sh >> /data/logs/runOneJob.log 2>&1' ) | crontab - ;
fi
if [ ! -e /data/code/trigger/ror ]; then
    sudo wget -qO- https://github.com/mmiv-center/Research-Information-System/raw/master/components/Workflow-Image-AI/build/linux-amd64/ror > /data/code/trigger/ror;
    sudo chmod +x /data/code/trigger/ror;
fi

# This can be run by a non-root user.
# docker compose build --no-cache
docker compose build && docker compose up
