#
# Setup and check the configuration of DTS
#
SHELL := /bin/bash


.PHONY: all
all: run-as-root make-secure receiver-exists receiver-running trigger-running ai-core001


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

make-secure:
	@if crontab -l | grep -q shutdown; then echo "check for scheduled reboots, ok"; else echo "Setup a regular reboot in crontab with @weekly /sbin/shutdown -r now."; exit 1; fi
	@if fail2ban-client status 2>&1 > /dev/null; then echo "check for fail2ban service, ok"; else echo "Install fail2ban with apt install fail2ban."; exit 1; fi
	systemctl enable fail2ban
	systemctl start fail2ban
	@if systemctl status unattended-upgrades.service 2> /dev/null; then echo "check for unattended-upgrades, ok"; else echo "Install unattended-upgrades to install security relevant upgrades"; exit 1; fi
	systemctl status unattended-upgrades

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
	cp trigger/BackendLogging.py /data/code/trigger/BackendLogging.py
	apt update -yy && apt install -yy python3-sqlalchemy
	cp trigger/addJob.sh /data/code/trigger/addJob.sh && chmod +x /data/code/trigger/addJob.sh
	cp trigger/select.statements /data/code/trigger/select.statements
	cp trigger/config.json /data/code/trigger/config.json
	systemctl enable trigger.service
	systemctl restart trigger.service
	systemctl status trigger.service

log-rotate: trigger/logrotate_trigger.conf
	cp trigger/logrotate_trigger.conf /var/logrotate.d/trigger.conf
	systemctl restart logrotate

ai-core001:
	@if [ -z $(shell command -v ror 2> /dev/null) ] ;\
	then \
	  wget -qO- https://github.com/mmiv-center/Research-Information-System/raw/master/components/Workflow-Image-AI/build/linux-amd64/ror > /usr/local/bin/ror; \
	  chmod +x /usr/local/bin/ror; \
	  echo "download and setup for ror is done (`which ror`)"; \
	else \
	  echo "ror is already installed (`which ror`)"; \
	fi
	@if [ ! -e /data/ai-core001/select.statement ]; \
	then \
	  echo "Please create a select.statement file in /data/ai-core001"; \
	  exit 1; \
	fi
