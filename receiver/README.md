# Build, run and test

```{bash}
   docker build -t receiver -f Dockerfile .
```

```{bash}
   docker run --rm -d -p 11112:11112 -v /tmp:/data/site/archive -v /tmp:/root/logs receiver
```

```{bash}
   storescu -v -aec FIONA -aet FIONA -nh +r +sd localhost 11112 <some location with DICOM files>
```

# Setup as a system service (Linux only)

```{bash}
cp etc_systemd_system_docker.receiver.service /etc/systemd/system/docker.receiver.service
systemctl enable docker.receiver.service
systemctl start docker.receiver.service  
```
