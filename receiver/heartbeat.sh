#!/bin/bash
#
# create a heart beat for the storescp
# One way it can fail is if multiple associations are requested.
# If the timeout happens the connection will be unusable afterwards.
# Here we simply use echoscu to test the connection and if that
# fails we will kill a running storescp (hoping that monit will start it again).
#
# In order to activate put this into the crontab of processing (every minute)
#   */1 * * * * /usr/bin/nice -n 3 /var/www/html/server/bin/heartbeat.sh
#
#

# read in the configuration file

PARENTIP=`cat /config.json | jq -r ".DICOMIP"`
PARENTPORT=`cat /config.json | jq -r ".DICOMPORT"`
LOGDIR=`cat /config.json | jq -r ".LOGDIR"`

SERVERDIR=`dirname "$(readlink -f "$0")"`
log=${SERVERDIR}/logs/heartbeat.log

if [ ! -z "${LOGDIR}" ]; then
    if [ -d "${LOGDIR}" ]; then
        log=${LOGDIR}/heartbeat.log
    else
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: The LOGDIR ${LOGDIR} does not exist, using default ${log}"
    fi
fi

projname="$1"
if [ -z "$projname" ]; then
    projname="ABCD"
fi
if [ "$projname" != "ABCD" ]; then
    PARENTIP=`cat /config.json | jq -r ".SITES.${projname}.DICOMIP"`
    PARENTPORT=`cat /config.json | jq -r ".SITES.${projname}.DICOMPORT"`
    log=${SERVERDIR}/logs/heartbeat${projname}.log
    if [ ! -z "${LOGDIR}" ]; then
        if [ -d "${LOGDIR}" ]; then
            log=${LOGDIR}/heartbeat${projname}.log
        else
            echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: The LOGDIR ${LOGDIR} does not exist, using default ${log}"
        fi
    fi
fi

# cheap way to test if storescp is actually running
# check if the storescp log file is new enough
# (Bug: fixes a problem with non-fork send data, echoscu does not work if data is received)
storelog=${SERVERDIR}/logs/storescpd${projname}.log
if [ ! -z "${LOGDIR}" ]; then
    if [ -d "${LOGDIR}" ]; then
        storelog=${LOGDIR}/heartbeat${projname}.log
    else
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: The LOGDIR ${LOGDIR} does not exist, using default ${log}"
    fi
fi

if [ ! -e "${storelog}" ]; then
    # create an empty log file in case it does not exist yet
    touch "${storelog}"
fi

#
# The time selected here should be timed with the number of seconds storescp will wait and keep
# the line open in case the sender is slow and sending more images. If echoscu would call with
# storescp still open its aetitle will overwrite the aetitle of the incoming sender/files.
#
testtime=16
if [ "$(( $(date +"%s") - $(stat -c "%Y" "$storelog") ))" -lt "$testtime" ]; then
   echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: do not check with storescp: ${storelog} is too new, seems to work" >> $log
   exit 0
fi

echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: try now: /usr/bin/echoscu $PARENTIP $PARENTPORT" >> $log
timeout 20 /usr/bin/echoscu $PARENTIP $PARENTPORT
if (($? == 1)); then
   # get pid of the main storescu
   pid=`pgrep -f "storescp.*$PARENTPORT" | head -1`
   if [ -z "$pid" ]; then
      echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: storescp's pid could not be found" >> $log
      exit 0
   fi
   echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: detected unresponsive storescp, kill \"$pid\" and hope that the system restarts it" >> $log
   # stop storescu gracefully first
   kill -s SIGTERM $pid && kill -0 $pid || exit 0
   sleep 5
   # more forceful
   kill -s SIGKILL $pid

   # if we had to kill the process this way they port will belong to a parent, lets kill all of those as well
   portstr=`netstat -lnp | grep $PARENTPORT`
   count=20
   while [ ! -z "$portstr" ]; do
      echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: the port is still in use..." >> $log
      # It happened once that this loop did not stop, the proc name was tmp and the loop continued to kill
      # storescp again and again. Only stopping heartbeat resolved this issue.
      (( --count ))
      if [ "$count" -gt "0" ]; then
	  break
      fi

      proc=`netstat -lnp | grep $PARENTPORT | cut -d'/' -f2`
      id=`netstat -lnp | grep $PARENTPORT | cut -d'/' -f 1 | awk '{ print $7 }'`
      echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: the port is still in use by a process ($proc) with id $id, kill it" >> $log
      kill $id
      # and check again
      portstr=`netstat -lnp | grep $PARENTPORT`   
   done
fi


#
# Sometimes the detectStudyArrival will fail to quit, if that is the case it keeps running
# and prevent other detectStudyArrival jobs to work. Data will pile up in /data/site/.arrived
# until the detectStudyArrival job is killed and its .pid file removed.
#
# We should detect such a stuck detectStudyArrival job and clean up.
#
ids=`pgrep -f detectStudyArrival`
while read -r line; do
    if [ -z "$line" ]; then
       break
    fi
    tr=`ps -p "$line" -o etimes= | tr -d ' '`
    if [ "$tr" -eq "0" ] || [ "$tr" = "" ]; then
	:
    elif [ "$tr" -gt "3600" ]; then
        echo "`date +'%Y-%m-%d %H:%M:%S.%06N'`: Error, detectStudyArrival is running for more than 1 hour, stop it now and have it restart" >> $log
	/usr/bin/kill $line && /bin/bin/rm -f /var/www/html/server/.pids/detectStudyArrival${projname}.lock
	# the cron job will restart this service again
    fi
done <<< "$ids"
