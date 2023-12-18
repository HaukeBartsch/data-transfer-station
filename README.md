# Data transfer station - AI in the hospital

A DICOM aware system that receives medical images from PACS 
and triggers AI processing pipelines including routing of incoming and outgoing images on the network. 
This data transfer station small, fast and so simple that anyone should be able to set it up, and run pipelines.

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
