#
# Setup and check the configuration of DTS
#
SHELL := /bin/bash


.PHONY: all
all: run-as-root receiver-exists receiver-running trigger-running


#
# Check if we have all software isntalled
#
REQUIRED-SOFTWARE = podman md5sum apache2 storescu logrotate php

K := $(foreach bin,$(REQUIRED-SOFTWARE),\
    $(if $(shell command -v $(bin) 2> /dev/null),$(info Found `$(bin)`),$(error Please install `$(bin)`)))

run-as-root :
	@if [ $${EUID} -ne 0 ] ;\
	then \
	  echo "Error: You need to be root"; \
	  exit 1; \
	fi
	@echo "You are root, continue with checking...";


receiver-exists:
	$(if $(shell podman images -q "receiver" 2> /dev/null),$(info check for receiver container, ok),$(error Please install receiver with cd receiver; podman build -t receiver -f Dockerfile))

receiver-running: data-folders receiver-exists receiver/etc_systemd_system_docker.receiver.service
	cp receiver/etc_systemd_system_docker.receiver.service /etc/systemd/system/docker.receiver.service
	systemctl enable docker.receiver.service
	systemctl start docker.receiver.service
	@if ! systemctl status -q docker.receiver.service > /dev/null; \
	then \
	  echo -e "Check the output of: systemctl status docker.receiver.service and fix issues, reboot"; \
	  exit 1; \
	fi

data-folders:
	@test -d /data/site/archive || mkdir -p /data/site/archive
	@test -d /data/site/raw || mkdir -p /data/site/raw
	@test -d /data/site/.arrived || mkdir -p /data/site/.arrived
	@test -d /data/logs || mkdir -p /data/logs
	@echo "check /data/site folders done"

trigger-running: trigger/etc_systemd_system_trigger.service trigger/trigger.py trigger/config.json
	cp trigger/etc_systemd_system_trigger.service /etc/systemd/system/trigger.service
	test -d /data/code/trigger || mkdir -p /data/code/trigger
	cp trigger/trigger.py /data/code/trigger/trigger.py
	cp trigger/config.json /data/code/trigger/config.json
	systemctl enable trigger.service
	systemctl restart trigger.service
	systemctl status trigger.service

log-rotate: trigger/logrotate_trigger.conf
	cp trigger/logrotate_trigger.conf /var/logrotate.d/trigger.conf
	systemctl restart logrotate
