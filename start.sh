#!/usr/bin/env bash
set -e

# check if we are in the correct directory
if [ ! -e "runner/runOneJob.sh" ]; then
    echo "Please run this script from the root of the repository."
    exit 1
fi

# create the directories required to run
test -d /data/site/archive || sudo mkdir -m 755 -p /data/site/archive
test -d /data/site/raw || sudo mkdir -m 755 -p /data/site/raw
test -d /data/site/temp || sudo mkdir -m 755 -p /data/site/temp
test -d /data/site/.arrived || sudo mkdir -m 755 -p /data/site/.arrived
test -d /data/code || sudo mkdir -m 755 -p /data/code
test -d /data/logs || sudo mkdir -m 755 -p /data/logs
test -d /data/proc || sudo mkdir -m 755 -p /data/proc

# copy over the runner code
sudo mkdir -m 755 -p /data/code/trigger;
sudo chmod +x /data/code/trigger/runOneJob.sh;
if ! crontab -l | grep -qs "runOneJob.sh"; then
    sudo bash -c "( crontab -l; echo '*/1 * * * * /usr/bin/flock -n /data/logs/runOneJob.pid /data/code/trigger/runOneJob.sh >> /data/logs/runOneJob.log 2>&1' ) | crontab - ";
fi

# check if ror exists and is not empty
if [ ! -s /data/code/trigger/ror ]; then
    # this file could be empty after the download
    sudo bash -c "wget -qO- https://github.com/mmiv-center/Research-Information-System/raw/master/components/Workflow-Image-AI/build/linux-amd64/ror > /data/code/trigger/ror";
    sudo chmod +x /data/code/trigger/ror;
fi

# cleanup after a reboot (keep log files but remove pid files and all the temp data in /data/site/archive/*, /data/site/raw/* and /data/proc/*)
if ! crontab -l | grep -qs "@reboot"; then
    sudo bash -c "( crontab -l; echo '@reboot rm -rf /data/logs/*.pid /data/proc/scp* /data/site/archive/scp* /data/site/raw/* ) | crontab - ";
fi

# This can be run by a non-root user.
# docker compose build --no-cache
docker compose down && docker compose build && docker compose up
