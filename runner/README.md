# Runner

A minimal job scheduler that will run jobs created by the trigger service.

The runner will need to run natively on the system as it will attempt to start jobs using docker. It depends on docker, flock and bash.

Note: The runOneJob.sh script assumes that the current user is root.

Note: The cron-job is using the 'flock' utility to prevent several runOneJob.sh calls to run together.

Copy the runOneJob.sh file to /root/runOneJob.sh. To setup as a system service using cron:

```bash
crontab -l | { cat; echo "*/1 * * * * /usr/bin/flock -n /data/logs/runOneJob.pid /root/runOneJob.sh >> /data/logs/runOneJob.log 2>&1"; } | crontab -
```
