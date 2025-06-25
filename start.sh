#!/usr/bin/env bash

# should be run by processing user

# create the directories required to run
test -d /data/site/archive || sudo mkdir -m 755 -p /data/site/archive
test -d /data/site/raw || sudo mkdir -m 755 -p /data/site/raw
test -d /data/site/.arrived || sudo mkdir -m 755 -p /data/site/.arrived
test -d /data/code || sudo mkdir -m 755 -p /data/code
test -d /data/logs || sudo mkdir -m 755 -p /data/logs
test -d /data/proc || sudo mkdir -m 755 -p /data/proc

# We should not be root here?
# docker compose build --no-cache
docker compose build
docker compose up
