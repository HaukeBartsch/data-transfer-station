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
