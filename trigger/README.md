# Trigger service

In order to react to incoming studies and series we can simply observe the .arrived folder.

Configure your program in "config.json", section "trigger-study", action type "exec". Arguments to your program should be provided as an array of strings. You can use the following placeholders:

- "@StudyInstanceUID@",
- "@SeriesInstanceUID@",
- "@PATH@", and
- "@DESCRIPTION@"

You can run trigger.py on the command line:

```{bash}
./trigger.py
```

for testing purposes or you can run it as a system service.

### System service outside docker (Linux only)

Copy the file "etc_systemd_system_trigger.service" to /etc/systemd/system/trigger.service (as user root). You may want to adjust the paths in the file before running it (path to trigger.py). Enable and start the service with

```{bash}
systemctl enable trigger.service
systemctl start trigger.service
systemctl status trigger.service
```

If everythign works the status command should show no error messages.

### Cleaning up

Output of the trigger service will appear in /data/logs/trigger.log. In order to prevent the log folder from filling up the drive install a logrotate job such as (create /var/logrotate.d/trigger.conf):

```
/data/logs/*.log {
    maxsize 100M
    hourly
    missingok
    rotate 8
    compress
    notifempty
    nocreate
}
```

### Docker

You can create a docker container with the trigger. This will work fine for simple commands. But because the command is running inside your container you also need to install your program in Dockerfile. If you don't want to do this step, use the above version outside of a container.

Build the container:

```
docker build -t trigger -f Dockerfile .
```

Run the container:

```
docker run --rm -v /tmp/.arrived:/data/.arrived -it trigger /bin/bash
```
