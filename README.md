# Data transfer station for image AI in the hospital

A self-hosted digital platform for the secure image exchange and processing integrated with hospital systems using industry standards.

### Technical details

A DICOM aware platform that allows for in-house image processing using AI. Receives medical images from PACS and can trigger AI processing pipelines including routing of incoming and outgoing images on the network. 

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
```

Adjust the configuration files if needed, they are in the ./configuration folder.

Use docker-compose to setup receiver and trigger services. You can remove the '--no-cache' option to speed up the process. In case of errors we suggest you add it back.

```{bash}
docker compose build --no-cache && docker compose up
```

Add the A.I. docker container to the host system.

```{bash}
docker load < AI.tar
```

Setup the runner as a cron-job on the host system. It will check the output of the trigger service and run the A.I. container if needed. Perform the following steps as the root user.

```{bash}
mkdir -p /data/logs /data/code/trigger;
cp runner/runOneJob.sh /data/code/trigger;
( crontab -l; echo '*/1 * * * * /usr/bin/flock -n /data/logs/runOneJob.pid /data/code/trigger/runOneJob.sh >> /data/logs/runOneJob.log 2>&1' ) | crontab - ;

# get a copy of ror, check your platform code
wget -qO- https://github.com/mmiv-center/Research-Information-System/raw/master/components/Workflow-Image-AI/build/linux-amd64/ror > /data/code/trigger/ror;
chmod +x /data/code/trigger/ror;
```

### Test the receiver

If the setup worked the receiver should be accessible on port 11112 (DICOM). You can send a test dataset to this port to check for success

```{bash}
# apt install dcmtk
storescu -v -aet FIONA -aec AICORE1 -nh +sd +r localhost 11112 <data-folder>
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
