# Data transfer station

You might remember MagickBox, a DICOM aware system that could receive medical images over the network 
and trigger processing pipelines including routing of incoming and outgoing images on the network. 
This data transfer station is similar, but smaller, faster and so simple that anyone should be able 
to set it up.

If you run this data transfer station you will be able to participate on a hospital network as a
fully automated medical workstation. Radiologists will be able to send you a case and your processing
is triggered to generate a report that bounces back to the sending system.


In order to setup this environment we require a docker/docker-compose like environment.

Features:

- DICOM receive using storescp
- Auto-forwarding based on DICOM tags

## Data receiver

Listens for DICOM requests on a port and stores the images in a disk location.

## Website

The website code to show the data and to configure the system.
