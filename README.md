# Data transfer station for image AI in the hospital

A self-hosted technical solution for image exchange and image processing that integrates with hospital Picture Archive and Communication Systems (PACS) using industry standards.

### Technical details

A DICOM aware system that receives medical images from PACS and triggers AI processing pipelines including 
routing of incoming and outgoing images on the network. 

If you run this data transfer station you will be able to participate on a hospital network as a
fully automated medical workstation. Radiologists will be sending you a case, processing
is triggered to generate a report and that report bounces back to the sending system.

In order to setup this environment we require a docker/docker-compose like environment.

Features:

- DICOM receive using storescp
- Auto-forwarding based on DICOM tags

## Data receiver

A component that interfaces with PACS. Listens for DICOM requests on a port and stores the images in a disk location.

## Website

Used to debug processing steps, shows incoming data, error messages and processing logs. Used as well for the configuration of the system.

## Setup

The Makefile automates procedures on setup and to ensure system compliance. Instructions are provided on how to setup and check a virtual machine environment running DTS.

```{bash}
cd data-transfer-station
make
```
