#!/usr/bin/env bash

# create the directories required to run
test -d /data/site/archive && mkdir -p /data/site/archive
test -d /data/site/raw && mkdir -p /data/site/raw
test -d /data/site/.arrived && mkdir -p /data/site/.arrived
test -d /data/code && mkdir -p /data/code
test -d /data/logs && mkdir -p /data/logs
test -d /data/proc && mkdir -p /data/proc

# docker compose build --no-cache
docker compose build
docker compose up
