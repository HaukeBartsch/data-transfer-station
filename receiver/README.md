# Build, run and test

```{bash}
   docker build -t receiver -f Dockerfile .
```

```{bash}
   docker run --rm -d -p 11112:11112 -v /tmp/site/archive:/data/site/archive \
              -v /tmp/site/raw:/data/site/raw \
              -v /tmp/site/.arrived:/data/site/.arrived \
	      -v /tmp:/root/logs receiver
```

```{bash}
   storescu -v -aec FIONA -aet FIONA -nh +r +sd localhost 11112 <some location with DICOM files>
```

# Setup as a system service (Linux only)

For DTS the receiver is setup as a system service using systemd. The Makefile in the root directory will perform the three steps below.

```{bash}
# copy systemd file to control the service
cp etc_systemd_system_docker.receiver.service /etc/systemd/system/docker.receiver.service
# enable the start the service, after a reboot the service will persist now
systemctl enable docker.receiver.service
systemctl start docker.receiver.service  
```
