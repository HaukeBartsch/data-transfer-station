#!/usr/bin/env python3
from datetime import datetime

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
    config = read(f)
    f.close()

if not(os.path.isdir(config["arrived"])):
    print("Error: the provided arrived path \"%s\" is not a directory." % (config["arrived"]))
    sys.exit(-1)

# we need to check the /data/site/.arrived folder for files with a last modification time 
while True:
    obj = os.scandir(config["arrived"])
    for file in obj:
        if file.is_file():
            mtime = os.path.getmtime(file)
            t = datetime.fromtimestamp(t)
            now = datetime.now()
            delta = now - t
            if (delta.total_seconds() > config["timeout"]:
                # now trigger the action
                print("Trigger the action now")

                # remove the .arrived file again
                pass
    time.sleep(1)
