#!/usr/bin/env bash

# should be run by processing user

# create the directories required to run
test -d /data/site/archive || sudo mkdir -p /data/site/archive
test -d /data/site/raw || sudo mkdir -p /data/site/raw
test -d /data/site/.arrived || sudo mkdir -p /data/site/.arrived
test -d /data/code || sudo mkdir -p /data/code
test -d /data/logs || sudo mkdir -p /data/logs
test -d /data/proc || sudo mkdir -p /data/proc
sudo chmod -R 755 /data

# We should not be root here?
# docker compose build --no-cache
docker compose build
docker compose up
