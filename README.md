# Data transfer station

In order to setup this environment we require a docker/docker-compose like environment.

Features:

- DICOM receive using storescp
- Auto-forwarding based on DICOM tags

## Data receiver

Listens for DICOM requests on a port and stores the images in a disk location.

## Website

The website code to show the data and to configure the system.
