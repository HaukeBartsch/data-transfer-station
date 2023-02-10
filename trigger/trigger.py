#!/usr/bin/env python3
from datetime import datetime
import re, sys, os, time, json

# continuously check folder specified in config.json
config = {
    "arrived": "",
    "timeout": 16,
    "trigger-study": [{
        "send": "http",
        "destination": "http://localhost:11120"
    }]
}

with open("config.json", "r") as f:
    config = json.load(f)
    f.close()

if not(os.path.isdir(config["arrived"])):
    print("Error: the provided arrived path \"%s\" is not a directory." % (config["arrived"]))
    sys.exit(-1)

# we need to check the /data/site/.arrived folder for files with a last modification time 
while True:
    obj = os.scandir(config["arrived"])
    for file in obj:
        if file.is_file():
            # lets parse the filename and see if we get all structured fields
            re_series = "([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)"
            re_study = "([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)"
            x = re.match(re_series, file.name)
            type = "series"
            if x == None:
                x = re.match(re_study, file.name)
                type = "study"
            aet = x[1]
            aec = x[2]
            dummy = x[3]
            StudyInstanceUID = x[4]
            if type == "series":
                SeriesInstanceUID = x[5]
 
            mtime = os.path.getmtime(file)
            t = datetime.fromtimestamp(mtime)
            now = datetime.now()
            delta = now - t
            if delta.total_seconds() > config["timeout"]:
                # now trigger the action
                print("Trigger the action now for type: %s" % (type))

                # remove the .arrived file again
                pass
    time.sleep(1)
