# Data transfer station for image AI in the hospital

A self-hosted digital platform for the secure image exchange and processing integrated with hospital systems using industry standards.

### Technical details

A DICOM aware platform that allows for in-house image processing using AI. Receives medical images from PACS and can trigger AI processing pipelines including 
routing of incoming and outgoing images on the network. 

With Data Transfer Station you participate in the hospital network as a
fully automated medical service. Radiologists will be sending you an exam, processing
is triggered to generate a report and that report bounces back to the sending system.

The setup describes the roll-out in a docker/docker-compose environment.

Features:

- DICOM receive using storescp
- Auto-forwarding based on DICOM tags

## Setup

Checkout this repository. You will also need the A.I. service as a separate tar file (see below).

```{bash}
git clone https://github.com/HaukeBartsch/data-transfer-station.git
# move template configuration to /data/configuration
mkdir -p /data && cp -R configuration /data/configuration
```

Use docker-compose to setup receiver and trigger services.

```{bash}
docker compose up
```

Add the A.I. container to the system.

```{bash}
docker load < AI.tar
```

Setup the runner as a cron-job. It will check the output of the trigger service and run the A.I. container if needed. You need permissions to create a /data directory.

```{bash}
mkdir -p /data/logs /data/code/trigger;
cp runner/runOneJob.sh /data/code/trigger;
( crontab -l; echo '*/1 * * * * /usr/bin/flock -n /data/logs/runOneJob.pid /data/code/trigger/runOneJob.sh >> /data/logs/runOneJob.log 2>&1' ) | crontab - ;
```


### Test the receiver

If the setup worked the receiver should be accessible on port 11112 (DICOM). You can send a test dataset to this port to check for success

```{bash}
# apt install dcmtk
storescu -aet me -aec me -nh +sd +r localhost 11112 <data-folder>
```

If the above was successful you should see the data appearing in the archive and raw folders.


## Data receiver

Interfaces with the Picture Archive and Communication System (PACS). Listens for DICOM requests on a port and stores the images temporarily. This component is run using a docker container.

## Processing trigger

For every incoming dataset a ruleset will qualify a processing stream. The processing is triggered automatically and generated report documents and structured data are forwarded to other connected systems.

## Tracking data processing

Used to debug processing steps, shows incoming data, error messages and processing logs. Used as well for the configuration of the system.

## System setup

The Makefile automates procedures for setup and ensures system compliance. Running 'make' instructions are provided on how to setup DTS.

```{bash}
cd data-transfer-station
make
```
